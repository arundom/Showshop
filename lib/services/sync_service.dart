import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/item.dart';
import 'database_service.dart';
import 'supabase_service.dart';

/// Handles synchronisation between the local SQLite store and a remote backend.
///
/// ## How offline sync works
/// 1. Every write goes to local SQLite first (`is_synced = 0`).
/// 2. [SyncService] listens for connectivity changes.
/// 3. When connectivity is restored, [_syncPendingItems] pushes all
///    unsynced rows to Supabase and sets `is_synced = 1` on success.
/// 4. [syncFromServer] pulls items from Supabase and upserts them locally.
/// 5. On app start, [syncOnStartup] triggers both directions.
class SyncService {
  SyncService({
    DatabaseService? databaseService,
    SupabaseService? supabaseService,
  })  : _db = databaseService ?? DatabaseService(),
        _remote = supabaseService ?? SupabaseService();

  final DatabaseService _db;
  final SupabaseService _remote;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  bool _isSyncing = false;

  /// Broadcasts user-friendly sync failures for UI feedback.
  Stream<String> get errors => _errorController.stream;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  /// Call once (e.g. in [main]) to start listening for network changes.
  void startListening() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  /// Release resources when no longer needed.
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Attempt to push any locally-stored, unsynced items to the remote and
  /// pull any new/updated items from the server.
  /// Safe to call multiple times; concurrent calls are debounced.
  Future<void> syncOnStartup() async {
    final results = await Connectivity().checkConnectivity();
    if (_isOnline(results)) {
      await _syncPendingItems();
      await syncFromServer();
    }
  }

  /// Pulls all items from Supabase and upserts them into local SQLite.
  Future<void> syncFromServer() async {
    try {
      final remoteItems = await _remote.getItems();
      for (final item in remoteItems) {
        await _db.upsertItem(item);
      }
    } catch (e, st) {
      _emitSyncError(
        'Could not fetch latest cloud items. Will retry automatically.',
      );
      // Network errors are non-fatal; local data remains available.
      // ignore: avoid_print
      print('SyncService.syncFromServer error: $e\n$st');
    }
  }

  /// Attempts to push pending local items immediately when online.
  ///
  /// This is useful right after local writes (add/update/delete) so users do
  /// not need to restart the app or toggle connectivity to trigger sync.
  Future<void> syncPendingNow() async {
    final results = await Connectivity().checkConnectivity();
    if (!_isOnline(results)) return;
    await _syncPendingItems();
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  void _onConnectivityChanged(ConnectivityResult result) {
    if (_isOnline(result)) {
      _syncPendingItems();
    }
  }

  bool _isOnline(ConnectivityResult result) =>
      result != ConnectivityResult.none;

  bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _syncPendingItems() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final unsynced = await _db.getUnsyncedItems();
      for (final item in unsynced) {
        final success = await _pushItemToRemote(item);
        if (success && item.id != null) {
          await _db.markAsSynced(item.id!);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes [item] to Supabase.
  /// Returns `true` on success, `false` on failure (item will be retried).
  Future<bool> _pushItemToRemote(Item item) async {
    // Items without a local id cannot be reliably synced or deduplicated.
    if (item.id == null) return false;
    final localId = item.id!;

    try {
      final payload = item.toJson();
      // ignore: avoid_print
      print('[SYNC DEBUG] Pushing item $localId with payload: ${jsonEncode(payload)}');

      final existing = await _remote.getItemById(localId);

      if (existing != null) {
        // ignore: avoid_print
        print('[SYNC DEBUG] Item exists remotely, updating...');
        await _remote.updateItem(localId, item);
      } else {
        // ignore: avoid_print
        print('[SYNC DEBUG] Item is new, creating in Supabase...');
        final remoteId = await _remote.createItem(item);

        // If the local id differs from the Supabase-assigned id, atomically
        // replace the local record with the Supabase UUID.
        if (localId != remoteId) {
          final updated = item.copyWith(id: remoteId, isSynced: true);
          await _db.replaceItem(oldId: localId, newItem: updated);
          // ignore: avoid_print
          print('[SYNC DEBUG] Item created with new ID: $remoteId');
          return true;
        }
      }

      // Upload any local images that haven't been synced yet.
      final images = await _db.getItemImages(localId);
      for (var i = 0; i < images.length; i++) {
        final img = images[i];
        if ((img['synced'] as int? ?? 0) == 0) {
          final rawImageUrl = img['image_url'] as String;
          final displayOrder = img['display_order'] as int? ?? i;
          final imageRowId = img['id'] as String;

          var remoteImageUrl = rawImageUrl;
          if (!_isRemoteUrl(rawImageUrl)) {
            remoteImageUrl = await _remote.uploadImage(File(rawImageUrl), localId);
          }

          await _remote.addItemImage(localId, remoteImageUrl, displayOrder);
          await _db.markItemImageSynced(
            id: imageRowId,
            imageUrl: remoteImageUrl,
          );
        }
      }

      // ignore: avoid_print
      print('[SYNC DEBUG] Successfully synced item $localId');
      return true;
    } catch (e, st) {
      final errorMsg = e.toString();
      _emitSyncError(
        'Sync failed: $errorMsg',
      );
      // ignore: avoid_print
      print('[SYNC ERROR] Failed to sync item: $e\n$st');
      return false;
    }
  }

  void _emitSyncError(String message) {
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }
}

// ── Utility ────────────────────────────────────────────────────────────────────

/// Generates a random UUID v4 string without requiring an extra package.
String generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  final hex =
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}'
      '-${hex.substring(12, 16)}-${hex.substring(16, 20)}'
      '-${hex.substring(20, 32)}';
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/item.dart';
import 'database_service.dart';

/// Handles synchronisation between the local SQLite store and a remote backend.
///
/// ## Recommended remote backends
///
/// | Option | Best for | Notes |
/// |--------|----------|-------|
/// | **Firebase Firestore** | Small teams / rapid prototyping | Free tier, real-time listener, offline SDK built-in |
/// | **Supabase (PostgreSQL)** | SQL-familiar teams | Open-source Firebase alternative |
/// | **REST API (Node / Django / etc.)** | Full control | Custom server required |
///
/// ## How offline sync works
/// 1. Every write goes to local SQLite first (`is_synced = 0`).
/// 2. [SyncService] listens for connectivity changes.
/// 3. When connectivity is restored, [_syncPendingItems] pushes all
///    unsynced rows to the remote and sets `is_synced = 1` on success.
/// 4. On app start, [syncOnStartup] is called once to cover the case where
///    the app was closed while offline.
///
/// To integrate a real backend, replace [_pushItemToRemote] with your actual
/// HTTP / Firebase / Supabase call.
class SyncService {
  SyncService({
    DatabaseService? databaseService,
  }) : _db = databaseService ?? DatabaseService();

  final DatabaseService _db;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isSyncing = false;

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

  /// Attempt to push any locally-stored, unsynced items to the remote.
  /// Safe to call multiple times; concurrent calls are debounced.
  Future<void> syncOnStartup() async {
    final results = await Connectivity().checkConnectivity();
    if (_isOnline(results)) {
      await _syncPendingItems();
    }
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  void _onConnectivityChanged(ConnectivityResult result) {
    if (_isOnline(result)) {
      _syncPendingItems();
    }
  }

  bool _isOnline(ConnectivityResult result) =>
      result != ConnectivityResult.none;

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

  /// Replace this stub with a real HTTP / Firebase / Supabase call.
  ///
  /// Example (Firebase Firestore):
  /// ```dart
  /// await FirebaseFirestore.instance
  ///     .collection('items')
  ///     .doc(item.id.toString())
  ///     .set(item.toMap());
  /// return true;
  /// ```
  ///
  /// Example (REST API):
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('https://your-api.example.com/items'),
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: jsonEncode(item.toMap()),
  /// );
  /// return response.statusCode == 201;
  /// ```
  Future<bool> _pushItemToRemote(Item item) async {
    
    // TODO: implement your remote push logic here.
    // Returning false keeps is_synced = 0 so it will be retried next time.
    
    // Supabase URL: https://rdyszutpwabhqimvltvq.supabase.co
    // Anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkeXN6dXRwd2FiaHFpbXZsdHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMzY1NDcsImV4cCI6MjA5MTgxMjU0N30.fz6BzWiirFWzkTFY_DuPWoJE9qZ5xF8kEKkfrCjpd3s
    
    return false;
  }
}

import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

/// Provides the list of [Item] objects to the widget tree and exposes
/// methods to add, update, and delete items.
///
/// ## Write path
/// New items are written **directly to Supabase** so they are immediately
/// visible to all users. After Supabase confirms the write and returns the
/// server-assigned UUID, the item is also cached in local SQLite so it can
/// be viewed offline. Callers must ensure connectivity before calling [addItem].
class ItemProvider extends ChangeNotifier {
  ItemProvider({
    DatabaseService? databaseService,
    SupabaseService? supabaseService,
  })  : _db = databaseService ?? DatabaseService(),
        _remote = supabaseService ?? SupabaseService();

  final DatabaseService _db;
  final SupabaseService _remote;

  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Item> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _db.getAllItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Creates [item] in Supabase and caches it locally.
  ///
  /// Throws if the network call fails — callers should check connectivity
  /// before invoking this method and surface the error to the user.
  Future<void> addItem(Item item) async {
    // Write to Supabase; the server generates and returns the UUID.
    final remoteId = await _remote.createItem(item);
    final synced = item.copyWith(id: remoteId, isSynced: true);

    // Cache locally so the item is viewable offline.
    await _db.upsertItem(synced);

    _items.insert(0, synced);
    _items.sort((a, b) => b.listingDate.compareTo(a.listingDate));
    notifyListeners();
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _items.sort((a, b) => b.listingDate.compareTo(a.listingDate));
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}

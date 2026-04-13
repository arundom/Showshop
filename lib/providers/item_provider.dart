import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../services/database_service.dart';

/// Provides the list of [Item] objects to the widget tree and exposes
/// methods to add, update, and delete items.
class ItemProvider extends ChangeNotifier {
  ItemProvider({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService();

  final DatabaseService _db;

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

  Future<void> addItem(Item item) async {
    final id = await _db.insertItem(item);
    _items.insert(0, item.copyWith(id: id));
    // Re-sort by listing date descending so the new item appears at top.
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

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}

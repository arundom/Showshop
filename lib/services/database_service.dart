import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/item.dart';

/// Manages all local SQLite database operations for [Item] records.
///
/// The database stores items offline so they are available without a network
/// connection.  An [isSynced] flag marks rows that have been pushed to the
/// remote backend so the [SyncService] knows what still needs uploading.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  static const String _tableName = 'items';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'showshop.db');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        description   TEXT    NOT NULL,
        price         REAL    NOT NULL,
        listing_date  TEXT    NOT NULL,
        image_url     TEXT,
        condition     TEXT,
        seller_name   TEXT,
        seller_contact TEXT,
        notes         TEXT,
        is_synced     INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations go here.
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  /// Inserts [item] and returns the new row id.
  Future<int> insertItem(Item item) async {
    final db = await database;
    return db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all items ordered by [listingDate] descending (newest first).
  Future<List<Item>> getAllItems() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'listing_date DESC',
    );
    return rows.map(Item.fromMap).toList();
  }

  /// Returns a single item by [id], or `null` if not found.
  Future<Item?> getItemById(int id) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  /// Updates an existing item record.
  Future<int> updateItem(Item item) async {
    final db = await database;
    return db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deletes the item with [id].
  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ── Sync helpers ────────────────────────────────────────────────────────────

  /// Returns all items that have not yet been pushed to the remote backend.
  Future<List<Item>> getUnsyncedItems() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return rows.map(Item.fromMap).toList();
  }

  /// Marks the item with [id] as synced so it is not re-uploaded.
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Closes the database connection (useful in tests).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

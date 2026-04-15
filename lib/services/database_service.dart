import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/item.dart';

/// Manages all local SQLite database operations for [Item] records.
///
/// The database stores items offline so they are available without a network
/// connection.  An [isSynced] flag marks rows that have been pushed to the
/// remote backend so the [SyncService] knows what still needs uploading.
///
/// Schema version history:
/// - v1: initial schema (integer id, single image_url)
/// - v2: UUID text id, new fields (title, original_price, brand,
///       known_issues, image_urls, created_at, updated_at), item_images table
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  static const String _tableName = 'items';
  static const String _imagesTable = 'item_images';
  static const int _dbVersion = 2;

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
    await _createTablesV2(db);
  }

  Future<void> _createTablesV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id              TEXT    PRIMARY KEY,
        title           TEXT,
        description     TEXT    NOT NULL,
        price           REAL    NOT NULL,
        original_price  REAL,
        brand           TEXT,
        known_issues    TEXT,
        image_urls      TEXT    NOT NULL DEFAULT '[]',
        listing_date    TEXT    NOT NULL,
        condition       TEXT,
        seller_name     TEXT,
        seller_contact  TEXT,
        notes           TEXT,
        is_synced       INTEGER NOT NULL DEFAULT 0,
        created_at      TEXT,
        updated_at      TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_imagesTable (
        id            TEXT    PRIMARY KEY,
        item_id       TEXT    NOT NULL,
        image_url     TEXT    NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0,
        created_at    TEXT,
        synced        INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (item_id) REFERENCES $_tableName(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to items table (ignore errors if column already exists).
      final newColumns = {
        'title': 'TEXT',
        'original_price': 'REAL',
        'brand': 'TEXT',
        'known_issues': 'TEXT',
        "image_urls": "TEXT NOT NULL DEFAULT '[]'",
        'created_at': 'TEXT',
        'updated_at': 'TEXT',
      };
      for (final entry in newColumns.entries) {
        try {
          await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN ${entry.key} ${entry.value}');
        } catch (_) {
          // Column may already exist — safe to ignore.
        }
      }

      // Migrate old image_url values into image_urls JSON array.
      try {
        await db.execute(
          "UPDATE $_tableName SET image_urls = "
          "json_array(image_url) WHERE image_url IS NOT NULL AND image_url != ''",
        );
      } catch (_) {
        // image_url column may not exist in all cases.
      }

      // Create item_images table.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_imagesTable (
          id            TEXT    PRIMARY KEY,
          item_id       TEXT    NOT NULL,
          image_url     TEXT    NOT NULL,
          display_order INTEGER NOT NULL DEFAULT 0,
          created_at    TEXT,
          synced        INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (item_id) REFERENCES $_tableName(id) ON DELETE CASCADE
        )
      ''');

      // Convert old integer primary key rows to TEXT by recreating the table.
      // We use a temp-table approach so existing data is preserved.
      await db.execute('ALTER TABLE $_tableName RENAME TO _items_old');
      await _createTablesV2(db);
      await db.execute('''
        INSERT INTO $_tableName (
          id, title, description, price, original_price, brand,
          known_issues, image_urls, listing_date, condition,
          seller_name, seller_contact, notes, is_synced,
          created_at, updated_at
        )
        SELECT
          CAST(id AS TEXT), title, description, price, original_price, brand,
          known_issues,
          COALESCE(image_urls, '[]'),
          listing_date, condition, seller_name, seller_contact, notes,
          is_synced, created_at, updated_at
        FROM _items_old
      ''');
      await db.execute('DROP TABLE _items_old');
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  /// Inserts [item] and returns the item's id (UUID string).
  Future<String> insertItem(Item item) async {
    final db = await database;
    final map = item.toMap();
    await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return map['id'] as String;
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
  Future<Item?> getItemById(String id) async {
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
  Future<int> deleteItem(String id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ── Item Images ────────────────────────────────────────────────────────────

  /// Returns all image records for the item with [itemId].
  Future<List<Map<String, dynamic>>> getItemImages(String itemId) async {
    final db = await database;
    return db.query(
      _imagesTable,
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'display_order ASC',
    );
  }

  /// Inserts an image record for [itemId].
  Future<void> insertItemImage({
    required String id,
    required String itemId,
    required String imageUrl,
    required int displayOrder,
  }) async {
    final db = await database;
    await db.insert(
      _imagesTable,
      {
        'id': id,
        'item_id': itemId,
        'image_url': imageUrl,
        'display_order': displayOrder,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes all image records for [itemId].
  Future<void> deleteItemImages(String itemId) async {
    final db = await database;
    await db.delete(_imagesTable, where: 'item_id = ?', whereArgs: [itemId]);
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
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Upserts an item received from the remote into local SQLite.
  Future<void> upsertItem(Item item) async {
    final db = await database;
    await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Closes the database connection (useful in tests).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

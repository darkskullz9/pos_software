import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_model.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;

  static const String _databaseName = 'inventory.db';
  static const int _databaseVersion = 2;

  static const String productsTable = 'products';
  static const String settingsTable = 'settings';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $productsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        barcode TEXT,
        category_code INTEGER NOT NULL,
        color_code INTEGER,
        size_code INTEGER
      )
    ''');

    await _createSettingsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<Map<String, String>> getSettings() async {
    final db = await database;
    final maps = await db.query(settingsTable);

    return {
      for (final item in maps) item['key'] as String: item['value'] as String,
    };
  }

  Future<void> saveSettings(Map<String, String> settings) async {
    final db = await database;

    final batch = db.batch();

    for (final entry in settings.entries) {
      batch.insert(
        settingsTable,
        {
          'key': entry.key,
          'value': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return db.insert(
      productsTable,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProductModel>> getProducts() async {
    final db = await database;
    final maps = await db.query(
      productsTable,
      orderBy: 'id DESC',
    );

    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query(
      productsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  Future<int> updateProduct(ProductModel product) async {
    if (product.id == null) {
      throw Exception('Impossible de mettre à jour un produit sans id');
    }

    final db = await database;
    return db.update(
      productsTable,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete(
      productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}

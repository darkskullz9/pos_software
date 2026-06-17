import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_model.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;

  static const String _databaseName = 'inventory.db';
  static const int _databaseVersion = 1;

  static const String productsTable = 'products';

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
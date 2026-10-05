import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/order_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'order_packer_pro.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_code TEXT NOT NULL,
            type TEXT NOT NULL,
            platform TEXT NOT NULL DEFAULT 'SHOPEE',
            video_path TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            note TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_order_code ON orders(order_code)');
        await db.execute('CREATE INDEX idx_platform ON orders(platform)');
        await db.execute('CREATE INDEX idx_created_at ON orders(created_at)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE orders ADD COLUMN platform TEXT DEFAULT 'SHOPEE'");
            await db.execute('CREATE INDEX IF NOT EXISTS idx_platform ON orders(platform)');
          } catch (_) {}
        }
      },
    );
  }

  Future<int> insertOrder(OrderRecord order) async {
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<OrderRecord>> getOrders({
    String? searchQuery,
    String? filterType, // 'PACKING', 'RETURN', or null for all
    String? filterPlatform, // 'SHOPEE', 'TIKTOK', 'LAZADA', 'TIKI', 'OTHER', or null for all
    DateTime? fromDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += 'order_code LIKE ? ';
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (filterType != null && filterType != 'ALL') {
      if (whereClause.isNotEmpty) whereClause += 'AND ';
      whereClause += 'type = ? ';
      whereArgs.add(filterType);
    }

    if (filterPlatform != null && filterPlatform != 'ALL') {
      if (whereClause.isNotEmpty) whereClause += 'AND ';
      whereClause += 'platform = ? ';
      whereArgs.add(filterPlatform);
    }

    if (fromDate != null) {
      if (whereClause.isNotEmpty) whereClause += 'AND ';
      whereClause += 'created_at >= ? ';
      whereArgs.add(fromDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => OrderRecord.fromMap(maps[i]));
  }

  Future<OrderRecord?> getOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return OrderRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateNote(int id, String note) async {
    final db = await database;
    return await db.update(
      'orders',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();

    final totalOrdersResult = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    final totalOrders = Sqflite.firstIntValue(totalOrdersResult) ?? 0;

    final todayPackingResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE type = 'PACKING' AND created_at >= ?",
      [startOfToday],
    );
    final todayPacking = Sqflite.firstIntValue(todayPackingResult) ?? 0;

    final todayReturnResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE type = 'RETURN' AND created_at >= ?",
      [startOfToday],
    );
    final todayReturn = Sqflite.firstIntValue(todayReturnResult) ?? 0;

    // Platform statistics
    final shopeeCountResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE platform = 'SHOPEE'",
    );
    final shopeeCount = Sqflite.firstIntValue(shopeeCountResult) ?? 0;

    final tiktokCountResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE platform = 'TIKTOK'",
    );
    final tiktokCount = Sqflite.firstIntValue(tiktokCountResult) ?? 0;

    final lazadaCountResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE platform = 'LAZADA'",
    );
    final lazadaCount = Sqflite.firstIntValue(lazadaCountResult) ?? 0;

    final totalSizeResult = await db.rawQuery('SELECT SUM(file_size) as total_size FROM orders');
    final totalBytes = (totalSizeResult.first['total_size'] as num?)?.toInt() ?? 0;

    return {
      'totalOrders': totalOrders,
      'todayPacking': todayPacking,
      'todayReturn': todayReturn,
      'shopeeCount': shopeeCount,
      'tiktokCount': tiktokCount,
      'lazadaCount': lazadaCount,
      'totalBytes': totalBytes,
    };
  }
}

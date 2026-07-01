import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Local SQLite via [sqflite] — caches API browse results.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final fp = path.join(dir, 'beltei_lost_found.db');
    _db = await openDatabase(
      fp,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS favorites');
          await db.execute('DROP TABLE IF EXISTS cart_lines');
          await db.execute('DROP TABLE IF EXISTS items_cache');
          await _createCacheTable(db);
        }
      },
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createCacheTable(db);
  }

  static Future<void> _createCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE items_cache (
        cache_key TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
  }
}

import 'dart:convert';

import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/db/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class _MemoryCacheEntry {
  const _MemoryCacheEntry(this.page, this.cachedAt);

  final ItemsPage page;
  final DateTime cachedAt;
}

/// Browse cache — SQLite on mobile, in-memory on web.
class ItemsCache {
  final Map<String, _MemoryCacheEntry> _memory = {};

  Future<Database> get _db => AppDatabase.instance.database;

  static String cacheKey({
    int page = 1,
    String? type,
    String? q,
    String? category,
    String? building,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) {
    return 'p$page|t${type ?? ''}|q${q ?? ''}|c${category ?? ''}'
        '|b${building ?? ''}|s${status ?? ''}|df${dateFrom ?? ''}|dt${dateTo ?? ''}';
  }

  Future<void> put(String key, ItemsPage page) async {
    if (kIsWeb) {
      _memory[key] = _MemoryCacheEntry(page, DateTime.now());
      return;
    }
    final database = await _db;
    await database.insert(
      'items_cache',
      {
        'cache_key': key,
        'payload': jsonEncode(page.toJson()),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ItemsPage?> get(
    String key, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    if (kIsWeb) {
      final entry = _memory[key];
      if (entry == null) return null;
      if (DateTime.now().difference(entry.cachedAt) > maxAge) return null;
      return entry.page;
    }

    final database = await _db;
    final rows = await database.query(
      'items_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final cachedAt = rows.first['cached_at'] as int;
    if (DateTime.now().millisecondsSinceEpoch - cachedAt >
        maxAge.inMilliseconds) {
      return null;
    }
    final payload =
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
    return ItemsPage.fromJson(payload);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _memory.clear();
      return;
    }
    final database = await _db;
    await database.delete('items_cache');
  }
}

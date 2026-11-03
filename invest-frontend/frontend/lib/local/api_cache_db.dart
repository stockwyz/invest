import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 本地缓存数据库：把每个接口最近一次成功返回的 JSON 原样存下来，
/// key 用"接口名+参数"拼出来（如 dashboard_summary_month），下次请求时：
///   1. 先尝试请求后端最新数据 —— 成功就覆盖写入缓存，界面显示"最新"角标；
///   2. 请求失败（断网/超时/服务端挂了）就读这张表兜底 —— 界面显示"离线缓存 · 更新于 xx:xx"角标。
/// 只做"整份 JSON 缓存"而不建一堆和后端字段一一对应的本地表，
/// 是因为这里缓存的目的是"弱网兜底展示"，不需要离线可写、离线可查询等更复杂的能力；
/// 真要支持离线记账，再把 trade 相关的写操作换成本地表 + 后台同步队列。
class ApiCacheDb {
  ApiCacheDb._internal();

  static final ApiCacheDb instance = ApiCacheDb._internal();

  Database? _db;

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    final dbPath = p.join(await getDatabasesPath(), 'fuli_api_cache.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE api_cache (
            cache_key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<void> put(String key, Map<String, dynamic> jsonPayload) async {
    final db = await _database();
    await db.insert(
      'api_cache',
      {
        'cache_key': key,
        'payload': jsonEncode(jsonPayload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 返回 (数据, 缓存时间)；没有缓存过就返回 null。
  Future<(Map<String, dynamic>, DateTime)?> get(String key) async {
    final db = await _database();
    final rows = await db.query('api_cache', where: 'cache_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int);
    return (payload, updatedAt);
  }
}

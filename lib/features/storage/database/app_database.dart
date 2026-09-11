/// 应用数据库管理
///
/// 每个租户一个独立的 SQLite 数据库文件，物理隔离。
/// 表结构：
///   sessions  会话表
///   messages  消息表
///   memory    记忆表（预留）
library;

import 'package:sqflite/sqflite.dart';
import '../tenant_storage.dart';

class AppDatabase {
  Database? _db;
  String? _tenantId;

  /// 打开指定租户的数据库
  Future<Database> open(String tenantId) async {
    if (_db != null && _tenantId == tenantId) {
      return _db!;
    }
    await close();
    final path = await TenantStorage.getDatabasePath(tenantId);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    _tenantId = tenantId;
    return _db!;
  }

  /// 获取当前已打开的数据库
  Database get db {
    if (_db == null) {
      throw StateError('Database not opened. Call open(tenantId) first.');
    }
    return _db!;
  }

  /// 当前租户ID
  String? get tenantId => _tenantId;

  /// 关闭数据库
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _tenantId = null;
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        message_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        attachment_type TEXT,
        attachment_path TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_messages_session_id ON messages(session_id)',
    );

    await db.execute(
      'CREATE INDEX idx_sessions_tenant_id ON sessions(tenant_id)',
    );

    // 记忆表（预留，后续版本使用）
    await db.execute('''
      CREATE TABLE memory (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        title TEXT NOT NULL,
        weight INTEGER DEFAULT 50,
        tags TEXT,
        category TEXT,
        source TEXT,
        file_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
}

/// 全局单例
final appDatabase = AppDatabase();

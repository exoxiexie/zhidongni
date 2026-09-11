/// 应用数据库管理
///
/// 每个租户一个独立的 SQLite 数据库文件，物理隔离。
/// 表结构：
///   sessions              会话表
///   messages              消息表
///   memory                记忆表
///   local_upload_sessions 本地文件沉淀会话表
///   local_files           本地文件记录表
library;

import 'package:sqflite/sqflite.dart';
import '../tenant_storage.dart';

class AppDatabase {
  Database? _db;
  String? _tenantId;

  /// 全局单例
  static final AppDatabase instance = AppDatabase();

  /// 打开指定租户的数据库
  Future<Database> open(String tenantId) async {
    if (_db != null && _tenantId == tenantId) {
      return _db!;
    }
    await close();
    final path = await TenantStorage.getDatabasePath(tenantId);
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // 记忆表
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

    // 本地文件沉淀会话表
    await db.execute('''
      CREATE TABLE local_upload_sessions (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        file_count INTEGER DEFAULT 0,
        total_size INTEGER DEFAULT 0,
        source TEXT NOT NULL
      )
    ''');

    // 本地文件记录表
    await db.execute('''
      CREATE TABLE local_files (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        name TEXT NOT NULL,
        size INTEGER DEFAULT 0,
        extension TEXT,
        relative_path TEXT NOT NULL,
        source TEXT NOT NULL,
        uploaded_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES local_upload_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_local_files_session_id ON local_files(session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_local_sessions_tenant_id ON local_upload_sessions(tenant_id)',
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2：添加本地文件沉淀相关表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_upload_sessions (
          id TEXT PRIMARY KEY,
          tenant_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          file_count INTEGER DEFAULT 0,
          total_size INTEGER DEFAULT 0,
          source TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_files (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          name TEXT NOT NULL,
          size INTEGER DEFAULT 0,
          extension TEXT,
          relative_path TEXT NOT NULL,
          source TEXT NOT NULL,
          uploaded_at TEXT NOT NULL,
          FOREIGN KEY (session_id) REFERENCES local_upload_sessions(id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_local_files_session_id ON local_files(session_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_local_sessions_tenant_id ON local_upload_sessions(tenant_id)',
      );
    }
  }
}

/// 全局单例（兼容旧代码）
final appDatabase = AppDatabase.instance;

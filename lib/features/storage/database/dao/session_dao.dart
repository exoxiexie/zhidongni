/// 会话 DAO
library;

import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/session_entity.dart';

class SessionDao {
  Database get _db => appDatabase.db;

  /// 创建会话
  Future<void> insert(SessionEntity session) async {
    await _db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取指定租户的所有会话，按更新时间倒序
  Future<List<SessionEntity>> findByTenant(String tenantId) async {
    final maps = await _db.query(
      'sessions',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => SessionEntity.fromMap(m)).toList();
  }

  /// 根据ID获取会话
  Future<SessionEntity?> findById(String id) async {
    final maps = await _db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SessionEntity.fromMap(maps.first);
  }

  /// 更新会话标题和更新时间
  Future<void> update(SessionEntity session) async {
    await _db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// 增加消息计数
  Future<void> incrementMessageCount(String sessionId) async {
    await _db.rawUpdate(
      'UPDATE sessions SET message_count = message_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, sessionId],
    );
  }

  /// 删除会话（级联删除消息）
  Future<void> delete(String id) async {
    await _db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

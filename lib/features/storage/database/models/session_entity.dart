/// 会话实体（对应 sessions 表）
class SessionEntity {
  final String id;
  final String tenantId; // 统一社会信用代码
  final String title;
  final int createdAt; // 毫秒时间戳
  final int updatedAt; // 毫秒时间戳
  final int messageCount;

  const SessionEntity({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tenant_id': tenantId,
        'title': title,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'message_count': messageCount,
      };

  factory SessionEntity.fromMap(Map<String, dynamic> map) => SessionEntity(
        id: map['id'] as String,
        tenantId: map['tenant_id'] as String,
        title: map['title'] as String,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
        messageCount: map['message_count'] as int? ?? 0,
      );

  SessionEntity copyWith({
    String? title,
    int? updatedAt,
    int? messageCount,
  }) =>
      SessionEntity(
        id: id,
        tenantId: tenantId,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messageCount: messageCount ?? this.messageCount,
      );
}

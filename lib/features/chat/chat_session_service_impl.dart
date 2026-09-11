/// 对话会话服务实现
///
/// 从 home_tab.dart 抽取，负责所有数据库/存储操作：
/// 多租户数据库初始化、会话 CRUD、消息持久化、原始 JSON 存档、
/// AI 回复后的自动记忆提炼。UI 层只调用本类，不直接接触 DAO/Entity。
library;

import 'package:flutter/foundation.dart';

import '../../contracts/chat_service.dart';
import '../../contracts/chat_session_service.dart';
import '../enterprise/enterprise_auth_service.dart';
import '../enterprise/enterprise_data.dart';
import '../enterprise/enterprise_model.dart';
import '../memory/memory_distiller.dart';
import '../storage/database/app_database.dart';
import '../storage/database/dao/message_dao.dart';
import '../storage/database/dao/session_dao.dart';
import '../storage/database/models/message_entity.dart';
import '../storage/database/models/session_entity.dart';
import '../storage/session_archive.dart';

class ChatSessionServiceImpl implements ChatSessionService {
  final SessionDao _sessionDao = SessionDao();
  final MessageDao _messageDao = MessageDao();

  final List<Conversation> _conversations = [
    Conversation(id: 'default', title: '新对话'),
  ];
  int _currentIndex = 0;
  String? _tenantId;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  List<Conversation> get conversations => _conversations;

  @override
  int get currentIndex => _currentIndex;

  @override
  Conversation get currentConversation => _conversations[_currentIndex];

  @override
  List<ChatMessage> get currentMessages => _conversations[_currentIndex].messages;

  @override
  Future<void> init() async {
    try {
      final auth = await EnterpriseAuthService.getAuth();
      if (auth == null) {
        _ready = true;
        return;
      }

      // 查找企业信用代码作为租户ID
      Enterprise? ent;
      try {
        ent = kEnterpriseSeedData.firstWhere(
          (e) => e.id == auth.enterpriseId || e.name == auth.enterpriseName,
        );
      } catch (_) {
        ent = null;
      }

      final tenantId = ent?.creditCode.isNotEmpty == true
          ? ent!.creditCode
          : auth.enterpriseId;
      _tenantId = tenantId;

      // 打开该租户的数据库
      await appDatabase.open(tenantId);

      // 加载历史会话
      final sessions = await _sessionDao.findByTenant(tenantId);
      if (sessions.isNotEmpty) {
        final convList = sessions
            .map((s) => Conversation(
                  id: s.id,
                  title: s.title,
                  createdAt:
                      DateTime.fromMillisecondsSinceEpoch(s.createdAt),
                  updatedAt:
                      DateTime.fromMillisecondsSinceEpoch(s.updatedAt),
                ))
            .toList();

        // 加载每个会话的消息
        for (final conv in convList) {
          final msgs = await _messageDao.findBySession(conv.id);
          conv.messages.addAll(msgs.map((m) => ChatMessage(
                role: m.role,
                content: m.content,
                attachment: m.attachmentPath != null
                    ? ChatAttachment(
                        type: m.attachmentType == 'image'
                            ? ChatAttachmentType.image
                            : ChatAttachmentType.document,
                        filePath: m.attachmentPath!,
                        name: '',
                      )
                    : null,
              )));
        }

        _conversations.clear();
        _conversations.addAll(convList);
        _currentIndex = 0;
      } else {
        // 没有历史会话，把默认的"新对话"存入数据库
        final now = DateTime.now().millisecondsSinceEpoch;
        final session = SessionEntity(
          id: _conversations.first.id,
          tenantId: tenantId,
          title: '新对话',
          createdAt: now,
          updatedAt: now,
        );
        await _sessionDao.insert(session);
      }
      _ready = true;
    } catch (e) {
      debugPrint('数据库初始化失败: $e');
      _ready = true;
    }
  }

  @override
  Future<String> newConversation() async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _conversations.insert(
      0,
      Conversation(
        id: newId,
        title: '新对话',
      ),
    );
    _currentIndex = 0;

    // 写入数据库
    if (_tenantId != null && _ready) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _sessionDao.insert(SessionEntity(
        id: newId,
        tenantId: _tenantId!,
        title: '新对话',
        createdAt: now,
        updatedAt: now,
      ));
    }
    return newId;
  }

  @override
  void switchConversation(int index) {
    if (index < 0 || index >= _conversations.length) return;
    _currentIndex = index;
  }

  @override
  Future<void> persistMessage(ChatMessage msg) async {
    if (_tenantId == null || !_ready) return;
    final sessionId = _conversations[_currentIndex].id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final entity = MessageEntity(
      id: '${now}_${msg.role}_${msg.content.length}',
      sessionId: sessionId,
      role: msg.role,
      content: msg.content,
      attachmentType: msg.attachment?.type.name,
      attachmentPath: msg.attachment?.filePath,
      createdAt: now,
    );
    try {
      await _messageDao.insert(entity);
      await _sessionDao.incrementMessageCount(sessionId);
    } catch (e) {
      debugPrint('消息持久化失败: $e');
      return;
    }
    // 同步把整个会话覆盖写入原始 JSON 存档
    await syncArchive();
    // AI 回复完成后，后台自动提炼对话记忆（不阻塞、失败静默）
    if (msg.role == 'assistant') {
      _triggerDistill();
    }
  }

  @override
  Future<void> updateSessionTitle(String title) async {
    if (_tenantId == null || !_ready) return;
    final sessionId = _conversations[_currentIndex].id;
    try {
      final session = await _sessionDao.findById(sessionId);
      if (session != null) {
        await _sessionDao.update(session.copyWith(
          title: title,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    } catch (e) {
      debugPrint('更新会话标题失败: $e');
    }
  }

  @override
  Future<void> syncArchive() async {
    if (_tenantId == null || !_ready) return;
    final sessionId = _conversations[_currentIndex].id;
    try {
      final session = await _sessionDao.findById(sessionId);
      if (session == null) return;
      final msgs = await _messageDao.findBySession(sessionId);
      await sessionArchive.save(
        tenantId: _tenantId!,
        session: session,
        messages: msgs,
      );
    } catch (e) {
      debugPrint('会话存档失败: $e');
    }
  }

  /// 后台触发对话记忆自动提炼（fire-and-forget）
  void _triggerDistill() {
    if (_tenantId == null || !_ready) return;
    final conv = _conversations[_currentIndex];
    MemoryDistiller.distillAndSave(
      tenantId: _tenantId!,
      conversationText: _conversationToText(conv),
    ).catchError((Object e) {
      debugPrint('自动提炼失败: $e');
      return false;
    });
  }

  /// 把会话消息转为模型可读的对话文本（带附件名，不携带文档正文）
  String _conversationToText(Conversation conv) {
    final buf = StringBuffer();
    for (final m in conv.messages) {
      final role = m.role == 'user' ? '用户' : '智懂你';
      buf.writeln('【$role】${m.content}');
      if (m.attachment != null && m.attachment!.name.isNotEmpty) {
        buf.writeln('（附件：${m.attachment!.name}）');
      }
    }
    return buf.toString();
  }
}

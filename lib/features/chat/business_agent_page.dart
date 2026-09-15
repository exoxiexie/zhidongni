/// 业务智能体详情页
///
/// 左上角：返回箭头 + 双横杠菜单（打开左侧抽屉，显示本智能体历史对话）
/// 内容区：智能体占位信息 + 对话消息列表（持久化到数据库）
/// 底部：与对话页完全一致的输入栏（ChatInputBar）
/// 上下文：打开时加载该业务标签（[title]）下已沉淀的数据，
/// 组装成系统提示词注入对话（BusinessContextService）
library;

import 'package:flutter/material.dart';

import '../../contracts/agent_service.dart';
import '../../contracts/chat_service.dart';
import '../data/business_agent_role.dart';
import '../data/business_context_service.dart';
import '../enterprise/enterprise_auth_service.dart';
import '../storage/database/dao/message_dao.dart';
import '../storage/database/dao/session_dao.dart';
import '../storage/database/models/message_entity.dart';
import '../storage/database/models/session_entity.dart';
import 'chat_input_bar.dart';

/// 业务智能体详情页
class BusinessAgentPage extends StatefulWidget {
  final String title;
  final String tenantId; // 企业统一社会信用代码（业务上下文按租户隔离加载）
  final ChatService chatService;
  final AgentService? agentService;

  const BusinessAgentPage({
    super.key,
    required this.title,
    required this.tenantId,
    required this.chatService,
    this.agentService,
  });

  @override
  State<BusinessAgentPage> createState() => _BusinessAgentPageState();
}

class _BusinessAgentPageState extends State<BusinessAgentPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;
  ChatModel _selectedModel = kChatModels[0];

  /// 业务域上下文
  String? _businessContext;
  bool _contextLoading = true;

  // === 会话管理 ===
  final SessionDao _sessionDao = SessionDao();
  final MessageDao _messageDao = MessageDao();
  List<SessionEntity> _sessions = [];
  SessionEntity? _currentSession;
  List<ChatMessage> _messages = [];
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = await EnterpriseAuthService.getAuth();
    _currentUserPhone = auth?.phone;
    await _loadBusinessContext();
    await _loadSessions();
  }

  /// 加载该业务标签下的沉淀数据，组装为系统提示词上下文
  Future<void> _loadBusinessContext() async {
    try {
      final context = await BusinessContextService.build(
          tenantId: widget.tenantId, businessTag: widget.title);
      final fullPrompt =
          BusinessAgentRole.buildSystemPrompt(widget.title, context);
      if (mounted) {
        setState(() {
          _businessContext = fullPrompt;
          _contextLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载业务上下文失败: $e');
      if (mounted) setState(() => _contextLoading = false);
    }
  }

  /// 加载本智能体的会话列表
  Future<void> _loadSessions() async {
    try {
      final isOwner = (await EnterpriseAuthService.getAuth())?.role == 'owner';
      final list = isOwner
          ? await _sessionDao.findByTenantAndBusiness(
              widget.tenantId, widget.title)
          : await _sessionDao.findByTenantAndBusiness(
              widget.tenantId, widget.title,
              createdBy: _currentUserPhone);
      if (mounted) {
        setState(() => _sessions = list);
        // 如果有会话，加载最近一个；否则新建一个
        if (list.isNotEmpty) {
          _switchSession(list.first);
        } else {
          _createNewSession();
        }
      }
    } catch (e) {
      debugPrint('加载会话列表失败: $e');
    }
  }

  /// 新建会话
  void _createNewSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final session = SessionEntity(
      id: now.toString(),
      tenantId: widget.tenantId,
      title: '${widget.title}对话',
      createdAt: now,
      updatedAt: now,
      createdBy: _currentUserPhone,
      businessTag: widget.title,
    );
    await _sessionDao.insert(session);
    if (mounted) {
      setState(() {
        _currentSession = session;
        _messages = [];
        _sessions.insert(0, session);
      });
    }
  }

  /// 切换会话，加载历史消息
  void _switchSession(SessionEntity session) async {
    final msgs = await _messageDao.findBySession(session.id);
    if (mounted) {
      setState(() {
        _currentSession = session;
        _messages = msgs
            .map((m) => ChatMessage(role: m.role, content: m.content))
            .toList();
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _currentSession == null) return;
    final sessionId = _currentSession!.id;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // 保存用户消息到数据库
    final now = DateTime.now().millisecondsSinceEpoch;
    await _messageDao.insert(MessageEntity(
      id: 'u$now',
      sessionId: sessionId,
      role: 'user',
      content: text,
      createdAt: now,
    ));
    await _sessionDao.incrementMessageCount(sessionId);

    try {
      final reply = await widget.chatService.sendMessage(
        _messages
            .map((m) => ChatMessage(role: m.role, content: m.content))
            .toList(),
        model: _selectedModel.id,
        systemExtra: _businessContext,
      );
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: reply));
          _isLoading = false;
        });
        _scrollToBottom();

        // 保存助手回复到数据库
        final now2 = DateTime.now().millisecondsSinceEpoch;
        await _messageDao.insert(MessageEntity(
          id: 'a$now2',
          sessionId: sessionId,
          role: 'assistant',
          content: reply,
          createdAt: now2,
        ));
        await _sessionDao.incrementMessageCount(sessionId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
              ChatMessage(role: 'assistant', content: '请求失败，请稍后重试（$e）'));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  /// 双杠菜单图标（上面长、下面短，与通用对话页同款）
  Widget _buildMenuIcon() {
    return Center(
      child: InkWell(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 22,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xCC1A1B1C),
                    borderRadius: BorderRadius.circular(1.25),
                  )),
              const SizedBox(height: 6),
              Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xCC1A1B1C),
                    borderRadius: BorderRadius.circular(1.25),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// 左侧抽屉（本智能体历史对话）
  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // 顶部：新建对话按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _createNewSession();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建对话'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // 历史对话列表
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Text('暂无历史对话',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sessions.length,
                    itemBuilder: (ctx, i) {
                      final s = _sessions[i];
                      final active = s.id == _currentSession?.id;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          active
                              ? Icons.chat_bubble
                              : Icons.chat_bubble_outline,
                          size: 18,
                          color: active
                              ? const Color(0xFF5B7FD4)
                              : const Color(0x661A1B1C),
                        ),
                        title: Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            color: active
                                ? const Color(0xFF5B7FD4)
                                : const Color(0xFF1A1B1C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${s.messageCount} 条消息',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                        selected: active,
                        onTap: () {
                          _switchSession(s);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leadingWidth: 122,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 16,
                    color: Color(0xFF1B3A5C)),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: '返回',
              ),
              const SizedBox(width: 6),
              _buildMenuIcon(),
            ],
          ),
        ),
        // 右上角：新建对话
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 22),
            onPressed: _createNewSession,
            tooltip: '新建对话',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyAgent(context)
                : _buildMessageList(),
          ),
          ChatInputBar(
            controller: _controller,
            isLoading: _isLoading,
            selectedModel: _selectedModel,
            onModelChanged: (m) {
              setState(() => _selectedModel = m);
            },
            onAddAttachment: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('智能体附件功能开发中')),
              );
            },
            onSend: _send,
            onConnectComputer: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('连接电脑功能开发中')),
              );
            },
            onSkillSelect: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('技能选择功能开发中')),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 智能体占位信息
  Widget _buildEmptyAgent(BuildContext context) {
    final subtitle =
        _contextLoading ? '正在加载本业务域沉淀数据…' : '已加载业务域数据上下文，可以在下方直接对话';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF5B7FD4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 32, color: Color(0xFF5B7FD4)),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1B1C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const _ThinkingBubble();
        }
        return _Bubble(message: _messages[index]);
      },
    );
  }

  /// 自动滚动到消息列表底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// 单条消息气泡
class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.72 : 0.9),
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF5B7FD4) : const Color(0x0F000000),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: isUser ? Colors.white : const Color(0xFF1A1B1C),
          ),
        ),
      ),
    );
  }
}

/// 思考中气泡
class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          '正在思考…',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }
}

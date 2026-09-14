/// 业务智能体详情页
///
/// 左上角：向左尖括号返回（与首页顶部卡片箭头同款样式）
/// 内容区：智能体占位信息 + 对话消息列表
/// 底部：与对话页完全一致的输入栏（ChatInputBar），可直接对话
/// 上下文：打开时加载该业务标签（[title]）下已沉淀的数据，
/// 组装成系统提示词注入对话（BusinessContextService）
library;

import 'package:flutter/material.dart';

import '../../contracts/agent_service.dart';
import '../../contracts/chat_service.dart';
import '../data/business_agent_role.dart';
import '../data/business_context_service.dart';
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
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  ChatModel _selectedModel = kChatModels[0];

  /// 业务域上下文（加载完成后注入对话）
  String? _businessContext;

  /// 上下文加载状态
  bool _contextLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessContext();
  }

  /// 加载该业务标签下的沉淀数据，组装为系统提示词上下文
  /// （角色定义 + 业务域数据现状 合并为一个系统提示词）
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _isLoading = true;
    });
    try {
      // 智能体单轮对话：业务域上下文作为系统提示词注入
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages
              .add(ChatMessage(role: 'assistant', content: '请求失败，请稍后重试（$e）'));
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        // 左上角：向左尖括号返回（与首页顶部卡片箭头同款）
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Color(0xFF1B3A5C),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '返回',
        ),
      ),
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
}

/// 单条消息气泡（与对话页样式一致）
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

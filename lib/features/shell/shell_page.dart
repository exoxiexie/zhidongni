/// 主框架模块 · 登录后的四栏导航壳
///
/// 底部四个 Tab：懂你 / 数据 / 发现 / 我的。
/// 对话页不再占用 Tab，改为独立页面（从首页"对话"卡片进入）。
library;

import 'package:flutter/material.dart';

import '../../contracts/agent_service.dart';
import '../../contracts/chat_service.dart';
import '../chat/business_agent_page.dart';
import '../chat/chat_page.dart';
import '../data/business_seed_data.dart';
import '../discover/discover_tab.dart';
import '../enterprise/enterprise_auth_service.dart';
import '../enterprise/enterprise_data.dart';
import '../tabs/database_tab.dart';
import '../tabs/insight_tab.dart';
import '../tabs/profile_tab.dart';

/// 登录后的主框架
class ShellPage extends StatefulWidget {
  final ChatService? chatService;
  final AgentService? agentService;

  const ShellPage({super.key, this.chatService, this.agentService});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  /// Tab 索引：0 懂你（首页）、1 数据、2 发现、3 我的
  int _index = 0;
  final GlobalKey<DatabaseTabState> _databaseTabKey =
      GlobalKey<DatabaseTabState>();

  /// 当前企业统一社会信用代码（租户ID，用于业务上下文按租户隔离加载）
  String _currentTenantId = '';

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  /// 加载当前登录企业的租户ID，并确保业务域种子数据已写入
  Future<void> _loadTenant() async {
    try {
      final auth = await EnterpriseAuthService.getAuth();
      if (auth != null) {
        for (final e in kEnterpriseSeedData) {
          if (e.id == auth.enterpriseId || e.name == auth.enterpriseName) {
            if (mounted) setState(() => _currentTenantId = e.creditCode);
            // 幂等：为模拟企业业务域表注入种子数据（已有数据不重复写）
            await BusinessSeedService.seedIfEmpty(e.creditCode);
            break;
          }
        }
      }
    } catch (_) {
      // 加载失败不影响主框架使用（业务上下文降级为不注入）
    }
  }

  static const _titles = ['懂你', '数据', '发现', '我的'];

  /// 打开对话页（不带指令）
  void openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatService: widget.chatService!,
          agentService: widget.agentService,
        ),
      ),
    );
  }

  /// 打开业务智能体详情页（业务域上下文按当前企业租户加载）
  void openAgent(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessAgentPage(
          title: title,
          tenantId: _currentTenantId,
          chatService: widget.chatService!,
          agentService: widget.agentService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InsightTab(onOpenChat: openChat, onOpenAgent: openAgent),
      DatabaseTab(key: _databaseTabKey),
      DiscoverTab(chatService: widget.chatService, agentService: widget.agentService),
      const ProfileTab(),
    ];

    return Scaffold(
      appBar: (_index == 3 || _index == 2)
          ? null
          : AppBar(
              title: Text(_titles[_index]),
              centerTitle: true,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          // 切换到数据页时刷新记忆列表（让自动提炼的记忆立即可见）
          // 数据页是第2位（index 1）
          if (i == 1) {
            _databaseTabKey.currentState?.refresh();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: '懂你',
          ),
          NavigationDestination(
            icon: Icon(Icons.dataset_outlined),
            selectedIcon: Icon(Icons.dataset),
            label: '数据',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

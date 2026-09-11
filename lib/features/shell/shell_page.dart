/// 主框架模块 · 登录后的五栏导航壳
///
/// 底部五个 Tab：数据 / 懂你 / 对话 / 发现 / 我的。
library;

import 'package:flutter/material.dart';

import '../../contracts/agent_service.dart';
import '../../contracts/chat_service.dart';
import '../tabs/home_tab.dart';
import '../tabs/database_tab.dart';
import '../tabs/files_tab.dart';
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
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<DatabaseTabState> _databaseTabKey =
      GlobalKey<DatabaseTabState>();

  static const _titles = ['数据', '懂你', '对话', '发现', '我的'];

  /// 双杠菜单图标（上面长、下面短，经典 AI 产品风格）
  /// 点击区域放大，用 InkWell 确保整个区域都能响应点击
  Widget _buildMenuIcon() {
    return Center(
      child: InkWell(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  /// 左侧抽屉（经典 AI 产品风格：新建对话 + 历史对话列表）
  /// 宽度为屏幕的 80%，从左向右滑入，点击右侧 20% 阴影区或左滑关闭
  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: StatefulBuilder(
        builder: (ctx, setDrawerState) {
          final conversations = _homeTabKey.currentState?.conversations ?? [];
          final currentIndex = _homeTabKey.currentState?.currentIndex ?? 0;

          return Column(
            children: [
              // 顶部：新建对话按钮
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _homeTabKey.currentState?.newConversation();
                        setDrawerState(() {}); // 刷新抽屉列表
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
              // 历史对话列表（真实数据）
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  itemBuilder: (ctx, i) {
                    final conv = conversations[i];
                    final active = i == currentIndex;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        active ? Icons.chat_bubble : Icons.chat_bubble_outline,
                        size: 18,
                        color: active
                            ? const Color(0xFF5B7FD4)
                            : const Color(0x661A1B1C),
                      ),
                      title: Text(
                        conv.title,
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
                        '${conv.messages.length} 条消息',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                      selected: active,
                      onTap: () {
                        _homeTabKey.currentState?.switchConversation(i);
                        setDrawerState(() {});
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(String title, bool active) {
    return ListTile(
      dense: true,
      leading: Icon(
        active ? Icons.chat_bubble : Icons.chat_bubble_outline,
        size: 18,
        color: active ? const Color(0xFF5B7FD4) : const Color(0x661A1B1C),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: active ? const Color(0xFF5B7FD4) : const Color(0xCC1A1B1C),
          fontWeight: active ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.pop(context),
    );
  }

  /// 供外部调用：快捷指令跳转——切换到对话页并填入预设指令
  void sendPresetCommand(String command) {
    setState(() => _index = 2); // 切换到对话页
    // 等待对话页构建完成后设置输入框内容
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeTabKey.currentState?.setInputText(command);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DatabaseTab(key: _databaseTabKey),
      InsightTab(onPresetCommand: sendPresetCommand),
      HomeTab(
        key: _homeTabKey,
        chatService: widget.chatService!,
        agentService: widget.agentService,
      ),
      const FilesTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
        elevation: 0,
        // 禁止自动显示默认菜单按钮（Scaffold有drawer时leading=null会自动显示汉堡图标）
        automaticallyImplyLeading: false,
        // 仅对话页显示双杠菜单图标
        leading: _index == 2 ? _buildMenuIcon() : null,
        // 仅对话页显示右上角笔图标（新建对话）
        actions: _index == 2
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, size: 22),
                  onPressed: () => _homeTabKey.currentState?.newConversation(),
                  tooltip: '新建对话',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          // 切换到数据页时刷新记忆列表（让自动提炼的记忆立即可见）
          if (i == 0) {
            _databaseTabKey.currentState?.refresh();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dataset_outlined),
            selectedIcon: Icon(Icons.dataset),
            label: '数据',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: '懂你',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '对话',
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

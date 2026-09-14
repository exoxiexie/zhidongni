/// 懂你 Tab · 对话入口 + 功能栏目列表
///
/// 顶部：对话入口卡片（点击进入对话页）
/// 下方：业务智能体栏目（右上角齿轮可管理卡片开关）
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightTab extends StatefulWidget {
  /// 打开对话页回调（点击顶部"对话"板块时触发）
  final VoidCallback? onOpenChat;

  /// 打开业务智能体详情页回调（点击下方业务智能体时触发，传入智能体名称）
  final void Function(String title)? onOpenAgent;

  const InsightTab({super.key, this.onOpenChat, this.onOpenAgent});

  @override
  State<InsightTab> createState() => _InsightTabState();
}

class _InsightTabState extends State<InsightTab> {
  /// 全部业务智能体定义（顺序即展示顺序）
  static const List<_AgentDef> _agents = [
    _AgentDef(Icons.account_balance_outlined, Color(0xFF2563EB), '贷款',
        '融资、贷款、资金周转评估'),
    _AgentDef(Icons.business_outlined, Color(0xFF059669), '工商', '企业工商登记信息'),
    _AgentDef(
        Icons.receipt_long_outlined, Color(0xFFF97316), '税务', '税务申报、筹划与合规'),
    _AgentDef(Icons.balance_outlined, Color(0xFF0D9488), '司法', '司法诉讼与案件信息'),
    _AgentDef(Icons.verified_outlined, Color(0xFF0891B2), '信用', '企业信用评级与风险'),
    _AgentDef(Icons.calculate_outlined, Color(0xFF0EA5E9), '财务', '财务核算、分析与报表'),
    _AgentDef(
        Icons.copyright_outlined, Color(0xFF7C3AED), '知识产权', '商标、专利与版权保护'),
    _AgentDef(
        Icons.assignment_outlined, Color(0xFF14B8A6), '政策申报', '惠企政策匹配与申报'),
    _AgentDef(
        Icons.fact_check_outlined, Color(0xFF0284C7), '项目审批', '项目立项、审批与备案'),
    _AgentDef(Icons.gavel, Color(0xFF6366F1), '法律', '合同审查与法务咨询'),
    _AgentDef(
        Icons.health_and_safety_outlined, Color(0xFFEA6668), '社保', '社保、公积金管理'),
    _AgentDef(
        Icons.local_shipping_outlined, Color(0xFFF59E0B), '供应链', '上下游协同与风险监测'),
  ];

  /// 智能体显示开关（title -> 是否显示），默认全部开启
  final Map<String, bool> _enabled = {};

  @override
  void initState() {
    super.initState();
    _loadEnabled();
  }

  Future<void> _loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final a in _agents) {
      map[a.title] = prefs.getBool('agent_enabled_${a.title}') ?? true;
    }
    if (mounted) {
      setState(() {
        _enabled
          ..clear()
          ..addAll(map);
      });
    }
  }

  bool _isEnabled(String title) => _enabled[title] ?? true;

  Future<void> _setEnabled(String title, bool value) async {
    setState(() => _enabled[title] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agent_enabled_$title', value);
  }

  /// 打开业务智能体管理面板（齿轮）
  void _showManageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.66,
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
                    child: Text(
                      '管理业务智能体',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1B1C),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      '关闭后该智能体卡片将不在首页显示',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _agents.length,
                      itemBuilder: (context, i) {
                        final a = _agents[i];
                        final enabled = _enabled[a.title] ?? true;
                        return ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: a.iconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(a.icon, size: 18, color: Colors.white),
                          ),
                          title: Text(
                            a.title,
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xFF1A1B1C)),
                          ),
                          subtitle: Text(
                            a.subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                          trailing: Switch(
                            value: enabled,
                            activeColor: const Color(0xFF5B7FD4),
                            onChanged: (v) {
                              setSheetState(() => _enabled[a.title] = v);
                              _setEnabled(a.title, v);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 按开关状态过滤需要显示的业务智能体
    final visibleAgents = _agents.where((a) => _isEnabled(a.title)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 顶部大卡片：对话 | 洞察 上下两个板块（整体浅蓝渐变）
              _buildTopCard(context),
              const SizedBox(height: 16),
              // 业务智能体栏目标题行（右侧齿轮管理开关）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '业务智能体',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const Spacer(),
                    // 细齿轮：管理业务智能体卡片开关
                    InkWell(
                      onTap: _showManageSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildSection([
                for (final a in visibleAgents)
                  _InsightItem(
                    icon: a.icon,
                    iconBg: a.iconBg,
                    title: a.title,
                    subtitle: a.subtitle,
                    onTap: () => widget.onOpenAgent?.call(a.title),
                  ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部大卡片：对话 | 洞察 上下两个板块（整体浅蓝渐变撑满，无白边）
  Widget _buildTopCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFBFD9F2), Color(0xFF8FB8E0)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 上：对话板块（InkWell 整块区域可点，含空白处）
          InkWell(
            onTap: widget.onOpenChat,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // 图标
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat_bubble_outline,
                          size: 22, color: Color(0xFF1B3A5C)),
                    ),
                    const SizedBox(width: 12),
                    // 标题和小字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '对话',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B3A5C),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '与智懂你 AI 管家对话',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF1B3A5C).withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 右侧箭头
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Color(0xFF1B3A5C)),
                  ],
                ),
              ),
            ),
          ),
          // 分隔线（白色半透明）
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: Color(0x59FFFFFF)),
          ),
          // 下：洞察板块
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const _PlaceholderPage(title: '洞察')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FD4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  // 标题和副标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '洞察',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1B3A5C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '基于企业数据生成分析报告',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF1B3A5C).withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右侧箭头
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF1B3A5C),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1, color: Color(0xFFE4E3DD)),
              ),
          ],
        ],
      ),
    );
  }
}

/// 洞察栏目项
class _InsightItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InsightItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // 中间标题和副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1B1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // 右侧箭头
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFFC4C4C4),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页（功能开发中）
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        // 左上角：向左尖括号返回（与首页顶部卡片箭头同款样式）
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
      body: const Center(
        child: Text(
          '功能开发中',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

/// 业务智能体定义（图标、配色、名称、副标题）
class _AgentDef {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _AgentDef(this.icon, this.iconBg, this.title, this.subtitle);
}

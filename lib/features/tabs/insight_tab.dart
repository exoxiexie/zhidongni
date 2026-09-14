/// 懂你 Tab · 对话入口 + 功能栏目列表
///
/// 顶部：对话入口卡片（点击进入对话页）
/// 下方：深入洞察、风险预警等功能栏目
library;

import 'package:flutter/material.dart';

class InsightTab extends StatelessWidget {
  /// 打开对话页回调（点击顶部"对话"卡片时触发）
  final VoidCallback? onOpenChat;

  const InsightTab({super.key, this.onOpenChat});

  @override
  Widget build(BuildContext context) {
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
              // 业务智能体栏目
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '业务智能体',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildSection([
                _InsightItem(
                  icon: Icons.account_balance_outlined,
                  iconBg: const Color(0xFF2563EB),
                  title: '贷款',
                  subtitle: '融资、贷款、资金周转评估',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '贷款')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.business_outlined,
                  iconBg: const Color(0xFF059669),
                  title: '工商',
                  subtitle: '企业工商登记信息',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '工商')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.receipt_long_outlined,
                  iconBg: const Color(0xFFF97316),
                  title: '税务',
                  subtitle: '税务申报、筹划与合规',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '税务')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.calculate_outlined,
                  iconBg: const Color(0xFF0EA5E9),
                  title: '财务',
                  subtitle: '财务核算、分析与报表',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '财务')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.copyright_outlined,
                  iconBg: const Color(0xFF7C3AED),
                  title: '知识产权',
                  subtitle: '商标、专利与版权保护',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '知识产权')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.assignment_outlined,
                  iconBg: const Color(0xFF14B8A6),
                  title: '政策申报',
                  subtitle: '惠企政策匹配与申报',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '政策申报')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.gavel,
                  iconBg: const Color(0xFF6366F1),
                  title: '法律',
                  subtitle: '合同审查与法务咨询',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '法律')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.health_and_safety_outlined,
                  iconBg: const Color(0xFFEA6668),
                  title: '社保',
                  subtitle: '社保、公积金管理',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '社保')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.local_shipping_outlined,
                  iconBg: const Color(0xFFF59E0B),
                  title: '供应链',
                  subtitle: '上下游协同与风险监测',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '供应链')),
                    );
                  },
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
          // 上：对话板块
          GestureDetector(
            onTap: onOpenChat,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          // 分隔线（白色半透明）
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: Color(0x59FFFFFF)),
          ),
          // 下：洞察板块
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '洞察')),
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

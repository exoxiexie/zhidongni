/// 懂你 Tab · 快捷指令入口 + 功能栏目列表
///
/// 顶部：快捷指令卡片（点击进入预设指令列表，选择后自动填入对话框并跳转）
/// 下方：深入洞察、风险预警等功能栏目
library;

import 'package:flutter/material.dart';

class InsightTab extends StatelessWidget {
  /// 快捷指令回调：选择预设指令后，由 ShellPage 切换到对话页并填入指令
  final void Function(String command)? onPresetCommand;

  const InsightTab({super.key, this.onPresetCommand});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 快捷指令卡片
              _buildPresetCommandCard(context),
              const SizedBox(height: 16),
              // 功能栏目列表
              _buildSection([
                _InsightItem(
                  icon: Icons.auto_awesome,
                  iconBg: const Color(0xFF5B7FD4),
                  title: '深入洞察',
                  subtitle: 'AI 基于企业数据生成分析报告与行动建议',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '深入洞察')),
                    );
                  },
                ),
                _InsightItem(
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFFEA6668),
                  title: '风险预警',
                  subtitle: '工商、税务、司法等企业自身风险监测',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderPage(title: '风险预警')),
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

  /// 快捷指令入口卡片
  Widget _buildPresetCommandCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PresetCommandsPage(onSelect: onPresetCommand),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B7FD4), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tips_and_updates_outlined, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // 中间标题和小字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '试试像这样给我下指令',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '正确的、完整的指令会得到更好的结果',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // 右侧箭头
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          ],
        ),
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

/// 快捷指令列表页
class PresetCommandsPage extends StatelessWidget {
  final void Function(String command)? onSelect;

  const PresetCommandsPage({super.key, this.onSelect});

  /// 预设指令分类和内容
  List<PresetCommandCategory> get _categories => [
    PresetCommandCategory(
      name: '热门指令',
      icon: Icons.local_fire_department_outlined,
      color: const Color(0xFFF97316),
      commands: [
        '帮我全面分析一下我公司当前的经营状况和潜在风险，给出 actionable 的改进建议',
        '根据我公司的数据，生成一份本周的智能运营简报，重点突出关键指标变化和需要关注的事项',
        '帮我检查一下我公司有没有需要立即处理的风险预警，包括工商、税务、司法和信用方面',
      ],
    ),
    PresetCommandCategory(
      name: '经营分析',
      icon: Icons.analytics_outlined,
      color: const Color(0xFF2563EB),
      commands: [
        '帮我分析一下我公司当前的经营状况，包括财务健康度、业务增长趋势和主要风险点',
        '根据我公司的行业特点和经营数据，给我一份未来3个月的业务发展建议',
        '帮我做一份公司月度运营报告，重点突出关键指标变化和需要关注的问题',
      ],
    ),
    PresetCommandCategory(
      name: '风险预警',
      icon: Icons.shield_outlined,
      color: const Color(0xFFDC2626),
      commands: [
        '帮我检查一下我公司有没有潜在的法律风险，包括合同、劳动、知识产权等方面',
        '根据工商、税务、司法公开信息，评估我公司当前的信用风险等级',
        '帮我梳理一下我公司可能面临的合规风险，并给出整改建议',
      ],
    ),
    PresetCommandCategory(
      name: '战略规划',
      icon: Icons.trending_up_outlined,
      color: const Color(0xFF7C3AED),
      commands: [
        '根据我公司的行业地位和资源禀赋，帮我制定一份年度战略规划',
        '分析我公司主要竞争对手的情况，找出我们的差异化优势和改进方向',
        '帮我整理一份给投资人的公司简介，突出商业模式、增长潜力和竞争壁垒',
      ],
    ),
    PresetCommandCategory(
      name: '日常办公',
      icon: Icons.work_outline,
      color: const Color(0xFF059669),
      commands: [
        '帮我制定一份季度工作计划，按优先级排列关键任务和时间节点',
        '根据我公司的业务情况，帮我写一封给客户的商务合作邮件',
        '帮我整理一份会议纪要模板，适用于公司内部的项目评审会议',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷指令'),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, PresetCommandCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, size: 16, color: category.color),
                ),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1B1C),
                  ),
                ),
              ],
            ),
          ),
          // 指令列表
          for (int i = 0; i < category.commands.length; i++) ...[
            InkWell(
              onTap: () {
                onSelect?.call(category.commands[i]);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        category.commands[i],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFC4C4C4)),
                  ],
                ),
              ),
            ),
            if (i < category.commands.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// 预设指令分类模型
class PresetCommandCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> commands;

  const PresetCommandCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.commands,
  });
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

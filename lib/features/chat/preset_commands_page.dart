/// 快捷指令列表页 · 对话页顶部"试试像这样给我下指令"卡片点击后进入
///
/// 分类展示预设指令，点击后通过 [onSelect] 回调填入输入框。
library;

import 'package:flutter/material.dart';

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

  Widget _buildCategoryCard(
      BuildContext context, PresetCommandCategory category) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    const Icon(Icons.arrow_forward,
                        size: 14, color: Color(0xFFC4C4C4)),
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

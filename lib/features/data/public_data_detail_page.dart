/// 信息公开数据详情页
///
/// 展示5类信息公开数据的大卡片（标题+摘要）：工商、税务、司法、信用、其他。
/// 点击每类卡片进入该类数据的详细信息页。
library;

import 'package:flutter/material.dart';

import '../enterprise/enterprise_data.dart';
import '../enterprise/enterprise_model.dart';
import '../enterprise/public_data.dart';

/// 信息公开数据详情页
class PublicDataDetailPage extends StatelessWidget {
  final String creditCode;

  const PublicDataDetailPage({super.key, required this.creditCode});

  Enterprise? get _enterprise {
    try {
      return kEnterpriseSeedData.firstWhere(
        (e) => e.creditCode == creditCode,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ent = _enterprise;
    final tax = kTaxData[creditCode];
    final judicial = kJudicialData[creditCode];
    final credit = kCreditData[creditCode];

    return Scaffold(
      appBar: AppBar(
        title: const Text('信息公开数据'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 工商信息大卡片
          _buildSummaryCard(
            context: context,
            icon: Icons.business_outlined,
            color: const Color(0xFF2563EB),
            title: '工商信息',
            summaryLines: ent == null
                ? ['暂无数据']
                : [
                    '企业名称：${ent.name}',
                    '法定代表人：${ent.legalPerson}',
                    '注册资本：${ent.registeredCapital}',
                    '成立日期：${ent.foundedAt}',
                    '经营状态：${ent.status}',
                  ],
            onTap: () => _showTypeDetail(
              context,
              title: '工商信息',
              color: const Color(0xFF2563EB),
              rows: ent == null
                  ? {'暂无数据': ''}
                  : {
                      '企业名称': ent.name,
                      '统一社会信用代码': ent.creditCode,
                      '法定代表人': ent.legalPerson,
                      '经营状态': ent.status,
                      '成立日期': ent.foundedAt,
                      '注册资本': ent.registeredCapital,
                      '企业类型': ent.enterpriseType,
                      '所属行业': ent.industry.isEmpty ? '—' : ent.industry,
                      '人员规模': ent.staffScale.isEmpty ? '—' : ent.staffScale,
                      '所在区域': ent.region,
                      '注册地址': ent.address,
                      '经营范围': ent.businessScope,
                    },
            ),
          ),
          const SizedBox(height: 12),
          // 税务信息大卡片
          _buildSummaryCard(
            context: context,
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF059669),
            title: '税务信息',
            summaryLines: tax == null
                ? ['暂无数据']
                : [
                    '纳税等级：${tax.taxRating}',
                    '年纳税额：${tax.annualTaxAmount}万元',
                    '欠税金额：${tax.owedTax}万元',
                    '涉税处罚：${tax.taxPenaltyCount}次',
                    '非正常户：${tax.isTaxAbnormal ? "是" : "否"}',
                  ],
            onTap: () => _showTypeDetail(
              context,
              title: '税务信息',
              color: const Color(0xFF059669),
              rows: tax == null
                  ? {'暂无数据': ''}
                  : {
                      '纳税等级': tax.taxRating,
                      '年纳税额': '${tax.annualTaxAmount}万元',
                      '欠税金额': '${tax.owedTax}万元',
                      '涉税处罚次数': '${tax.taxPenaltyCount}次',
                      if (tax.taxPenalties.isNotEmpty)
                        '处罚记录': tax.taxPenalties
                            .map((p) => '${p.date}｜${p.reason}｜罚款${p.amount}万元｜${p.authority}')
                            .join('\n'),
                      '非正常户': tax.isTaxAbnormal ? '是' : '否',
                    },
            ),
          ),
          const SizedBox(height: 12),
          // 司法信息大卡片
          _buildSummaryCard(
            context: context,
            icon: Icons.gavel_outlined,
            color: const Color(0xFFDC2626),
            title: '司法信息',
            summaryLines: judicial == null
                ? ['暂无数据']
                : [
                    '涉诉总数：${judicial.lawsuitCount}件',
                    '原告/被告：${judicial.asPlaintiffCount}件 / ${judicial.asDefendantCount}件',
                    '执行案件：${judicial.enforcementCount}件（${judicial.enforcementAmount}万元）',
                    '失信被执行人：${judicial.isDishonest ? "是" : "否"}',
                  ],
            onTap: () => _showTypeDetail(
              context,
              title: '司法信息',
              color: const Color(0xFFDC2626),
              rows: judicial == null
                  ? {'暂无数据': ''}
                  : {
                      '涉诉总数': '${judicial.lawsuitCount}件',
                      '作为原告': '${judicial.asPlaintiffCount}件',
                      '作为被告': '${judicial.asDefendantCount}件',
                      if (judicial.cases.isNotEmpty)
                        '案件列表': judicial.cases
                            .map((c) => '${c.caseNo}\n案由：${c.cause}｜角色：${c.role}｜涉案${c.amount}万元｜${c.status}｜${c.result}')
                            .join('\n\n'),
                      '执行案件数': '${judicial.enforcementCount}件',
                      '执行标的总额': '${judicial.enforcementAmount}万元',
                      '失信被执行人': judicial.isDishonest ? '是（失信金额${judicial.dishonestAmount}万元）' : '否',
                    },
            ),
          ),
          const SizedBox(height: 12),
          // 信用信息大卡片
          _buildSummaryCard(
            context: context,
            icon: Icons.verified_outlined,
            color: const Color(0xFF7C3AED),
            title: '信用信息',
            summaryLines: credit == null
                ? ['暂无数据']
                : [
                    '信用评级：${credit.creditRating}（${credit.creditScore}分）',
                    '行政处罚：${credit.administrativePenaltyCount}次',
                    '经营异常：${credit.isBusinessAbnormal ? "是" : "否"}',
                    '严重违法失信：${credit.isSeriousIllegal ? "是" : "否"}',
                  ],
            onTap: () => _showTypeDetail(
              context,
              title: '信用信息',
              color: const Color(0xFF7C3AED),
              rows: credit == null
                  ? {'暂无数据': ''}
                  : {
                      '信用评级': credit.creditRating,
                      '信用分': '${credit.creditScore}分',
                      '行政处罚次数': '${credit.administrativePenaltyCount}次',
                      if (credit.administrativePenalties.isNotEmpty)
                        '处罚记录': credit.administrativePenalties
                            .map((p) => '${p.date}｜${p.reason}｜${p.penaltyType}｜罚款${p.amount}万元｜${p.authority}')
                            .join('\n'),
                      '经营异常': credit.isBusinessAbnormal ? '是（${credit.abnormalReason}）' : '否',
                      '严重违法失信': credit.isSeriousIllegal ? '是' : '否',
                    },
            ),
          ),
          const SizedBox(height: 12),
          // 其他信息大卡片（占位）
          _buildSummaryCard(
            context: context,
            icon: Icons.more_horiz,
            color: const Color(0xFF6B7280),
            title: '其他信息',
            summaryLines: ['功能开发中'],
            onTap: null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 摘要大卡片
  Widget _buildSummaryCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required List<String> summaryLines,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E3DD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC0C4CC)),
              ],
            ),
            const SizedBox(height: 12),
            // 摘要信息
            ...summaryLines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 展示某类数据的详细信息页
  void _showTypeDetail(
    BuildContext context, {
    required String title,
    required Color color,
    required Map<String, String> rows,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E3DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in rows.entries) ...[
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.isEmpty ? '—' : entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1B1C),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

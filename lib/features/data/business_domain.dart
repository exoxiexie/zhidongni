/// 业务域中心注册表 —— 三位一体
///
/// 业务智能体 ↔ 业务标签 ↔ 数据表 一一映射，统一由 [BusinessDomain] 注册：
/// - [id]：统一 ID（如 'tax'），三者共用
/// - [tag]：业务标签值（与 DataBusinessTag 完全一致）
/// - [table]：业务域数据表名（如 'tax_data'）
/// - UI 元数据（图标/颜色/副标题）与角色定义（职责/材料）也注册于此，
///   智能体列表、标签、数据表、角色提示词全部从这里派生，保证一致。
///
/// 三个都可以随时增长：新增业务域时只需在此注册一条，
/// 建表、智能体卡片、标签、上下文注入、按业务视图自动跟随。
library;

import 'package:flutter/material.dart';

import 'data_tags.dart';

/// 业务域定义（三位一体注册单元）
class BusinessDomain {
  /// 统一 ID（贯穿智能体/标签/数据表）
  final String id;

  /// 业务标签值（= DataBusinessTag 对应常量）
  final String tag;

  /// 业务域数据表名（SQLite）
  final String table;

  /// 智能体副标题（首页卡片展示）
  final String subtitle;

  /// 智能体图标
  final IconData icon;

  /// 智能体主题色
  final Color color;

  /// 职责范围（角色系统提示词用）
  final String scope;

  /// 需要用户提供的材料（角色系统提示词引导用）
  final String need;

  const BusinessDomain({
    required this.id,
    required this.tag,
    required this.table,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.scope,
    required this.need,
  });

  /// 按标签值查找
  static BusinessDomain? byTag(String tag) {
    for (final d in kBusinessDomains) {
      if (d.tag == tag) return d;
    }
    return null;
  }

  /// 按统一ID查找
  static BusinessDomain? byId(String id) {
    for (final d in kBusinessDomains) {
      if (d.id == id) return d;
    }
    return null;
  }
}

/// 全部业务域（顺序即展示顺序，三位一体）
const List<BusinessDomain> kBusinessDomains = [
  BusinessDomain(
    id: 'loan',
    tag: DataBusinessTag.loan,
    table: 'loan_data',
    subtitle: '融资、贷款、资金周转评估',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF2563EB),
    scope: '贷款融资、授信申请、还款规划、抵押担保',
    need: '财务报表、银行流水、授信合同、抵押担保材料、贷款合同',
  ),
  BusinessDomain(
    id: 'business',
    tag: DataBusinessTag.business,
    table: 'business_data',
    subtitle: '企业工商登记信息',
    icon: Icons.business_outlined,
    color: Color(0xFF059669),
    scope: '工商注册与变更、股权结构、经营范围、年报公示',
    need: '营业执照、公司章程、股东名册、工商变更记录',
  ),
  BusinessDomain(
    id: 'tax',
    tag: DataBusinessTag.tax,
    table: 'tax_data',
    subtitle: '税务申报、筹划与合规',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFFF97316),
    scope: '纳税信用等级、税务合规排查、发票与申报管理、税收筹划',
    need: '纳税申报表、发票数据、完税证明、税务处罚通知',
  ),
  BusinessDomain(
    id: 'judicial',
    tag: DataBusinessTag.judicial,
    table: 'judicial_data',
    subtitle: '司法诉讼与案件信息',
    icon: Icons.balance_outlined,
    color: Color(0xFF0D9488),
    scope: '诉讼风险评估、被执行与失信预警、合同纠纷分析',
    need: '裁判文书、起诉状、执行信息、法律文书',
  ),
  BusinessDomain(
    id: 'credit',
    tag: DataBusinessTag.credit,
    table: 'credit_data',
    subtitle: '企业信用评级与风险',
    icon: Icons.verified_outlined,
    color: Color(0xFF0891B2),
    scope: '信用评级、行政处罚记录、经营异常名录、信用修复',
    need: '信用报告、行政处罚决定书、经营异常名录信息',
  ),
  BusinessDomain(
    id: 'finance',
    tag: DataBusinessTag.finance,
    table: 'finance_data',
    subtitle: '财务核算、分析与报表',
    icon: Icons.calculate_outlined,
    color: Color(0xFF0EA5E9),
    scope: '财务报表分析、利润与成本、现金流健康度、审计配合',
    need: '资产负债表、利润表、现金流量表、审计报告',
  ),
  BusinessDomain(
    id: 'ip',
    tag: DataBusinessTag.ip,
    table: 'ip_data',
    subtitle: '商标、专利与版权保护',
    icon: Icons.copyright_outlined,
    color: Color(0xFF7C3AED),
    scope: '专利申请、商标注册、著作权登记、侵权风险预警',
    need: '专利证书、商标注册证、版权登记证明、技术文档',
  ),
  BusinessDomain(
    id: 'policy',
    tag: DataBusinessTag.policy,
    table: 'policy_data',
    subtitle: '惠企政策匹配与申报',
    icon: Icons.assignment_outlined,
    color: Color(0xFF14B8A6),
    scope: '政策匹配、补贴与专项资金申报、资质认定辅导',
    need: '政策文件、企业资质证书、历史申报材料',
  ),
  BusinessDomain(
    id: 'project_approval',
    tag: DataBusinessTag.projectApproval,
    table: 'project_approval_data',
    subtitle: '项目立项、审批与备案',
    icon: Icons.fact_check_outlined,
    color: Color(0xFF0284C7),
    scope: '项目立项、备案、环评、招投标',
    need: '项目可行性报告、立项批复、备案文件、环评报告',
  ),
  BusinessDomain(
    id: 'legal',
    tag: DataBusinessTag.legal,
    table: 'legal_data',
    subtitle: '合同审查与法务咨询',
    icon: Icons.gavel,
    color: Color(0xFF6366F1),
    scope: '合同审查、合规风险、违约纠纷、法务咨询',
    need: '合同文本、协议、律师函、法律文书',
  ),
  BusinessDomain(
    id: 'social_security',
    tag: DataBusinessTag.socialSecurity,
    table: 'social_security_data',
    subtitle: '社保、公积金管理',
    icon: Icons.health_and_safety_outlined,
    color: Color(0xFFEA6668),
    scope: '社保缴纳、公积金管理、用工合规',
    need: '社保缴纳记录、公积金明细、用工花名册',
  ),
  BusinessDomain(
    id: 'supply_chain',
    tag: DataBusinessTag.supplyChain,
    table: 'supply_chain_data',
    subtitle: '上下游协同与风险监测',
    icon: Icons.local_shipping_outlined,
    color: Color(0xFFF59E0B),
    scope: '采购管理、供应商评估、物流库存、订单履约',
    need: '采购订单、供应商名录、库存报表、物流单据',
  ),
];

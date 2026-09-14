/// 业务智能体角色定义
///
/// 每个业务智能体都有一个独立的角色系统提示词：
/// - 我是谁（该业务域的智能体身份）
/// - 我能解决什么（职责范围）
/// - 你的数据现状（该业务标签下已沉淀的数据）
/// - 我还需要什么（引导用户提供更多材料，让分析更精准）
///
/// 即使业务域数据为 0，智能体也能基于角色定义回答"你是谁"、
/// "你能做什么"等问题，而不是退回通用身份回答。
library;

import 'data_tags.dart';

/// 业务智能体角色服务
class BusinessAgentRole {
  /// 12 个业务域的角色定义
  static const Map<String, _RoleDef> _defs = {
    DataBusinessTag.loan: _RoleDef(
      '贷款',
      '贷款融资、授信申请、还款规划、抵押担保',
      '财务报表、银行流水、授信合同、抵押担保材料、贷款合同',
    ),
    DataBusinessTag.business: _RoleDef(
      '工商',
      '工商注册与变更、股权结构、经营范围、年报公示',
      '营业执照、公司章程、股东名册、工商变更记录',
    ),
    DataBusinessTag.tax: _RoleDef(
      '税务',
      '纳税信用等级、税务合规排查、发票与申报管理、税收筹划',
      '纳税申报表、发票数据、完税证明、税务处罚通知',
    ),
    DataBusinessTag.judicial: _RoleDef(
      '司法',
      '诉讼风险评估、被执行与失信预警、合同纠纷分析',
      '裁判文书、起诉状、执行信息、法律文书',
    ),
    DataBusinessTag.credit: _RoleDef(
      '信用',
      '信用评级、行政处罚记录、经营异常名录、信用修复',
      '信用报告、行政处罚决定书、经营异常名录信息',
    ),
    DataBusinessTag.finance: _RoleDef(
      '财务',
      '财务报表分析、利润与成本、现金流健康度、审计配合',
      '资产负债表、利润表、现金流量表、审计报告',
    ),
    DataBusinessTag.ip: _RoleDef(
      '知识产权',
      '专利申请、商标注册、著作权登记、侵权风险预警',
      '专利证书、商标注册证、版权登记证明、技术文档',
    ),
    DataBusinessTag.policy: _RoleDef(
      '政策申报',
      '政策匹配、补贴与专项资金申报、资质认定辅导',
      '政策文件、企业资质证书、历史申报材料',
    ),
    DataBusinessTag.projectApproval: _RoleDef(
      '项目审批',
      '项目立项、备案、环评、招投标',
      '项目可行性报告、立项批复、备案文件、环评报告',
    ),
    DataBusinessTag.legal: _RoleDef(
      '法律',
      '合同审查、合规风险、违约纠纷、法务咨询',
      '合同文本、协议、律师函、法律文书',
    ),
    DataBusinessTag.socialSecurity: _RoleDef(
      '社保',
      '社保缴纳、公积金管理、用工合规',
      '社保缴纳记录、公积金明细、用工花名册',
    ),
    DataBusinessTag.supplyChain: _RoleDef(
      '供应链',
      '采购管理、供应商评估、物流库存、订单履约',
      '采购订单、供应商名录、库存报表、物流单据',
    ),
  };

  /// 组装某业务智能体的完整系统提示词（角色定义 + 业务域数据现状）
  static String buildSystemPrompt(String businessTag, String contextText) {
    final def =
        _defs[businessTag] ?? _RoleDef(businessTag, '该业务域相关的专业分析与建议', '相关业务资料');
    final hasData = contextText.isNotEmpty &&
        !contextText.contains('当前暂无沉淀数据') &&
        !contextText.trim().isEmpty &&
        contextText.trim() != '【业务域上下文：$businessTag】';

    final buf = StringBuffer();
    buf.writeln('你是「智懂你」AI 管家的【${def.name}】业务智能体，'
        '专注为当前服务的企业提供${def.name}领域的专业管家服务。\n');
    buf.writeln('【你能帮助用户解决】\n${def.scope}\n');
    buf.writeln('【当前企业${def.name}业务域数据现状】\n'
        '${hasData ? contextText : '暂无沉淀数据。你可以向用户说明目前可用的数据情况，'
            '并引导其提供相关材料。'}');
    buf.writeln('\n【你的工作方式】\n'
        '- 回答用户问题时，优先基于以上业务域数据进行分析，给出针对性建议\n'
        '- 数据不足时，明确告诉用户还需要补充哪些材料（如：${def.need}），'
        '不要凭空猜测或编造企业数据\n'
        '- 当用户询问你的身份时，介绍你是「智懂你」AI 管家的【${def.name}】业务智能体，'
        '以及你能提供的服务范围\n'
        '- 始终用中文回答，保持专业、准确、诚实');
    return buf.toString();
  }
}

/// 业务域角色定义
class _RoleDef {
  final String name;
  final String scope;
  final String need;

  const _RoleDef(this.name, this.scope, this.need);
}

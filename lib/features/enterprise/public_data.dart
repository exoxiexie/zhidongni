/// 企业信息公开数据（税务、司法、信用）
///
/// 三张结构化数据表，以统一社会信用代码为主键隔离企业主体。
/// 当前为模拟数据，将来接入企查查/天眼查/政务公开 API 后，
/// 以信用代码为 key 直接覆盖替换为真实数据，注入逻辑无需改动。
library;

// ────────────────────────────────────────────────────────────
//  税务信息表
// ────────────────────────────────────────────────────────────

/// 涉税处罚记录
class TaxPenalty {
  final String date; // 处罚日期
  final String reason; // 处罚事由
  final double amount; // 罚款金额（万元）
  final String authority; // 处罚机关

  const TaxPenalty({
    required this.date,
    required this.reason,
    required this.amount,
    required this.authority,
  });
}

/// 企业税务信息
class TaxInfo {
  final String creditCode; // 统一社会信用代码（主键）
  final String taxRating; // 纳税等级（A/B/C/D/M）
  final double annualTaxAmount; // 年纳税额（万元）
  final double owedTax; // 欠税金额（万元）
  final int taxPenaltyCount; // 涉税处罚次数
  final List<TaxPenalty> taxPenalties; // 处罚记录
  final bool isTaxAbnormal; // 是否非正常户

  const TaxInfo({
    required this.creditCode,
    required this.taxRating,
    required this.annualTaxAmount,
    required this.owedTax,
    required this.taxPenaltyCount,
    required this.taxPenalties,
    required this.isTaxAbnormal,
  });
}

// ────────────────────────────────────────────────────────────
//  司法信息表
// ────────────────────────────────────────────────────────────

/// 司法案件记录
class JudicialCase {
  final String caseNo; // 案号
  final String cause; // 案由
  final String role; // 角色（原告/被告/第三人）
  final double amount; // 涉案金额（万元）
  final String status; // 案件状态（审理中/已判决/已执行/已结案）
  final String result; // 判决结果（胜诉/败诉/部分胜诉/调解）

  const JudicialCase({
    required this.caseNo,
    required this.cause,
    required this.role,
    required this.amount,
    required this.status,
    required this.result,
  });
}

/// 企业司法信息
class JudicialInfo {
  final String creditCode; // 统一社会信用代码（主键）
  final int lawsuitCount; // 涉诉总数
  final int asDefendantCount; // 作为被告案件数
  final int asPlaintiffCount; // 作为原告案件数
  final List<JudicialCase> cases; // 案件列表
  final int enforcementCount; // 执行案件数
  final double enforcementAmount; // 执行标的总额（万元）
  final bool isDishonest; // 是否失信被执行人
  final double dishonestAmount; // 失信金额（万元）

  const JudicialInfo({
    required this.creditCode,
    required this.lawsuitCount,
    required this.asDefendantCount,
    required this.asPlaintiffCount,
    required this.cases,
    required this.enforcementCount,
    required this.enforcementAmount,
    required this.isDishonest,
    required this.dishonestAmount,
  });
}

// ────────────────────────────────────────────────────────────
//  信用信息表
// ────────────────────────────────────────────────────────────

/// 行政处罚记录
class AdministrativePenalty {
  final String date; // 处罚日期
  final String authority; // 处罚机关
  final String reason; // 处罚事由
  final double amount; // 罚款金额（万元）
  final String penaltyType; // 处罚类型（罚款/警告/责令改正/吊销执照）

  const AdministrativePenalty({
    required this.date,
    required this.authority,
    required this.reason,
    required this.amount,
    required this.penaltyType,
  });
}

/// 企业信用信息
class CreditInfo {
  final String creditCode; // 统一社会信用代码（主键）
  final String creditRating; // 信用评级（AAA/AA/A/BBB/BB/B/CCC）
  final int creditScore; // 信用分（0-100）
  final int administrativePenaltyCount; // 行政处罚次数
  final List<AdministrativePenalty> administrativePenalties; // 处罚记录
  final bool isBusinessAbnormal; // 是否经营异常
  final String abnormalReason; // 异常原因
  final bool isSeriousIllegal; // 是否严重违法失信

  const CreditInfo({
    required this.creditCode,
    required this.creditRating,
    required this.creditScore,
    required this.administrativePenaltyCount,
    required this.administrativePenalties,
    required this.isBusinessAbnormal,
    required this.abnormalReason,
    required this.isSeriousIllegal,
  });
}

// ────────────────────────────────────────────────────────────
//  模拟数据（以信用代码为 key，将来 API 接入直接覆盖）
// ────────────────────────────────────────────────────────────

/// 税务信息模拟数据
const Map<String, TaxInfo> kTaxData = {
  // 成都风腾伟业科技有限公司 — 科技公司，纳税信用良好
  '91510100MA6CQ6X150': TaxInfo(
    creditCode: '91510100MA6CQ6X150',
    taxRating: 'A',
    annualTaxAmount: 18.5,
    owedTax: 0,
    taxPenaltyCount: 0,
    taxPenalties: [],
    isTaxAbnormal: false,
  ),
  // 西部铭仁（四川）供应链管理有限公司 — 供应链公司，规模中等
  '91510100MA6444A75C': TaxInfo(
    creditCode: '91510100MA6444A75C',
    taxRating: 'B',
    annualTaxAmount: 86.2,
    owedTax: 0,
    taxPenaltyCount: 1,
    taxPenalties: [
      TaxPenalty(
        date: '2024-03-15',
        reason: '增值税申报逾期',
        amount: 0.2,
        authority: '国家税务总局成都市武侯区税务局',
      ),
    ],
    isTaxAbnormal: false,
  ),
  // 西部铭仁（四川）能源集团有限公司 — 新成立企业
  '91510100MAEGM9HXXD': TaxInfo(
    creditCode: '91510100MAEGM9HXXD',
    taxRating: 'M',
    annualTaxAmount: 0,
    owedTax: 0,
    taxPenaltyCount: 0,
    taxPenalties: [],
    isTaxAbnormal: false,
  ),
  // 开始送（成都）科技有限公司 — 小规模，纳税等级较低
  '91510100MA64PWHX35': TaxInfo(
    creditCode: '91510100MA64PWHX35',
    taxRating: 'C',
    annualTaxAmount: 2.1,
    owedTax: 0.8,
    taxPenaltyCount: 2,
    taxPenalties: [
      TaxPenalty(
        date: '2023-08-20',
        reason: '未按规定期限办理纳税申报',
        amount: 0.05,
        authority: '国家税务总局成都市双流区税务局',
      ),
      TaxPenalty(
        date: '2024-11-10',
        reason: '发票开具不规范',
        amount: 0.1,
        authority: '国家税务总局成都市双流区税务局',
      ),
    ],
    isTaxAbnormal: false,
  ),
};

/// 司法信息模拟数据
const Map<String, JudicialInfo> kJudicialData = {
  // 成都风腾伟业 — 无司法风险
  '91510100MA6CQ6X150': JudicialInfo(
    creditCode: '91510100MA6CQ6X150',
    lawsuitCount: 0,
    asDefendantCount: 0,
    asPlaintiffCount: 0,
    cases: [],
    enforcementCount: 0,
    enforcementAmount: 0,
    isDishonest: false,
    dishonestAmount: 0,
  ),
  // 西部铭仁供应链 — 有少量合同纠纷
  '91510100MA6444A75C': JudicialInfo(
    creditCode: '91510100MA6444A75C',
    lawsuitCount: 3,
    asDefendantCount: 1,
    asPlaintiffCount: 2,
    cases: [
      JudicialCase(
        caseNo: '(2024)川0107民初12345号',
        cause: '买卖合同纠纷',
        role: '原告',
        amount: 45.0,
        status: '已判决',
        result: '胜诉',
      ),
      JudicialCase(
        caseNo: '(2024)川0107民初23456号',
        cause: '运输合同纠纷',
        role: '被告',
        amount: 12.5,
        status: '已判决',
        result: '部分胜诉',
      ),
      JudicialCase(
        caseNo: '(2025)川0107民初34567号',
        cause: '仓储合同纠纷',
        role: '原告',
        amount: 28.0,
        status: '审理中',
        result: '待判决',
      ),
    ],
    enforcementCount: 1,
    enforcementAmount: 12.5,
    isDishonest: false,
    dishonestAmount: 0,
  ),
  // 西部铭仁能源 — 新成立，无司法记录
  '91510100MAEGM9HXXD': JudicialInfo(
    creditCode: '91510100MAEGM9HXXD',
    lawsuitCount: 0,
    asDefendantCount: 0,
    asPlaintiffCount: 0,
    cases: [],
    enforcementCount: 0,
    enforcementAmount: 0,
    isDishonest: false,
    dishonestAmount: 0,
  ),
  // 开始送科技 — 有少量劳动争议
  '91510100MA64PWHX35': JudicialInfo(
    creditCode: '91510100MA64PWHX35',
    lawsuitCount: 2,
    asDefendantCount: 2,
    asPlaintiffCount: 0,
    cases: [
      JudicialCase(
        caseNo: '(2023)川0116民初45678号',
        cause: '劳动争议',
        role: '被告',
        amount: 3.2,
        status: '已判决',
        result: '败诉',
      ),
      JudicialCase(
        caseNo: '(2024)川0116民初56789号',
        cause: '服务合同纠纷',
        role: '被告',
        amount: 5.8,
        status: '已结案',
        result: '调解',
      ),
    ],
    enforcementCount: 1,
    enforcementAmount: 3.2,
    isDishonest: false,
    dishonestAmount: 0,
  ),
};

/// 信用信息模拟数据
const Map<String, CreditInfo> kCreditData = {
  // 成都风腾伟业 — 信用优秀
  '91510100MA6CQ6X150': CreditInfo(
    creditCode: '91510100MA6CQ6X150',
    creditRating: 'AAA',
    creditScore: 95,
    administrativePenaltyCount: 0,
    administrativePenalties: [],
    isBusinessAbnormal: false,
    abnormalReason: '',
    isSeriousIllegal: false,
  ),
  // 西部铭仁供应链 — 信用良好
  '91510100MA6444A75C': CreditInfo(
    creditCode: '91510100MA6444A75C',
    creditRating: 'AA',
    creditScore: 88,
    administrativePenaltyCount: 1,
    administrativePenalties: [
      AdministrativePenalty(
        date: '2024-06-20',
        authority: '成都市武侯区市场监督管理局',
        reason: '广告宣传内容不规范',
        amount: 1.0,
        penaltyType: '罚款',
      ),
    ],
    isBusinessAbnormal: false,
    abnormalReason: '',
    isSeriousIllegal: false,
  ),
  // 西部铭仁能源 — 新企业，信用A级
  '91510100MAEGM9HXXD': CreditInfo(
    creditCode: '91510100MAEGM9HXXD',
    creditRating: 'A',
    creditScore: 80,
    administrativePenaltyCount: 0,
    administrativePenalties: [],
    isBusinessAbnormal: false,
    abnormalReason: '',
    isSeriousIllegal: false,
  ),
  // 开始送科技 — 信用一般，有经营异常记录
  '91510100MA64PWHX35': CreditInfo(
    creditCode: '91510100MA64PWHX35',
    creditRating: 'BBB',
    creditScore: 68,
    administrativePenaltyCount: 2,
    administrativePenalties: [
      AdministrativePenalty(
        date: '2023-05-10',
        authority: '成都市双流区市场监督管理局',
        reason: '未按规定公示年度报告',
        amount: 0.3,
        penaltyType: '罚款',
      ),
      AdministrativePenalty(
        date: '2024-09-15',
        authority: '成都市双流区市场监督管理局',
        reason: '经营范围变更未及时办理变更登记',
        amount: 0.5,
        penaltyType: '罚款+责令改正',
      ),
    ],
    isBusinessAbnormal: true,
    abnormalReason: '通过登记的住所或经营场所无法联系（2024年10月列入，2025年1月已移出）',
    isSeriousIllegal: false,
  ),
};

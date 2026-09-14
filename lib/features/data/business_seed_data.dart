/// 业务域模拟数据（种子数据）
///
/// 4 家入库模拟企业 × 12 个业务域，各造一批结构化业务数据，
/// 数据按企业画像差异化：
/// - 成都风腾伟业：科技公司，经营好、无官司、信用好、有专利
/// - 西部铭仁供应链：供应链公司，经营中上、少量纠纷
/// - 西部铭仁能源：能源公司，有司法纠纷、税务欠缴、经营承压
/// - 开始送科技：初创公司，经营一般、有融资需求
///
/// 仅对 kEnterpriseSeedData 中的 4 家模拟企业生效（seedIfEmpty 时按信用代码匹配），
/// 将来接入真实 API 后由真实数据覆盖，模拟数据不影响真实企业。
library;

import '../data/business_domain.dart';
import '../data/data_tags.dart';
import '../storage/business_domain_store.dart';

/// 种子条目定义
class _SeedItem {
  final String domainId; // 业务域统一ID
  final String title;
  final String detail;
  final int weight; // 数据权重（0-100，>=60 自动进上下文）
  final String sourceTag; // 来源标签

  const _SeedItem(
      this.domainId, this.title, this.detail, this.weight, this.sourceTag);
}

/// 公开信息域：来源=信息公开
const String _sPublic = DataSourceTag.publicInfo;

/// 外接业务系统域：来源=外接应用
const String _sApp = DataSourceTag.externalApp;

/// 种子数据：信用代码 -> 条目列表
const Map<String, List<_SeedItem>> kBusinessSeedData = {
  // ──────────────────────────────
  // 成都风腾伟业科技有限公司（科技，经营良好）
  // ──────────────────────────────
  '91510100MA6CQ6X150': [
    // 贷款
    _SeedItem(
        'loan',
        '经营性贷款（500万）',
        '2026-03 从成都银行获得经营性贷款 500 万元，期限 3 年，利率 4.2%，已还 200 万元，抵押物为办公楼。',
        85,
        _sApp),
    _SeedItem('loan', '综合授信额度（1000万）',
        '2025-11 与招商银行签订综合授信协议，额度 1000 万元，已使用 300 万元，余额 700 万元。', 75, _sApp),
    // 工商
    _SeedItem('business', '注册资本变更（1000万→2000万）',
        '2024-05 注册资本由 1000 万元增至 2000 万元，实缴 1500 万元。', 70, _sPublic),
    _SeedItem('business', '股权结构',
        '股东：张伟持股 60%、李强持股 40%；法定代表人张伟；成立日期 2016-03-15。', 80, _sPublic),
    // 税务
    _SeedItem('tax', '纳税信用A级',
        '2025 年度纳税信用评级 A 级，年纳税额约 320 万元，增值税、企业所得税均按时申报缴纳，无欠税。', 90, _sPublic),
    _SeedItem('tax', '研发费用加计扣除', '2025 年度研发费用加计扣除申报额 480 万元，享受所得税优惠约 72 万元。',
        78, _sPublic),
    // 司法
    _SeedItem('judicial', '无重大涉诉', '近三年无重大诉讼记录，2023 年一起货款纠纷已调解结案，标的 12 万元。', 72,
        _sPublic),
    // 信用
    _SeedItem('credit', '信用评级AA', '信用评级 AA，信用分 92，无行政处罚、无经营异常、非失信被执行人。', 88,
        _sPublic),
    // 财务
    _SeedItem('finance', '2025年度财务概览',
        '营业收入 6800 万元，净利润 920 万元，毛利率 38%，资产负债率 42%，现金流健康。', 92, _sApp),
    _SeedItem(
        'finance', '应收账款', '应收账款余额 860 万元，账龄 90 天以内占 78%，坏账率低于 1%。', 74, _sApp),
    // 知识产权
    _SeedItem('ip', '发明专利（3项）', '已授权发明专利 3 项（智能物流调度、数据加密传输、边缘计算网关），另有 2 项实审中。',
        86, _sApp),
    _SeedItem('ip', '商标与软著', '注册商标 12 件（含核心品牌"风腾"），软件著作权 8 项。', 70, _sApp),
    // 政策申报
    _SeedItem('policy', '高新技术企业认定',
        '2026-04 通过高新技术企业认定（编号 GR2026-51-0042），享受 15% 所得税优惠。', 82, _sApp),
    _SeedItem(
        'policy', '研发补贴申报', '2025-12 申报成都市研发投入补贴，预计获补 30 万元，审批中。', 68, _sApp),
    // 项目审批
    _SeedItem('projectApproval', '智能仓储系统立项',
        '2025-12 立项"智能仓储管理系统"项目，总投资 600 万元，备案号 5101072501。', 76, _sApp),
    // 法律
    _SeedItem('legal', '框架采购合同', '与 3 家供应商签订年度框架采购合同，履约正常，无违约纠纷。', 65, _sApp),
    // 社保
    _SeedItem('socialSecurity', '社保缴纳（128人）', '在职员工 128 人，五险一金按月足额缴纳，无欠缴记录。',
        72, _sApp),
    // 供应链
    _SeedItem('supplyChain', '供应商管理', '合格供应商 35 家，核心电子元器件供应商 3 家（交货准时率 96%）。',
        78, _sApp),
  ],

  // ──────────────────────────────
  // 西部铭仁供应链有限公司（供应链，经营中上）
  // ──────────────────────────────
  '91510100MA6444A75C': [
    // 贷款
    _SeedItem('loan', '供应链融资（800万）',
        '2026-01 通过应收账款质押获得供应链融资 800 万元，期限 6 个月，利率 5.1%。', 82, _sApp),
    _SeedItem('loan', '银行承兑汇票', '2025-12 开立银行承兑汇票 300 万元，用于支付上游货款，到期日 2026-06。',
        70, _sApp),
    // 工商
    _SeedItem(
        'business',
        '企业基本信息',
        '成立日期 2023-03-08；股东：王铭 70%、西部铭仁集团 30%；法定代表人王铭；注册资本 5000 万元。',
        80,
        _sPublic),
    // 税务
    _SeedItem('tax', '纳税信用B级', '2025 年度纳税信用评级 B 级，年纳税额约 180 万元，无欠税，无涉税处罚。', 85,
        _sPublic),
    // 司法
    _SeedItem('judicial', '买卖合同纠纷（已结）',
        '2025-06 一起货物买卖合同纠纷，经法院调解结案，支付货款 45 万元，无被执行记录。', 68, _sPublic),
    // 信用
    _SeedItem('credit', '信用评级A', '信用评级 A，信用分 85，无行政处罚、无经营异常。', 84, _sPublic),
    // 财务
    _SeedItem('finance', '2025年度财务概览',
        '营业收入 1.2 亿元，净利润 480 万元，毛利率 12%（行业水平），资产负债率 58%。', 88, _sApp),
    _SeedItem(
        'finance', '应付账款', '应付账款余额 2100 万元，账期平均 45 天，与应收账期基本匹配。', 72, _sApp),
    // 知识产权
    _SeedItem('ip', '商标（4件）', '注册商标 4 件（含"铭仁物流"品牌），无专利。', 55, _sApp),
    // 政策申报
    _SeedItem('policy', '物流企业税收优惠', '2025-10 申报大宗商品仓储设施用地城镇土地使用税减半优惠，已获批。', 66,
        _sApp),
    // 项目审批
    _SeedItem('projectApproval', '成都分拨中心备案',
        '2025-08 "西南分拨中心"项目完成备案（备案号 5101072508），总投资 1200 万元。', 74, _sApp),
    // 法律
    _SeedItem('legal', '运输合同纠纷',
        '2025-04 一起运输货物损毁纠纷，赔偿 8 万元结案；年度承运合同 50+ 份履约正常。', 64, _sApp),
    // 社保
    _SeedItem(
        'socialSecurity', '社保缴纳（86人）', '在职员工 86 人，五险一金正常缴纳，无欠缴。', 70, _sApp),
    // 供应链
    _SeedItem('supplyChain', '承运商网络',
        '合作承运商 120 家，自有仓储 3 个（成都/重庆/贵阳），月度订单量约 2000 单，准时交付率 94%。', 90, _sApp),
    _SeedItem('supplyChain', '核心客户',
        '核心客户 5 家（含 2 家制造业、3 家商贸企业），年度框架合同覆盖率 70%。', 76, _sApp),
  ],

  // ──────────────────────────────
  // 西部铭仁能源有限公司（能源，有纠纷、经营承压）
  // ──────────────────────────────
  '91510100MAEGM9HXXD': [
    // 贷款
    _SeedItem('loan', '固定资产贷款（2000万）',
        '2024-12 固定资产贷款 2000 万元（设备采购），2026-06 起存在逾期风险，已展期申请中。', 86, _sApp),
    _SeedItem('loan', '融资租赁（1500万）',
        '2023-07 融资租赁 1500 万元（生产设备），已还 900 万元，剩余 600 万元。', 74, _sApp),
    // 工商
    _SeedItem(
        'business',
        '企业基本信息',
        '成立日期 2018-06-20；股东：陈铭 55%、西部铭仁集团 45%；法定代表人陈铭；注册资本 8000 万元。',
        80,
        _sPublic),
    // 税务
    _SeedItem(
        'tax',
        '纳税信用C级与欠税',
        '2024 年度纳税信用评级 C 级，欠税 86 万元（企业所得税），2025-03 因申报逾期被税务处罚一次（罚款 3 万元）。',
        92,
        _sPublic),
    _SeedItem('tax', '增值税留抵', '增值税留抵税额 45 万元，因欠税暂缓退税。', 70, _sPublic),
    // 司法
    _SeedItem('judicial', '被诉货款纠纷（2起）',
        '2025-09 被 2 家供应商起诉货款纠纷，合计标的 210 万元，一审进行中。', 90, _sPublic),
    _SeedItem('judicial', '被执行记录（1起）',
        '2025-05 一起执行案件，执行标的 320 万元，部分履行 120 万元，剩余 200 万元执行中。', 88, _sPublic),
    // 信用
    _SeedItem(
        'credit',
        '信用评级BBB与经营异常',
        '信用评级 BBB，信用分 62；2025-03 因年报未按期公示被列入经营异常名录（已移出）；行政处罚 1 次。',
        94,
        _sPublic),
    // 财务
    _SeedItem('finance', '2025年度财务概览',
        '营业收入 8500 万元，净利润 -230 万元（亏损），资产负债率 78%，现金流紧张。', 95, _sApp),
    _SeedItem('finance', '偿债压力', '短期借款 3500 万元，流动比率 0.9，偿债压力较大。', 84, _sApp),
    // 知识产权
    _SeedItem('ip', '实用新型（2项）', '实用新型专利 2 项（锅炉余热回收、烟气除尘装置），无发明专利。', 60, _sApp),
    // 政策申报
    _SeedItem('policy', '节能改造补贴未通过',
        '2024-11 申报成都市节能改造专项资金（120 万元），因申报材料不全未通过，2026 年可重新申报。', 64, _sApp),
    // 项目审批
    _SeedItem('projectApproval', '光伏电站项目环评',
        '2025-03 "厂房屋顶 3MW 分布式光伏电站"项目环评获批（环评批复文号成环审〔2025〕12 号）。', 78, _sApp),
    // 法律
    _SeedItem('legal', '设备采购合同纠纷', '2025-07 与设备供应商合同履行争议，对方索赔违约金 60 万元，诉讼中。',
        80, _sApp),
    // 社保
    _SeedItem('socialSecurity', '社保欠缴（2个月）',
        '在职员工 210 人，2026-07、08 两月社保存在欠缴，合计约 68 万元，已收到催缴通知。', 88, _sApp),
    // 供应链
    _SeedItem('supplyChain', '煤炭采购',
        '年采购煤炭约 25 万吨，主要供应商 4 家，2026 年采购合同执行率 65%（资金紧张压缩采购）。', 82, _sApp),
  ],

  // ──────────────────────────────
  // 开始送科技有限公司（初创，经营一般、有融资需求）
  // ──────────────────────────────
  '91510100MA64PWHX35': [
    // 贷款
    _SeedItem('loan', '创业担保贷款（申请中）', '2026-02 申请创业担保贷款 100 万元（政府贴息），资料已提交，审批中。',
        80, _sApp),
    _SeedItem(
        'loan', '日常经营周转', '2025-12 使用银行消费经营性贷款 30 万元，利率 5.8%，正常还款。', 68, _sApp),
    // 工商
    _SeedItem('business', '企业基本信息',
        '成立日期 2024-09-18；股东：赵磊 80%、王芳 20%；法定代表人赵磊；注册资本 100 万元。', 78, _sPublic),
    // 税务
    _SeedItem('tax', '纳税信用M级', '2025 年度纳税信用评级 M 级（新设立企业），年纳税额约 12 万元，申报正常。', 74,
        _sPublic),
    // 司法
    _SeedItem('judicial', '无涉诉记录', '成立以来无诉讼、无被执行记录。', 58, _sPublic),
    // 信用
    _SeedItem('credit', '信用评级A', '信用评级 A，信用分 88，无行政处罚、无经营异常。', 76, _sPublic),
    // 财务
    _SeedItem('finance', '2025年度财务概览',
        '营业收入 380 万元，净利润 45 万元，前期投入较大，预计 2026 年盈亏平衡。', 84, _sApp),
    // 知识产权
    _SeedItem('ip', '商标与软著', '注册商标 2 件，软件著作权 3 项（同城配送相关）。', 66, _sApp),
    // 政策申报
    _SeedItem('policy', '大学生创业补贴', '2026-01 申请大学生创业一次性补贴 1 万元及场地租金补贴，审核中。', 62,
        _sApp),
    // 项目审批
    _SeedItem('projectApproval', '同城配送App项目',
        '2025-11 "开始送"同城配送 App 项目立项，总投资 150 万元，已完成备案。', 72, _sApp),
    // 法律
    _SeedItem('legal', '办公租赁合同', '办公场所租赁合同（3 年），履约正常，无纠纷。', 56, _sApp),
    // 社保
    _SeedItem(
        'socialSecurity', '社保缴纳（15人）', '在职员工 15 人，社保正常缴纳，无欠缴。', 64, _sApp),
    // 供应链
    _SeedItem('supplyChain', '骑手与供应商', '合作骑手约 200 人，餐饮商家供应商 8 家，配送单量日均 800 单。',
        80, _sApp),
  ],
};

/// 业务域模拟数据种子服务
class BusinessSeedService {
  /// 首次写入：某租户（企业信用代码）各业务域表为空时，注入模拟数据。
  /// 仅对 4 家模拟企业生效；真实企业（未来 API 接入）不会写入模拟数据。
  static Future<void> seedIfEmpty(String tenantId) async {
    final seed = kBusinessSeedData[tenantId];
    if (seed == null) return; // 非模拟企业，不注入
    for (final domain in kBusinessDomains) {
      final count =
          await BusinessDomainStore.countByDomain(tenantId, domain.id);
      if (count > 0) continue; // 已有数据（用户可能增删过），不重复注入
      for (final item in seed) {
        if (item.domainId != domain.id) continue;
        await BusinessDomainStore.insert(
          tenantId,
          BusinessDomainRecord(
            id: 'seed_${domain.id}_${tenantId.hashCode.abs()}_${item.title.hashCode.abs()}',
            creditCode: tenantId,
            domainId: domain.id,
            title: item.title,
            detail: item.detail,
            weight: item.weight,
            source: '模拟数据',
            dataTags: DataTags()
              ..set(DataTagDimension.source, [item.sourceTag])
              ..set(DataTagDimension.business, [domain.tag]),
          ),
        );
      }
    }
  }
}

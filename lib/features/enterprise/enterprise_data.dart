/// 企业模拟数据（企查查插件快照，字段1:1对齐企查查返回）
///
/// 数据来源：qifuwang 项目 enterprises-data.json
/// TODO：接入企查查 API 后，改为实时检索
import 'enterprise_model.dart';

const List<Enterprise> kEnterpriseSeedData = [
  Enterprise(
    id: '91510100MA6CQ6X150',
    name: '成都风腾伟业科技有限公司',
    creditCode: '91510100MA6CQ6X150',
    legalPerson: '颜江',
    status: '存续（在营、开业、在册）',
    foundedAt: '2017-05-19',
    registeredCapital: '125万元',
    enterpriseType: '有限责任公司（自然人投资或控股）',
    industry: '基础软件开发',
    staffScale: '少于50人',
    region: '四川省成都市武侯区',
    address: '成都高新区益州大道北段366号1栋8层806号',
    businessScope:
        '一般项目：软件开发；人工智能应用软件开发；人工智能硬件销售；智能机器人的研发；技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；信息系统运行维护服务；信息系统集成服务；外卖递送服务；普通货物仓储服务（不含危险化学品等需许可审批的项目）。',
  ),
  Enterprise(
    id: '91510100MA6444A75C',
    name: '西部铭仁（四川）供应链管理有限公司',
    creditCode: '91510100MA6444A75C',
    legalPerson: '赵心心',
    status: '存续（在营、开业、在册）',
    foundedAt: '2019-04-01',
    registeredCapital: '2000万元',
    enterpriseType: '其他有限责任公司',
    industry: '供应链管理服务',
    staffScale: '少于50人',
    region: '四川省成都市武侯区',
    address: '中国（四川）自由贸易试验区成都高新区天府大道中段530号2栋33层3310号',
    businessScope:
        '一般项目：供应链管理服务；非金属矿及制品销售；金属矿石销售；机动车充电销售；农副产品销售；人工智能硬件销售；充电桩销售；储能技术服务；电动汽车充电基础设施运营；节能管理服务；合同能源管理；运行效能评估服务。',
  ),
  Enterprise(
    id: '91510100MAEGM9HXXD',
    name: '西部铭仁（四川）能源集团有限公司',
    creditCode: '91510100MAEGM9HXXD',
    legalPerson: '刘艳萍',
    status: '存续（在营、开业、在册）',
    foundedAt: '2025-04-03',
    registeredCapital: '1000万元',
    enterpriseType: '有限责任公司（非自然人投资或控股的法人独资）',
    industry: '其他组织管理服务',
    staffScale: '',
    region: '四川省成都市武侯区',
    address: '成都市武侯区长荣路66号1栋负一楼2276附122号',
    businessScope:
        '一般项目：新兴能源技术研发；发电技术服务；太阳能发电技术服务；技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；风力发电技术服务；储能技术服务；站用加氢及储氢设施销售；企业管理；企业管理咨询。',
  ),
  Enterprise(
    id: '91510100MA64PWHX35',
    name: '开始送（成都）科技有限公司',
    creditCode: '91510100MA64PWHX35',
    legalPerson: '王洪伟',
    status: '存续（在营、开业、在册）',
    foundedAt: '2021-05-08',
    registeredCapital: '10万元',
    enterpriseType: '有限责任公司（自然人投资或控股）',
    industry: '基础软件开发',
    staffScale: '',
    region: '四川省成都市双流区',
    address:
        '中国（四川）自由贸易试验区成都市天府新区兴隆街道湖畔路北段366号1栋3楼1号附OL-01-202104081',
    businessScope:
        '一般项目：软件开发；技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；信息系统集成服务；普通货物仓储服务（不含危险化学品等需许可审批的项目）；国内贸易代理；专业设计服务；票务代理服务；组织文化艺术交流活动。',
  ),
];

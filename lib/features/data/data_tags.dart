/// 统一数据标签体系
///
/// 每一条沉淀数据都挂载一套标签（DataTags），按"维度"组织：
/// - source（来源）：信息公开 / 对话记忆 / 本地私有 / 联网搜索 / 外接应用
/// - business（业务）：贷款 / 工商 / 税务 / 司法 / 信用 / 财务 / 知识产权 /
///   政策申报 / 项目审批 / 法律 / 社保 / 供应链
///
/// 维度可**持续扩展**：将来需要新的查询维度（如时间、人员、项目等），
/// 只需新增维度常量并给数据打对应标签，无需改动数据结构。
/// 标签体系在数据层维护，前台 UI 按需读取展示。
library;

import 'dart:convert';

/// 标签维度常量（可持续扩展）
class DataTagDimension {
  /// 数据来源维度
  static const String source = 'source';

  /// 业务维度
  static const String business = 'business';

  const DataTagDimension._();
}

/// 数据来源标签（五大类）
class DataSourceTag {
  static const String publicInfo = '信息公开';
  static const String chatMemory = '对话记忆';
  static const String localPrivate = '本地私有';
  static const String webSearch = '联网搜索';
  static const String externalApp = '外接应用';

  const DataSourceTag._();
}

/// 业务标签（对应业务智能体）
class DataBusinessTag {
  static const String loan = '贷款';
  static const String business = '工商';
  static const String tax = '税务';
  static const String judicial = '司法';
  static const String credit = '信用';
  static const String finance = '财务';
  static const String ip = '知识产权';
  static const String policy = '政策申报';
  static const String projectApproval = '项目审批';
  static const String legal = '法律';
  static const String socialSecurity = '社保';
  static const String supplyChain = '供应链';

  /// 全部 12 个业务域（有序，与业务智能体展示顺序一致）
  static const List<String> all = [
    loan,
    business,
    tax,
    judicial,
    credit,
    finance,
    ip,
    policy,
    projectApproval,
    legal,
    socialSecurity,
    supplyChain,
  ];

  /// 关键词规则表：业务域 -> 触发关键词（用于零成本自动打标）
  static const Map<String, List<String>> _keywordRules = {
    loan: ['贷款', '融资', '借款', '授信', '抵押', '担保', '银行', '还款', '信贷', '利息'],
    business: ['工商', '执照', '注册', '股权', '股东', '法人', '变更', '经营范围', '注册资本'],
    tax: ['税务', '纳税', '发票', '申报表', '完税', '增值税', '所得税', '税负', '税率'],
    judicial: ['诉讼', '起诉', '判决', '法院', '案件', '被执行', '开庭', '仲裁', '庭审'],
    credit: ['信用', '征信', '处罚', '异常', '失信', '黑名单', '评级', '信用分'],
    finance: ['财务', '报表', '利润', '营收', '成本', '现金流', '审计', '资产负债表', '应收账款'],
    ip: ['专利', '商标', '著作权', '版权', '知识产权', '软著', '发明', '外观设计'],
    policy: ['政策', '补贴', '申报', '扶持', '专项资金', '优惠', '资助', '奖励'],
    projectApproval: ['项目', '审批', '立项', '备案', '环评', '招标', '投标', '可研'],
    legal: ['合同', '协议', '法律', '合规', '条款', '违约', '律师', '法务', '赔偿'],
    socialSecurity: ['社保', '公积金', '五险', '养老', '医疗', '工伤', '失业', '生育'],
    supplyChain: ['供应链', '采购', '供应商', '物流', '库存', '订单', '发货', '入库', '仓储'],
  };

  /// 根据文本关键词匹配业务标签（零模型成本）。
  /// 命中多个业务域时全部返回（多对多）；匹配不到返回空。
  static List<String> matchFromText(String text) {
    if (text.isEmpty) return const [];
    final result = <String>[];
    _keywordRules.forEach((tag, keywords) {
      for (final kw in keywords) {
        if (text.contains(kw)) {
          result.add(tag);
          break;
        }
      }
    });
    return result;
  }

  const DataBusinessTag._();
}

/// 单条数据的标签容器：维度 -> 标签值列表
class DataTags {
  final Map<String, List<String>> _tags;

  DataTags([Map<String, List<String>>? tags]) : _tags = tags ?? {};

  /// 常量构造：直接传入 const 标签 Map（用于 const 数据定义，不可变）
  const DataTags.fromConst(Map<String, List<String>> tags) : _tags = tags;

  /// 是否没有任何标签
  bool get isEmpty => _tags.isEmpty;

  /// 是否包含某维度
  bool has(String dimension) => (_tags[dimension]?.isNotEmpty ?? false);

  /// 读取某维度的全部标签（不可变视图）
  List<String> of(String dimension) =>
      List.unmodifiable(_tags[dimension] ?? const []);

  /// 设置某维度标签（覆盖）
  void set(String dimension, List<String> values) {
    _tags[dimension] = List.of(values);
  }

  /// 向某维度添加一个标签（去重）
  void add(String dimension, String value) {
    final list = _tags.putIfAbsent(dimension, () => []);
    if (!list.contains(value)) list.add(value);
  }

  /// 序列化为 Map（用于 JSON / YAML / SQLite 列）
  Map<String, dynamic> toMap() =>
      _tags.map((k, v) => MapEntry(k, List<String>.of(v)));

  /// 从 Map 反序列化
  factory DataTags.fromMap(Map<String, dynamic>? map) {
    final tags = DataTags();
    if (map == null) return tags;
    map.forEach((dim, vals) {
      if (vals is List) {
        tags.set(dim, vals.whereType<String>().toList());
      }
    });
    return tags;
  }

  /// 序列化为 JSON 字符串（存 YAML / SQLite 文本列）
  String toJsonString() => jsonEncode(toMap());

  /// 从 JSON 字符串反序列化（解析失败返回空标签）
  factory DataTags.fromJsonString(String? json) {
    if (json == null || json.isEmpty) return DataTags();
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        return DataTags.fromMap(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      // 标签损坏不影响数据读取
    }
    return DataTags();
  }
}

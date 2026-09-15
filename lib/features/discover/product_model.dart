/// B2B 商品模型
///
/// 统一商品模型，支持实物产品和服务产品：
/// - physical：实物商品（价格、起订量、规格、库存、发货地）
/// - service：服务商品（服务类型、报价方式、交付周期、服务范围）
library;

/// 商品类型
enum ProductType {
  /// 实物产品
  physical,

  /// 服务产品
  service,
}

/// B2B 商品
class Product {
  /// 商品ID
  final String id;

  /// 商品标题
  final String title;

  /// 商品描述
  final String description;

  /// 商品类型
  final ProductType type;

  /// 价格区间（最低价）
  final double priceMin;

  /// 价格区间（最高价）
  final double priceMax;

  /// 价格单位（如：元/个、元/吨、元/月）
  final String priceUnit;

  /// 起订量
  final String moq;

  /// 发货地/服务地
  final String location;

  /// 供应商名称
  final String supplierName;

  /// 供应商信用分（0-100）
  final int supplierRating;

  /// 是否认证商家
  final bool certified;

  /// 行业分类标签（用于推荐匹配）
  final List<String> industryTags;

  /// 关键词标签（用于搜索和推荐）
  final List<String> keywords;

  /// 成交数
  final int dealCount;

  /// 上架时间戳
  final int listedAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priceMin,
    required this.priceMax,
    required this.priceUnit,
    required this.moq,
    required this.location,
    required this.supplierName,
    required this.supplierRating,
    required this.certified,
    required this.industryTags,
    required this.keywords,
    required this.dealCount,
    required this.listedAt,
  });

  /// 价格显示文本
  String get priceText {
    if (priceMin == priceMax) {
      return '¥${priceMin.toStringAsFixed(priceMin < 10 ? 2 : 0)}$priceUnit';
    }
    return '¥${priceMin.toStringAsFixed(0)}-${priceMax.toStringAsFixed(0)}$priceUnit';
  }
}

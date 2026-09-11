/// 企业主体数据模型
///
/// 字段对齐企查查返回结构，用于企业主体登录注册和数据库页面展示。
class Enterprise {
  /// 统一社会信用代码（主键）
  final String id;

  /// 企业名称
  final String name;

  /// 统一社会信用代码
  final String creditCode;

  /// 法定代表人
  final String legalPerson;

  /// 经营状态
  final String status;

  /// 成立日期
  final String foundedAt;

  /// 注册资本
  final String registeredCapital;

  /// 企业类型
  final String enterpriseType;

  /// 行业
  final String industry;

  /// 人员规模
  final String staffScale;

  /// 所在区域
  final String region;

  /// 注册地址
  final String address;

  /// 经营范围
  final String businessScope;

  const Enterprise({
    required this.id,
    required this.name,
    required this.creditCode,
    required this.legalPerson,
    required this.status,
    required this.foundedAt,
    required this.registeredCapital,
    required this.enterpriseType,
    this.industry = '',
    this.staffScale = '',
    required this.region,
    required this.address,
    required this.businessScope,
  });

  /// 从 JSON 构造
  factory Enterprise.fromJson(Map<String, dynamic> json) {
    final reg = json['registration'] as Map<String, dynamic>? ?? {};
    return Enterprise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      creditCode: json['credit_code'] as String? ?? '',
      legalPerson: reg['legal_person'] as String? ?? '',
      status: reg['status'] as String? ?? '',
      foundedAt: reg['founded_at'] as String? ?? '',
      registeredCapital: reg['registered_capital'] as String? ?? '',
      enterpriseType: reg['enterprise_type'] as String? ?? '',
      industry: reg['industry'] as String? ?? '',
      staffScale: reg['staff_scale'] as String? ?? '',
      region: reg['region'] as String? ?? '',
      address: reg['address'] as String? ?? '',
      businessScope: reg['business_scope'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'credit_code': creditCode,
        'registration': {
          'legal_person': legalPerson,
          'status': status,
          'founded_at': foundedAt,
          'registered_capital': registeredCapital,
          'enterprise_type': enterpriseType,
          'industry': industry,
          'staff_scale': staffScale,
          'region': region,
          'address': address,
          'business_scope': businessScope,
        },
      };
}

/// 企业登录态
class EnterpriseAuth {
  final String token;
  final String enterpriseName;
  final String enterpriseId;
  final String phone;
  final String userName;

  const EnterpriseAuth({
    required this.token,
    required this.enterpriseName,
    required this.enterpriseId,
    required this.phone,
    required this.userName,
  });

  factory EnterpriseAuth.fromJson(Map<String, dynamic> json) => EnterpriseAuth(
        token: json['token'] as String? ?? '',
        enterpriseName: json['enterpriseName'] as String? ?? '',
        enterpriseId: json['enterpriseId'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'enterpriseName': enterpriseName,
        'enterpriseId': enterpriseId,
        'phone': phone,
        'userName': userName,
      };
}

/// 企业注册用户记录
class EnterpriseUser {
  final String phone;
  final String password;
  final String enterpriseName;
  final String enterpriseId;
  final String userName;
  final String createdAt;

  const EnterpriseUser({
    required this.phone,
    required this.password,
    required this.enterpriseName,
    required this.enterpriseId,
    required this.userName,
    required this.createdAt,
  });

  factory EnterpriseUser.fromJson(Map<String, dynamic> json) => EnterpriseUser(
        phone: json['phone'] as String? ?? '',
        password: json['password'] as String? ?? '',
        enterpriseName: json['enterpriseName'] as String? ?? '',
        enterpriseId: json['enterpriseId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
        'enterpriseName': enterpriseName,
        'enterpriseId': enterpriseId,
        'userName': userName,
        'createdAt': createdAt,
      };
}

/// 企业认证服务（支持多管理员）
///
/// - SharedPreferences 存储用户列表（模拟数据库）
/// - 注册企业：第一个人 role=owner（超级管理员）
/// - owner 可创建子管理员（admin），同一企业共享数据
/// - 子管理员凭手机号+密码登录，进入同一企业
/// - 子管理员有 disabledDomains 权限控制（业务域可见性）
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'enterprise_model.dart';

class EnterpriseAuthService {
  static const String _usersKey = 'zhidongni.enterprise.users';
  static const String _authKey = 'zhidongni.enterprise.auth';

  /// 获取所有注册用户
  static Future<List<EnterpriseUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EnterpriseUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存用户列表
  static Future<void> _saveUsers(List<EnterpriseUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  /// 注册企业（第一个人，role=owner）
  static Future<Map<String, dynamic>> registerUser(EnterpriseUser user) async {
    final users = await getUsers();
    if (users.any((u) => u.phone == user.phone)) {
      return {'ok': false, 'error': '该手机号已注册'};
    }
    users.add(user);
    await _saveUsers(users);
    return {'ok': true};
  }

  /// 登录校验
  static Future<Map<String, dynamic>> loginUser(
      String phone, String password) async {
    final users = await getUsers();
    final found = users.where((u) => u.phone == phone).toList();
    if (found.isEmpty) {
      return {'ok': false, 'error': '手机号未注册，请先注册'};
    }
    if (found.first.password != password) {
      return {'ok': false, 'error': '手机号或密码错误'};
    }
    return {'ok': true, 'user': found.first};
  }

  /// 设置登录态
  static Future<void> setAuth(EnterpriseAuth auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode(auth.toJson()));
  }

  /// 获取当前登录态
  static Future<EnterpriseAuth?> getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return EnterpriseAuth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 退出登录
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
  }

  // ===== 多管理员管理（仅 owner 调用） =====

  /// 获取同一企业下的所有管理员（含 owner 自己和子管理员）
  static Future<List<EnterpriseUser>> listAdmins(String enterpriseId) async {
    final users = await getUsers();
    return users.where((u) => u.enterpriseId == enterpriseId).toList();
  }

  /// owner 创建子管理员
  static Future<Map<String, dynamic>> createAdmin({
    required String ownerPhone,
    required String phone,
    required String password,
    required String name,
  }) async {
    final users = await getUsers();
    final owner = users.where((u) => u.phone == ownerPhone).toList();
    if (owner.isEmpty || owner.first.role != 'owner') {
      return {'ok': false, 'error': '无权限：仅超级管理员可创建管理员'};
    }
    if (users.any((u) => u.phone == phone)) {
      return {'ok': false, 'error': '该手机号已被注册'};
    }
    if (phone.length != 11) {
      return {'ok': false, 'error': '请输入正确的手机号'};
    }
    if (password.length < 6) {
      return {'ok': false, 'error': '密码至少6位'};
    }

    final admin = EnterpriseUser(
      phone: phone,
      password: password,
      enterpriseName: owner.first.enterpriseName,
      enterpriseId: owner.first.enterpriseId,
      userName: name,
      createdAt: DateTime.now().toIso8601String(),
      role: 'admin',
      disabledDomains: const [], // 默认全部可见
    );
    users.add(admin);
    await _saveUsers(users);
    return {'ok': true, 'admin': admin};
  }

  /// owner 删除子管理员
  static Future<Map<String, dynamic>> deleteAdmin({
    required String ownerPhone,
    required String adminPhone,
  }) async {
    final users = await getUsers();
    final owner = users.where((u) => u.phone == ownerPhone).toList();
    if (owner.isEmpty || owner.first.role != 'owner') {
      return {'ok': false, 'error': '无权限'};
    }
    if (adminPhone == ownerPhone) {
      return {'ok': false, 'error': '不能删除超级管理员自己'};
    }
    final before = users.length;
    users.removeWhere((u) =>
        u.enterpriseId == owner.first.enterpriseId && u.phone == adminPhone);
    if (users.length == before) {
      return {'ok': false, 'error': '未找到该管理员'};
    }
    await _saveUsers(users);
    return {'ok': true};
  }

  /// owner 修改子管理员（姓名/密码/权限开关）
  static Future<Map<String, dynamic>> updateAdmin({
    required String ownerPhone,
    required String adminPhone,
    String? newName,
    String? newPassword,
    List<String>? disabledDomains,
  }) async {
    final users = await getUsers();
    final owner = users.where((u) => u.phone == ownerPhone).toList();
    if (owner.isEmpty || owner.first.role != 'owner') {
      return {'ok': false, 'error': '无权限'};
    }
    final idx = users.indexWhere((u) =>
        u.enterpriseId == owner.first.enterpriseId && u.phone == adminPhone);
    if (idx < 0) {
      return {'ok': false, 'error': '未找到该管理员'};
    }
    final old = users[idx];
    users[idx] = EnterpriseUser(
      phone: old.phone,
      password: newPassword ?? old.password,
      enterpriseName: old.enterpriseName,
      enterpriseId: old.enterpriseId,
      userName: newName ?? old.userName,
      createdAt: old.createdAt,
      role: old.role,
      disabledDomains: disabledDomains ?? old.disabledDomains,
    );
    await _saveUsers(users);
    return {'ok': true, 'admin': users[idx]};
  }
}

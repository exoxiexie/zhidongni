/// 企业认证服务
///
/// 对齐 qifuwang auth.ts + mock-users.ts 逻辑：
/// - SharedPreferences 存储用户列表（模拟数据库）
/// - SharedPreferences 存储登录态
/// - 注册：保存用户（重复手机号拒绝）
/// - 登录：校验手机号+密码
/// - 退出：清除登录态
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

  /// 注册企业用户
  /// 返回 {ok: bool, error?: String}
  static Future<Map<String, dynamic>> registerUser(EnterpriseUser user) async {
    final users = await getUsers();
    if (users.any((u) => u.phone == user.phone)) {
      return {'ok': false, 'error': '该手机号已注册'};
    }
    users.add(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
    return {'ok': true};
  }

  /// 登录校验
  /// 返回 {ok: bool, user?: EnterpriseUser, error?: String}
  static Future<Map<String, dynamic>> loginUser(String phone, String password) async {
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
}

/// 企业认证服务 · 单元测试（验证 EnterpriseAuthService 契约行为）
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zhidongni/features/enterprise/enterprise_auth_service.dart';
import 'package:zhidongni/features/enterprise/enterprise_model.dart';

EnterpriseUser _buildUser({
  String phone = '13800000000',
  String password = 'abc123',
}) =>
    EnterpriseUser(
      phone: phone,
      password: password,
      enterpriseName: '测试企业',
      enterpriseId: 'test_ent_001',
      userName: '测试用户',
      createdAt: '2026-09-10T00:00:00',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('注册 → 登录 → 登出 完整流程', () async {
    SharedPreferences.setMockInitialValues({});

    // 注册成功
    final r = await EnterpriseAuthService.registerUser(_buildUser());
    expect(r['ok'], true);

    // 重复注册失败
    final r2 = await EnterpriseAuthService.registerUser(_buildUser());
    expect(r2['ok'], false);

    // 登录成功
    final l = await EnterpriseAuthService.loginUser('13800000000', 'abc123');
    expect(l['ok'], true);
    expect((l['user'] as EnterpriseUser).phone, '13800000000');

    // 设置登录态
    await EnterpriseAuthService.setAuth(EnterpriseAuth(
      token: 'token_123',
      enterpriseName: '测试企业',
      enterpriseId: 'test_ent_001',
      phone: '13800000000',
      userName: '测试用户',
    ));
    expect(await EnterpriseAuthService.getAuth(), isNotNull);

    // 登出
    await EnterpriseAuthService.clearAuth();
    expect(await EnterpriseAuthService.getAuth(), isNull);
  });

  test('错误密码登录失败', () async {
    SharedPreferences.setMockInitialValues({});
    await EnterpriseAuthService.registerUser(_buildUser());
    final l = await EnterpriseAuthService.loginUser('13800000000', 'wrong');
    expect(l['ok'], false);
  });

  test('未注册手机号登录失败', () async {
    SharedPreferences.setMockInitialValues({});
    final l = await EnterpriseAuthService.loginUser('13999999999', 'abc123');
    expect(l['ok'], false);
  });

  test('getUsers 返回已注册用户列表', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await EnterpriseAuthService.getUsers(), isEmpty);

    await EnterpriseAuthService.registerUser(_buildUser(phone: '13800000001'));
    await EnterpriseAuthService.registerUser(_buildUser(phone: '13800000002'));

    final users = await EnterpriseAuthService.getUsers();
    expect(users.length, 2);
    expect(users.map((u) => u.phone).toSet(),
        {'13800000001', '13800000002'});
  });
}

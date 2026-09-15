/// 管理员管理页（仅超级管理员可见）
///
/// 功能：
/// - 查看本企业所有管理员列表
/// - 创建子管理员（手机号+密码+姓名）
/// - 编辑子管理员（姓名/密码/业务域权限开关）
/// - 删除子管理员
library;

import 'package:flutter/material.dart';

import '../data/business_domain.dart';
import 'enterprise_auth_service.dart';
import 'enterprise_model.dart';

class AdminManagementPage extends StatefulWidget {
  final String ownerPhone;
  final String enterpriseName;

  const AdminManagementPage({
    super.key,
    required this.ownerPhone,
    required this.enterpriseName,
  });

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  List<EnterpriseUser> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _loading = true);
    final admins = await EnterpriseAuthService.listAdmins(
        // 通过 owner 找到 enterpriseId
        (await EnterpriseAuthService.getAuth())?.enterpriseId ?? '');
    if (mounted) {
      setState(() {
        _admins = admins;
        _loading = false;
      });
    }
  }

  String _maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  /// 显示创建管理员对话框
  void _showCreateDialog() {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String error = '';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('创建管理员'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  hintText: '手机号',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: '姓名',
                  prefixIcon: Icon(Icons.person, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '密码（至少6位）',
                  prefixIcon: Icon(Icons.lock, size: 20),
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(error,
                    style: const TextStyle(color: Color(0xFFEA6668), fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final phone = phoneCtrl.text.trim();
                      final name = nameCtrl.text.trim();
                      final pwd = pwdCtrl.text;
                      if (phone.isEmpty || name.isEmpty || pwd.isEmpty) {
                        setDialog(() => error = '请填写完整信息');
                        return;
                      }
                      setDialog(() {
                        loading = true;
                        error = '';
                      });
                      final result = await EnterpriseAuthService.createAdmin(
                        ownerPhone: widget.ownerPhone,
                        phone: phone,
                        password: pwd,
                        name: name,
                      );
                      if (result['ok']) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadAdmins();
                      } else {
                        setDialog(() {
                          loading = false;
                          error = result['error'] ?? '创建失败';
                        });
                      }
                    },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示编辑管理员对话框（权限开关）
  void _showEditDialog(EnterpriseUser admin) {
    final nameCtrl = TextEditingController(text: admin.userName);
    final pwdCtrl = TextEditingController();
    final disabled = List<String>.from(admin.disabledDomains);
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('编辑 ${admin.userName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: '姓名',
                    prefixIcon: Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '重置密码（留空则不修改）',
                    prefixIcon: Icon(Icons.lock, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('业务域权限（关闭后该智能体不可见）',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ),
                const SizedBox(height: 8),
                // 权限开关列表
                ...kBusinessDomains.map((d) {
                  final isDisabled = disabled.contains(d.id);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.tag, style: const TextStyle(fontSize: 14)),
                    value: !isDisabled,
                    activeColor: const Color(0xFF5B7FD4),
                    onChanged: (v) {
                      setDialog(() {
                        if (v == true) {
                          disabled.remove(d.id);
                        } else {
                          disabled.add(d.id);
                        }
                      });
                    },
                  );
                }),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error,
                      style: const TextStyle(
                          color: Color(0xFFEA6668), fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final result = await EnterpriseAuthService.updateAdmin(
                  ownerPhone: widget.ownerPhone,
                  adminPhone: admin.phone,
                  newName: nameCtrl.text.trim(),
                  newPassword: pwdCtrl.text.isNotEmpty ? pwdCtrl.text : null,
                  disabledDomains: disabled,
                );
                if (result['ok']) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAdmins();
                } else {
                  setDialog(() => error = result['error'] ?? '保存失败');
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 删除管理员确认
  void _confirmDelete(EnterpriseUser admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除管理员'),
        content: Text('确定要删除 ${admin.userName}（${_maskPhone(admin.phone)}）吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final result = await EnterpriseAuthService.deleteAdmin(
                ownerPhone: widget.ownerPhone,
                adminPhone: admin.phone,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (result['ok']) {
                _loadAdmins();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['error'] ?? '删除失败')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Color(0xFFD05656))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员管理'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF5B7FD4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _admins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final admin = _admins[i];
                final isOwner = admin.role == 'owner';
                final disabledCount = admin.disabledDomains.length;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE4E3DD)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOwner
                          ? const Color(0xFF5B7FD4)
                          : const Color(0xFF10B981),
                      child: Text(
                        admin.userName.isNotEmpty
                            ? admin.userName[0]
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(admin.userName),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(0xFF5B7FD4).withOpacity(0.1)
                                : const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOwner ? '超级管理员' : '管理员',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOwner
                                  ? const Color(0xFF5B7FD4)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${_maskPhone(admin.phone)}'
                      '${disabledCount > 0 ? ' · 已禁用 $disabledCount 个业务域' : ' · 全部业务域可见'}',
                    ),
                    trailing: isOwner
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 20, color: Color(0xFF6B7280)),
                                onPressed: () => _showEditDialog(admin),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Color(0xFFD05656)),
                                onPressed: () => _confirmDelete(admin),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }
}

/// 我的 Tab · 企业信息 + 退出登录 + 检查更新
///
/// 铁律1：本页只通过 [EnterpriseAuthService] / [UpdateService] 契约执行动作，
/// 不接触存储 / 网络实现细节；具体实现由外部注入或默认装配。
library;

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../contracts/update_service.dart';
import '../enterprise/enterprise_auth_service.dart';
import '../enterprise/enterprise_login_page.dart';
import '../enterprise/enterprise_model.dart';
import '../update/update_service_impl.dart';

/// 更新服务器地址（多源：Gitee API 优先，GitHub 回退；均公网可访问）
/// Gitee 用 API 方式获取文件内容，避免 raw URL 302 重定向导致超时
const List<String> _kUpdateBaseUrls = [
  'https://gitee.com/api/v5/repos/laoxie2076/zhidongni/contents',
  'https://raw.githubusercontent.com/exoxiexie/zhidongni/main',
];

class ProfileTab extends StatefulWidget {
  final UpdateService? updateService;

  const ProfileTab({super.key, this.updateService});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<EnterpriseAuth?> _authFuture;
  bool _checking = false;
  bool _downloading = false;
  double _progress = 0;
  StateSetter? _setDialogState; // 用于更新下载进度对话框内部状态

  UpdateService get _updateSvc =>
      widget.updateService ?? HttpUpdateService(baseUrls: _kUpdateBaseUrls);

  @override
  void initState() {
    super.initState();
    _authFuture = EnterpriseAuthService.getAuth();
  }

  /// 手机号脱敏展示：138****1234
  String _maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  Future<void> _logout(BuildContext context) async {
    await EnterpriseAuthService.clearAuth();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EnterpriseLoginPage()),
      (route) => false,
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    if (_checking || _downloading) return;
    setState(() => _checking = true);

    CheckResult result;
    try {
      result = await _updateSvc.checkForUpdate();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
    if (!mounted) return;

    if (result.hasUpdate && result.latest != null) {
      final info = result.latest!;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('发现新版本'),
          content: Text(
              '最新版本：${info.version}\n\n更新内容：\n${info.note.isEmpty ? '暂无' : info.note}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('立即更新')),
          ],
        ),
      );
      if (proceed == true) {
        await _downloadAndInstall(context, info);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? '已是最新版本',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Future<void> _downloadAndInstall(BuildContext context, UpdateInfo info) async {
    setState(() => _downloading = true);
    BuildContext? dialogRebuild;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogRebuild = ctx;
        return AlertDialog(
          title: const Text('正在下载更新'),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) {
              _setDialogState = setDialogState; // 存起来，供 onProgress 回调使用
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_progress >= 0)
                    LinearProgressIndicator(value: _progress > 0 ? _progress / 100 : null)
                  else
                    const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  if (_progress >= 0)
                    Text('${_progress.toStringAsFixed(0)}%')
                  else
                    Text('已下载 ${(_progress.abs() / 1024 / 1024).toStringAsFixed(1)} MB'),
                ],
              );
            },
          ),
        );
      },
    );

    try {
      final path = await _updateSvc.download(
        info.url,
        onProgress: (p) {
          // 用 setDialogState 更新对话框内部 UI（setState 不会触发 StatefulBuilder 重建）
          _setDialogState?.call(() {
            if (p >= 0) {
              _progress = p * 100; // 已知总大小：百分比
            } else {
              _progress = p; // 未知总大小：已下载字节数（负数标识）
            }
          });
        },
      );
      if (dialogRebuild != null && dialogRebuild!.mounted) {
        Navigator.of(dialogRebuild!).pop();
      }
      if (!mounted) return;
      setState(() => _downloading = false);

      final r = await OpenFilex.open(path);
      final ok = r.type == ResultType.done;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '下载完成，请在系统安装界面确认安装' : '下载完成，但打开安装器失败（${r.message}）'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      if (dialogRebuild != null && dialogRebuild!.mounted) {
        Navigator.of(dialogRebuild!).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // === 顶部：企业信息（企业图标 + 企业名称 + 管理员） ===
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B7FD4), Color(0xFF8CA8E8)],
              ),
            ),
            child: const Icon(Icons.business, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 14),
          FutureBuilder<EnterpriseAuth?>(
            future: _authFuture,
            builder: (context, snap) {
              final auth = snap.data;
              return Column(
                children: [
                  Text(
                    auth?.enterpriseName ?? '未登录',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (auth != null)
                    Text(
                      '管理员：${auth.userName} · ${_maskPhone(auth.phone)}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          // === 操作区：检查更新 + 退出登录 ===
          if (_checking)
            const CircularProgressIndicator()
          else
            OutlinedButton.icon(
              onPressed: () => _checkUpdate(context),
              icon: const Icon(Icons.system_update_alt),
              label: const Text('检查更新'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B7FD4),
                side: const BorderSide(color: Color(0xFF5B7FD4)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('退出登录'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD05656),
              side: const BorderSide(color: Color(0xFFD05656)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

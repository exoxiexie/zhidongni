/// 数据库 Tab · UniText 上下文宇宙的具象化展示
///
/// 顶部展示当前登录的企业主体信息，底部留空（后续放 UniText 数据）。
/// 未登录时显示登录/注册入口。
import 'package:flutter/material.dart';
import '../enterprise/enterprise_auth_service.dart';
import '../enterprise/enterprise_data.dart';
import '../enterprise/enterprise_login_page.dart';
import '../enterprise/enterprise_model.dart';
import '../memory/memory_edit_page.dart';
import '../storage/memory_store.dart';
import '../data/public_data_detail_page.dart';
import '../data/memory_detail_page.dart';

class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => DatabaseTabState();
}

class DatabaseTabState extends State<DatabaseTab> {
  EnterpriseAuth? _auth;
  Enterprise? _enterprise;
  bool _loading = true;
  List<MemoryItem> _memories = [];
  bool _loadingMemories = false;

  @override
  void initState() {
    super.initState();
    _loadAuth();
  }

  /// 加载记忆列表
  Future<void> _loadMemories() async {
    if (_enterprise?.creditCode.isEmpty == true) return;
    setState(() => _loadingMemories = true);
    try {
      final list = await MemoryStore.listAll(_enterprise!.creditCode);
      if (mounted) setState(() => _memories = list);
    } catch (e) {
      debugPrint('加载记忆失败: $e');
    } finally {
      if (mounted) setState(() => _loadingMemories = false);
    }
  }

  /// 供外部调用：重新加载记忆列表（切换到本页时刷新，让自动提炼立即可见）
  Future<void> refresh() async {
    await _loadMemories();
  }

  Future<void> _loadAuth() async {
    final auth = await EnterpriseAuthService.getAuth();
    Enterprise? ent;
    if (auth != null) {
      // 根据 enterpriseId 或 enterpriseName 查找企业完整信息
      ent = kEnterpriseSeedData.firstWhere(
        (e) => e.id == auth.enterpriseId || e.name == auth.enterpriseName,
        orElse: () => const Enterprise(
          id: '',
          name: '',
          creditCode: '',
          legalPerson: '',
          status: '',
          foundedAt: '',
          registeredCapital: '',
          enterpriseType: '',
          region: '',
          address: '',
          businessScope: '',
        ),
      );
      if (ent.id.isEmpty) ent = null;
    }
    if (mounted) {
      setState(() {
        _auth = auth;
        _enterprise = ent;
        _loading = false;
      });
      if (ent?.creditCode.isNotEmpty == true) {
        _loadMemories();
      }
    }
  }

  Future<void> _logout() async {
    await EnterpriseAuthService.clearAuth();
    await _loadAuth();
  }

  void _goLogin() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EnterpriseLoginPage()))
        .then((_) => _loadAuth());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMemories,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 顶部企业主体信息区
                _auth == null ? _buildNotLoggedIn() : _buildEnterpriseInfo(),
                // 五大类数据模块卡片
                if (_auth != null) _buildDataModules(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 政务数据专区：工商、税务、司法、信用
  Widget _buildGovernmentDataList() {
    final items = [
      _DataCategory(
        icon: Icons.business_outlined,
        color: const Color(0xFF2563EB),
        title: '工商数据',
        subtitle: '注册信息、股东、变更记录',
      ),
      _DataCategory(
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF059669),
        title: '税务数据',
        subtitle: '纳税等级、欠税、涉税处罚',
      ),
      _DataCategory(
        icon: Icons.gavel_outlined,
        color: const Color(0xFFDC2626),
        title: '司法数据',
        subtitle: '诉讼、执行、失信、裁判文书',
      ),
      _DataCategory(
        icon: Icons.verified_outlined,
        color: const Color(0xFF7C3AED),
        title: '信用数据',
        subtitle: '信用评级、行政处罚、经营异常',
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          () {
            final item = items[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1B1C),
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC0C4CC)),
              onTap: () => _openCategoryDetail(item),
            );
          }(),
          if (i < items.length - 1)
            const Divider(height: 1, indent: 72, endIndent: 16),
        ],
      ],
    );
  }

  /// 对话记忆专区
  Widget _buildMemorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 专区标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              const Text(
                '对话记忆',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1C),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_memories.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22, color: Color(0xFF6366F1)),
                onPressed: _openNewMemory,
              ),
            ],
          ),
        ),
        // 记忆列表
        if (_loadingMemories)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_memories.isEmpty)
          _buildMemoryEmpty()
        else
          ..._memories.map((m) => Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _weightColor(m.weight).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${m.weight}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _weightColor(m.weight),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1B1C),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.tags.isNotEmpty)
                          Text(
                            m.tags.take(3).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                        if (m.source == '会话提炼')
                          const Text(
                            'AI 自动提炼',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF6366F1)),
                          ),
                        Text(
                          _formatDate(m.updatedAt),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFC0C4CC)),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: Color(0xFFC0C4CC)),
                    onTap: () => _openMemoryDetail(m),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 20),
                ],
              )),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 记忆空状态
  Widget _buildMemoryEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            '还没有对话记忆',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击右上角 + 新建第一条记忆',
            style: TextStyle(fontSize: 12, color: Color(0xFFC0C4CC)),
          ),
        ],
      ),
    );
  }

  /// 权重颜色
  Color _weightColor(int weight) {
    if (weight >= 80) return const Color(0xFFDC2626);
    if (weight >= 60) return const Color(0xFFF59E0B);
    if (weight >= 40) return const Color(0xFF2563EB);
    return const Color(0xFF9CA3AF);
  }

  /// 打开新建记忆
  void _openNewMemory() {
    if (_enterprise?.creditCode.isEmpty == true) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => MemoryEditPage(tenantId: _enterprise!.creditCode),
        ))
        .then((saved) {
      if (saved == true) _loadMemories();
    });
  }

  /// 打开记忆详情
  void _openMemoryDetail(MemoryItem item) {
    if (_enterprise?.creditCode.isEmpty == true) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => MemoryEditPage(
            tenantId: _enterprise!.creditCode,
            memory: item,
          ),
        ))
        .then((saved) {
      if (saved == true) _loadMemories();
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 打开数据分类详情（占位页）
  void _openCategoryDetail(_DataCategory item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(item.title),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 48, color: item.color.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  '${item.title}功能开发中',
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                const Text(
                  '将接入企查查等专业数据库 API',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 未登录状态
  Widget _buildNotLoggedIn() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E3DD)),
      ),
      child: Column(
        children: [
          const Icon(Icons.business_outlined, size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          const Text(
            '尚未登录企业账号',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1B1C)),
          ),
          const SizedBox(height: 8),
          const Text(
            '登录后可管理企业 UniText 数据',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _goLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('登录 / 注册企业账号',
                  style: TextStyle(fontSize: 15, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// 已登录 - 企业主体信息卡片（主体名称 + 统一社会信用代码，作为身份标识）
  Widget _buildEnterpriseInfo() {
    final creditCode = _enterprise?.creditCode.isNotEmpty == true
        ? _enterprise!.creditCode
        : _auth!.enterpriseId;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 企业主体名称
          Text(
            _auth!.enterpriseName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          // 统一社会信用代码（主体身份标识）
          Text(
            '统一社会信用代码：$creditCode',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  /// 五大类数据模块卡片：信息公开、对话记忆、本地私有、联网搜索、外接应用
  Widget _buildDataModules() {
    final modules = [
      _DataModule(
        icon: Icons.business_outlined,
        color: const Color(0xFF2563EB),
        title: '信息公开数据',
        subtitle: '工商、税务、司法、信用等公开信息',
      ),
      _DataModule(
        icon: Icons.auto_stories_outlined,
        color: const Color(0xFF7C3AED),
        title: '对话记忆数据',
        subtitle: 'AI提炼、压缩、记忆三层沉淀',
        count: _memories.length,
      ),
      _DataModule(
        icon: Icons.folder_outlined,
        color: const Color(0xFF059669),
        title: '本地私有数据',
        subtitle: '手机、电脑、U盘、移动硬盘文件',
      ),
      _DataModule(
        icon: Icons.search_outlined,
        color: const Color(0xFFF59E0B),
        title: '联网搜索数据',
        subtitle: '行业动态、新闻、社交媒体',
      ),
      _DataModule(
        icon: Icons.extension_outlined,
        color: const Color(0xFF0891B2),
        title: '外接应用数据',
        subtitle: '第三方应用、API、数据源接入',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          for (var i = 0; i < modules.length; i++) ...[
            _buildModuleCard(modules[i]),
            if (i < modules.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// 单个数据模块卡片
  Widget _buildModuleCard(_DataModule module) {
    return GestureDetector(
      onTap: () => _openModuleDetail(module),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E3DD)),
        ),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: module.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(module.icon, size: 26, color: module.color),
            ),
            const SizedBox(width: 14),
            // 中间标题+描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        module.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1B1C),
                        ),
                      ),
                      if (module.count != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: module.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${module.count}',
                            style: TextStyle(
                              fontSize: 11,
                              color: module.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            // 右侧箭头
            const Icon(Icons.chevron_right, size: 22, color: Color(0xFFC0C4CC)),
          ],
        ),
      ),
    );
  }

  /// 打开数据模块详情页
  void _openModuleDetail(_DataModule module) {
    // 信息公开数据 → 进入5类数据大卡片详情页
    if (module.title == '信息公开数据') {
      final creditCode = _enterprise?.creditCode.isNotEmpty == true
          ? _enterprise!.creditCode
          : _auth?.enterpriseId ?? '';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicDataDetailPage(creditCode: creditCode),
        ),
      );
      return;
    }
    // 对话记忆数据 → 进入记忆列表页
    if (module.title == '对话记忆数据') {
      final creditCode = _enterprise?.creditCode.isNotEmpty == true
          ? _enterprise!.creditCode
          : _auth?.enterpriseId ?? '';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoryDetailPage(tenantId: creditCode),
        ),
      );
      return;
    }
    // 其他模块 → 占位页
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(module.title),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(module.icon, size: 56, color: module.color.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  '${module.title}功能开发中',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Text(
                  module.subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// 数据模块模型（五大类数据）
class _DataModule {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int? count;

  const _DataModule({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.count,
  });
}

/// 数据分类模型
class _DataCategory {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _DataCategory({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

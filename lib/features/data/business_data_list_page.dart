/// 业务数据列表页（数据页"按业务"视图点开）
///
/// 展示某业务域（如"税务"）下全部已沉淀数据：
/// 对话记忆 / 联网搜索 / 本地私有文件 / 信息公开，按来源分组排列。
library;

import 'package:flutter/material.dart';

import 'business_context_service.dart';
import 'data_tags.dart';

/// 业务数据列表页
class BusinessDataListPage extends StatefulWidget {
  final String tenantId;
  final String businessTag;

  const BusinessDataListPage({
    super.key,
    required this.tenantId,
    required this.businessTag,
  });

  @override
  State<BusinessDataListPage> createState() => _BusinessDataListPageState();
}

class _BusinessDataListPageState extends State<BusinessDataListPage> {
  List<BusinessDataEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await BusinessViewService.listByBusiness(
          widget.tenantId, widget.businessTag);
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      debugPrint('加载业务数据失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessTag),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        // 左上角：向左尖括号返回（与业务智能体页同款）
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Color(0xFF1B3A5C),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '返回',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) =>
                        _buildEntryCard(_entries[index], index),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.inbox_outlined,
          size: 48,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '该业务域暂无沉淀数据',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(BusinessDataEntry entry, int index) {
    final accent = _sourceStyle(entry.source);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E3DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 来源图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(accent.icon, size: 20, color: accent.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 来源徽标
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        entry.source,
                        style: TextStyle(
                          fontSize: 10,
                          color: accent.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (entry.weight != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '权重 ${entry.weight}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1B1C),
                  ),
                ),
                if (entry.detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280), height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 来源样式
  ({IconData icon, Color color}) _sourceStyle(String source) {
    switch (source) {
      case DataSourceTag.chatMemory:
        return (
          icon: Icons.auto_stories_outlined,
          color: const Color(0xFF7C3AED)
        );
      case DataSourceTag.webSearch:
        return (icon: Icons.search_outlined, color: const Color(0xFFF59E0B));
      case DataSourceTag.localPrivate:
        return (icon: Icons.folder_outlined, color: const Color(0xFF059669));
      case DataSourceTag.externalApp:
        return (icon: Icons.extension_outlined, color: const Color(0xFF0891B2));
      case DataSourceTag.publicInfo:
      default:
        return (icon: Icons.business_outlined, color: const Color(0xFF2563EB));
    }
  }
}

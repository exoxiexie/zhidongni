/// 发现 Tab · AI 驱动的 B2B 供应链交易平台
///
/// 顶部：AI 对话框（和通用对话页同款 ChatInputBar），贴顶离状态栏 4dp
/// 内容区：商品推荐流（基于企业行业千人千面）
/// 对话：AI 作为采购助手，同时充当搜索引擎
library;

import 'package:flutter/material.dart';

import '../../contracts/agent_service.dart';
import '../../contracts/chat_service.dart';
import '../chat/chat_input_bar.dart';
import '../enterprise/enterprise_auth_service.dart';
import '../enterprise/enterprise_data.dart';
import 'product_model.dart';
import 'product_detail_page.dart';
import 'product_seed_data.dart';

/// 发现页（B2B 供应链交易平台）
class DiscoverTab extends StatefulWidget {
  final ChatService? chatService;
  final AgentService? agentService;

  const DiscoverTab({super.key, this.chatService, this.agentService});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _currentIndustry = '';
  String _currentEnterpriseName = '';
  bool _isChatting = false;
  String? _chatReply;

  @override
  void initState() {
    super.initState();
    _loadEnterprise();
  }

  Future<void> _loadEnterprise() async {
    try {
      final auth = await EnterpriseAuthService.getAuth();
      if (auth != null) {
        for (final e in kEnterpriseSeedData) {
          if (e.creditCode == auth.enterpriseId ||
              e.name == auth.enterpriseName) {
            if (mounted) {
              setState(() {
                _currentIndustry = e.industry;
                _currentEnterpriseName = e.name;
              });
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  /// 规则式推荐：基于企业行业匹配商品
  List<Product> get _recommendedProducts {
    if (_currentIndustry.isEmpty) return kSeedProducts;

    final industry = _currentIndustry;
    final scored = kSeedProducts.map((p) {
      int score = 0;
      for (final tag in p.industryTags) {
        if (industry.contains(tag) || tag.contains(industry)) score += 10;
      }
      for (final kw in p.keywords) {
        if (industry.contains(kw)) score += 5;
      }
      score += p.supplierRating ~/ 10;
      return MapEntry(p, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 发送采购咨询给 AI（对话框即搜索引擎）
  Future<void> _sendPurchaseQuery() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isChatting || widget.chatService == null) return;

    _chatController.clear();
    setState(() {
      _isChatting = true;
      _chatReply = null;
    });

    try {
      final systemPrompt = '''
你是智懂你平台的 AI 采购助手。当前用户企业：$_currentEnterpriseName，所属行业：$_currentIndustry。

你的职责：
1. 帮用户在 B2B 供应链平台上找商品、找供应商
2. 根据用户需求推荐合适的产品和服务
3. 解释价格、起订量、交付等采购相关问题
4. 帮用户准备询盘话术

可用商品参考：
${kSeedProducts.map((p) => '- ${p.title}（${p.priceText}，起订${p.moq}，${p.location}）').join('\n')}

请用简洁专业的中文回答，给出具体建议。
''';

      final reply = await widget.chatService!.sendMessage(
        [ChatMessage(role: 'user', content: text)],
        systemExtra: systemPrompt,
      );

      if (mounted) {
        setState(() {
          _chatReply = reply;
          _isChatting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatReply = '查询失败：$e';
          _isChatting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _recommendedProducts;

    return Column(
      children: [
        // === 顶部 AI 对话框（贴顶 4dp） ===
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: ChatInputBar(
            controller: _chatController,
            isLoading: _isChatting,
            selectedModel: kChatModels[0],
            onSend: _sendPurchaseQuery,
            onAddAttachment: () {},
            onConnectComputer: () {},
            onSkillSelect: () {},
          ),
        ),

        // === AI 回复气泡 ===
        if (_chatReply != null) _buildChatReply(),

        // === 推荐标题 ===
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.recommend, size: 18, color: Color(0xFF5B7FD4)),
              const SizedBox(width: 6),
              const Text(
                '为你推荐',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1C),
                ),
              ),
              const Spacer(),
              Text(
                '${products.length} 个商品',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),

        // === 商品列表 ===
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text('未找到相关商品',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _ProductCard(
                    product: products[i],
                    onTap: () => _openProductDetail(products[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChatReply() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy, size: 16, color: Color(0xFF5B7FD4)),
              SizedBox(width: 6),
              Text('AI 采购助手',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B7FD4))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _chatReply!,
            style: const TextStyle(
                fontSize: 14, height: 1.5, color: Color(0xFF1A1B1C)),
          ),
        ],
      ),
    );
  }

  void _openProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          chatService: widget.chatService,
          enterpriseName: _currentEnterpriseName,
        ),
      ),
    );
  }
}

/// 商品卡片
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图标
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF5B7FD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                product.type == ProductType.physical
                    ? Icons.inventory_2_outlined
                    : Icons.handshake_outlined,
                size: 32,
                color: const Color(0xFF5B7FD4),
              ),
            ),
            const SizedBox(width: 12),
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        product.priceText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '起订 ${product.moq}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(
                        product.location,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      if (product.certified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('认证',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF2E7D32))),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.dealCount}人成交',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.supplierName,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF5B7FD4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

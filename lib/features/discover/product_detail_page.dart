/// 商品详情页
///
/// 展示商品详细信息，底部提供 AI 询盘功能
library;

import 'package:flutter/material.dart';

import '../../contracts/chat_service.dart';
import 'product_model.dart';

/// 商品详情页
class ProductDetailPage extends StatefulWidget {
  final Product product;
  final ChatService? chatService;
  final String enterpriseName;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.chatService,
    this.enterpriseName = '',
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isInquiring = false;
  String? _inquiryReply;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// AI 帮你写询盘
  Future<void> _generateInquiry() async {
    if (widget.chatService == null || _isInquiring) return;

    setState(() {
      _isInquiring = true;
      _inquiryReply = null;
    });

    try {
      final prompt = '''
你是 B2B 采购助手。请帮用户写一份专业的采购询盘，发给这个供应商。

商品信息：
- 商品：${widget.product.title}
- 价格：${widget.product.priceText}
- 起订量：${widget.product.moq}
- 发货地：${widget.product.location}
- 供应商：${widget.product.supplierName}

采购方企业：${widget.enterpriseName}

请生成一份简洁专业的中文询盘消息，包含：
1. 询问是否有现货/库存
2. 询问能否提供样品
3. 询问大批量采购的折扣
4. 询问交货周期
5. 询问付款方式

直接输出询盘内容，不要加解释。
''';

      final reply = await widget.chatService!.sendMessage(
        [ChatMessage(role: 'user', content: prompt)],
      );

      if (mounted) {
        setState(() {
          _inquiryReply = reply;
          _isInquiring = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inquiryReply = '生成失败：$e';
          _isInquiring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品大图占位
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FD4).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      p.type == ProductType.physical
                          ? Icons.inventory_2_outlined
                          : Icons.handshake_outlined,
                      size: 64,
                      color: const Color(0xFF5B7FD4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标题
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1B1C),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 价格
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p.priceText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '起订：${p.moq}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 信息卡片
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x08000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _infoRow('发货地', p.location),
                        _infoRow('成交数', '${p.dealCount} 人'),
                        _infoRow('供应商', p.supplierName),
                        _infoRow('信用分', '${p.supplierRating} 分'),
                        _infoRow(
                            '认证状态', p.certified ? '已认证商家' : '未认证'),
                        _infoRow('商品类型',
                            p.type == ProductType.physical ? '实物产品' : '服务产品'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 描述
                  const Text(
                    '商品描述',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1B1C)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.description,
                    style: const TextStyle(
                        fontSize: 14, height: 1.6, color: Color(0xFF4A4A4A)),
                  ),
                  const SizedBox(height: 16),

                  // 标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...p.industryTags.map((t) => _tagChip(t)),
                      ...p.keywords.take(5).map((k) => _tagChip(k)),
                    ],
                  ),

                  // AI 询盘回复
                  if (_inquiryReply != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.smart_toy,
                                  size: 16, color: Color(0xFF5B7FD4)),
                              SizedBox(width: 6),
                              Text('AI 生成的询盘',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5B7FD4))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _inquiryReply!,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF1A1B1C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 底部操作栏
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isInquiring ? null : _generateInquiry,
                      icon: Icon(_isInquiring
                          ? Icons.hourglass_empty
                          : Icons.edit_note),
                      label: Text(_isInquiring ? '生成中…' : 'AI 帮我写询盘'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B7FD4),
                        side: const BorderSide(color: Color(0xFF5B7FD4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('联系商家功能开发中')),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('联系商家'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1B1C),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF5B7FD4)),
      ),
    );
  }
}

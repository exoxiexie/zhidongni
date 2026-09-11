/// 企业搜索服务
///
/// 对齐 qifuwang enterprise-search.ts 逻辑：
/// - 输入≥3字触发搜索
/// - 模糊匹配评分：精确匹配 > 前缀匹配 > 子串包含
/// - 最多返回5条候选
import 'enterprise_data.dart';
import 'enterprise_model.dart';

class EnterpriseSearchService {
  /// 搜索企业
  /// [query] 搜索关键词（企业名称或统一社会信用代码）
  /// 返回匹配的企业列表，最多5条
  static List<Enterprise> search(String query) {
    final keyword = query.trim();
    if (keyword.length < 3) return [];

    final scored = <_ScoredEnterprise>[];

    for (final ent in kEnterpriseSeedData) {
      final name = ent.name;
      final code = ent.creditCode;
      int score = 0;

      // 精确匹配（企业全称完全一致）
      if (name == keyword) {
        score = 100;
      }
      // 统一社会信用代码精确匹配
      else if (code == keyword) {
        score = 95;
      }
      // 前缀匹配（企业名以关键词开头）
      else if (name.startsWith(keyword)) {
        score = 80;
      }
      // 子串包含（企业名包含关键词）
      else if (name.contains(keyword)) {
        score = 60;
      }
      // 信用代码包含关键词
      else if (code.contains(keyword)) {
        score = 50;
      }

      if (score > 0) {
        scored.add(_ScoredEnterprise(enterprise: ent, score: score));
      }
    }

    // 按评分降序，最多5条
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(5).map((s) => s.enterprise).toList();
  }
}

class _ScoredEnterprise {
  final Enterprise enterprise;
  final int score;
  const _ScoredEnterprise({required this.enterprise, required this.score});
}

/// 业务上下文组装服务
///
/// 打开某个业务智能体时，把该业务标签（DataBusinessTag）下已沉淀的数据
/// （对话记忆 / 联网搜索 / 信息公开 / 本地私有文件）按权重筛选组装成
/// 系统提示词上下文注入对话，让每个业务域都"懂你"。
///
/// 组装规则（用户已确认口径）：
/// - 多对多：一条数据可贴多个业务标签，一个智能体 = 聚合名下所有标签数据
/// - 权重筛选：对话记忆/联网搜索 仅取 weight >= 60 的数据，按权重降序取前 N 条
/// - 信息公开：天然属于对应业务域且数据量小，全量带
/// - 本地私有：仅列文件名清单（正文按需读取，避免大文件撑爆上下文）
library;

import '../enterprise/enterprise_data.dart';
import '../enterprise/public_data.dart';
import '../storage/business_domain_store.dart';
import '../storage/local_file_store.dart';
import '../storage/memory_store.dart';
import '../storage/search_data_store.dart';
import 'business_domain.dart';
import 'data_tags.dart';

class BusinessContextService {
  /// 上下文总字符上限（超出从后截断）
  static const int maxChars = 8000;

  /// 各类数据数量上限
  static const int maxMemories = 8;
  static const int maxSearches = 5;
  static const int maxLocalFiles = 20;
  static const int maxDomainRecords = 8;

  /// 进上下文的权重阈值（与联网搜索上下文阈值一致）
  static const int weightThreshold = 60;

  /// 组装某业务域上下文。任何单类数据读取失败都不影响整体（静默跳过）。
  static Future<String> build({
    required String tenantId,
    required String businessTag,
  }) async {
    final buf = StringBuffer();

    // ── 0. 企业主体信息（身份锚定，所有智能体都带，简短精炼） ──
    try {
      final ent = kEnterpriseSeedData.firstWhere(
        (e) => e.creditCode == tenantId,
        orElse: () => kEnterpriseSeedData[0],
      );
      if (ent.id.isNotEmpty) {
        buf.writeln('【企业主体】${ent.name}');
        buf.writeln('统一社会信用代码：${ent.creditCode}');
        buf.writeln('法定代表人：${ent.legalPerson}，成立日期：${ent.foundedAt}');
        buf.writeln('注册资本：${ent.registeredCapital}，企业类型：${ent.enterpriseType}');
        buf.writeln('所属行业：${ent.industry}，经营状态：${ent.status}');
        buf.writeln('');
      }
    } catch (_) {}

    buf.writeln('【业务域上下文：$businessTag】');

    // ── 1. 对话记忆（权重≥阈值，取前 N） ──
    try {
      final memories = await MemoryStore.listAll(tenantId);
      final matched = memories
          .where((m) =>
              m.dataTags.of(DataTagDimension.business).contains(businessTag) &&
              m.weight >= weightThreshold)
          .toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));
      if (matched.isNotEmpty) {
        buf.writeln('\n【对话记忆】');
        var count = 0;
        for (final m in matched) {
          if (count >= maxMemories) break;
          buf.writeln('- [权重${m.weight}] ${m.title}：${_trim(m.content, 300)}');
          count++;
        }
      }
    } catch (_) {}

    // ── 2. 联网搜索（权重≥阈值，取前 N） ──
    try {
      final searches = await SearchDataStore.listAll(tenantId);
      final matched = searches
          .where((s) =>
              s.dataTags.of(DataTagDimension.business).contains(businessTag) &&
              s.weight >= weightThreshold)
          .toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));
      if (matched.isNotEmpty) {
        buf.writeln('\n【联网搜索】');
        var count = 0;
        for (final s in matched) {
          if (count >= maxSearches) break;
          buf.writeln('- [权重${s.weight}] ${s.title}：${_trim(s.content, 300)}');
          count++;
        }
      }
    } catch (_) {}

    // ── 3. 信息公开（工商/税务/司法/信用，按业务域匹配，全量带） ──
    final publicPart = _buildPublicPart(tenantId, businessTag);
    if (publicPart.isNotEmpty) {
      buf.writeln('\n【信息公开】');
      buf.writeln(publicPart);
    }

    // ── 4. 业务域数据表（该域结构化记录，权重≥阈值，取前 N） ──
    try {
      final domain = BusinessDomain.byTag(businessTag);
      if (domain != null) {
        final records = await BusinessDomainStore.listByTenant(
          tenantId,
          domainId: domain.id,
          weightMin: weightThreshold,
          limit: maxDomainRecords,
        );
        if (records.isNotEmpty) {
          buf.writeln('\n【业务域数据】');
          for (final r in records) {
            buf.writeln('- [权重${r.weight}] ${r.title}：${_trim(r.detail, 300)}');
          }
        }
      }
    } catch (_) {}

    // ── 5. 本地私有文件（仅文件名清单，不进正文） ──
    try {
      final sessions = await LocalFileStore.listSessions(tenantId);
      final fileNames = <String>[];
      for (final s in sessions) {
        for (final f in s.files) {
          if (f.dataTags.of(DataTagDimension.business).contains(businessTag)) {
            fileNames.add('${f.name}（${_formatSize(f.size)}）');
          }
        }
      }
      if (fileNames.isNotEmpty) {
        buf.writeln('\n【本地私有文件】');
        var count = 0;
        for (final name in fileNames) {
          if (count >= maxLocalFiles) break;
          buf.writeln('- $name');
          count++;
        }
      }
    } catch (_) {}

    final text = buf.toString().trim();
    // 没有任何沉淀数据时，给出明确提示（智能体角色提示词会据此引导用户）
    if (text.isEmpty || text == '【业务域上下文：$businessTag】') {
      return '【业务域上下文：$businessTag】\n当前暂无沉淀数据。';
    }
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }

  /// 信息公开部分：按业务域匹配企业公开数据
  static String _buildPublicPart(String tenantId, String businessTag) {
    final parts = <String>[];

    // 税务
    if (businessTag == DataBusinessTag.tax) {
      final t = kTaxData[tenantId];
      if (t != null) {
        parts.add('税务：纳税信用等级 ${t.taxRating}，年纳税额 ${t.annualTaxAmount} 万元，'
            '欠税金额 ${t.owedTax} 万元，涉税处罚 ${t.taxPenaltyCount} 次，'
            '${t.isTaxAbnormal ? '当前为非正常户' : '当前非正常户：否'}');
      }
    }

    // 司法
    if (businessTag == DataBusinessTag.judicial) {
      final j = kJudicialData[tenantId];
      if (j != null) {
        parts.add(
            '司法：涉诉总数 ${j.lawsuitCount}（被告 ${j.asDefendantCount} / 原告 ${j.asPlaintiffCount}），'
            '执行案件 ${j.enforcementCount}，执行标的总额 ${j.enforcementAmount} 万元，'
            '${j.isDishonest ? '为失信被执行人（金额 ${j.dishonestAmount} 万元）' : '非失信被执行人'}');
      }
    }

    // 信用
    if (businessTag == DataBusinessTag.credit) {
      final c = kCreditData[tenantId];
      if (c != null) {
        parts.add('信用：信用评级 ${c.creditRating}，信用分 ${c.creditScore}，'
            '行政处罚 ${c.administrativePenaltyCount} 次，'
            '${c.isBusinessAbnormal ? '经营异常（${c.abnormalReason}）' : '经营异常：否'}，'
            '${c.isSeriousIllegal ? '严重违法失信' : '严重违法失信：否'}');
      }
    }

    return parts.join('\n');
  }

  /// 截断文本
  static String _trim(String text, int max) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  /// 字节数转可读大小
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// 业务域数据条目（供"按业务"视图列表展示）
class BusinessDataEntry {
  /// 来源标签（信息公开/对话记忆/本地私有/联网搜索/外接应用）
  final String source;

  /// 标题
  final String title;

  /// 权重（信息公开/本地文件无权重时为 null）
  final int? weight;

  /// 摘要说明
  final String detail;

  const BusinessDataEntry({
    required this.source,
    required this.title,
    this.weight,
    this.detail = '',
  });
}

/// 业务视图数据服务：按业务标签统计 / 列出数据条目（与注入上下文共用筛选口径）
class BusinessViewService {
  /// 统计各业务域下的数据条数（业务域表+记忆+联网搜索+本地文件+信息公开）
  static Future<Map<String, int>> countByBusiness(String tenantId) async {
    final counts = <String, int>{
      for (final t in DataBusinessTag.all) t: 0,
    };

    // 业务域数据表（三位一体：与智能体/标签一一对应）
    try {
      for (final domain in kBusinessDomains) {
        counts[domain.tag] = (counts[domain.tag] ?? 0) +
            await BusinessDomainStore.countByDomain(tenantId, domain.id);
      }
    } catch (_) {}

    try {
      final memories = await MemoryStore.listAll(tenantId);
      for (final m in memories) {
        for (final t in m.dataTags.of(DataTagDimension.business)) {
          if (counts.containsKey(t)) counts[t] = counts[t]! + 1;
        }
      }
    } catch (_) {}

    try {
      final searches = await SearchDataStore.listAll(tenantId);
      for (final s in searches) {
        for (final t in s.dataTags.of(DataTagDimension.business)) {
          if (counts.containsKey(t)) counts[t] = counts[t]! + 1;
        }
      }
    } catch (_) {}

    try {
      final sessions = await LocalFileStore.listSessions(tenantId);
      for (final s in sessions) {
        for (final f in s.files) {
          for (final t in f.dataTags.of(DataTagDimension.business)) {
            if (counts.containsKey(t)) counts[t] = counts[t]! + 1;
          }
        }
      }
    } catch (_) {}

    // 信息公开（固定：每企业每类公开数据计1条 + 工商照面1条）
    if (kTaxData.containsKey(tenantId)) {
      counts[DataBusinessTag.tax] = counts[DataBusinessTag.tax]! + 1;
    }
    if (kJudicialData.containsKey(tenantId)) {
      counts[DataBusinessTag.judicial] = counts[DataBusinessTag.judicial]! + 1;
    }
    if (kCreditData.containsKey(tenantId)) {
      counts[DataBusinessTag.credit] = counts[DataBusinessTag.credit]! + 1;
    }
    counts[DataBusinessTag.business] = counts[DataBusinessTag.business]! + 1;

    return counts;
  }

  /// 列出某业务域下的全部数据条目（不限权重，供列表页展示）
  static Future<List<BusinessDataEntry>> listByBusiness(
      String tenantId, String businessTag) async {
    final entries = <BusinessDataEntry>[];

    // 业务域数据表（三位一体记录）
    try {
      final domain = BusinessDomain.byTag(businessTag);
      if (domain != null) {
        final records = await BusinessDomainStore.listByTenant(tenantId,
            domainId: domain.id, limit: 200);
        for (final r in records) {
          final sourceTag = r.dataTags.of(DataTagDimension.source).isNotEmpty
              ? r.dataTags.of(DataTagDimension.source).first
              : DataSourceTag.publicInfo;
          entries.add(BusinessDataEntry(
            source: sourceTag,
            title: r.title,
            weight: r.weight,
            detail: BusinessContextService._trim(r.detail, 120),
          ));
        }
      }
    } catch (_) {}

    // 对话记忆
    try {
      final memories = await MemoryStore.listAll(tenantId);
      final matched = memories
          .where((m) =>
              m.dataTags.of(DataTagDimension.business).contains(businessTag))
          .toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));
      for (final m in matched) {
        entries.add(BusinessDataEntry(
          source: DataSourceTag.chatMemory,
          title: m.title,
          weight: m.weight,
          detail: BusinessContextService._trim(m.content, 120),
        ));
      }
    } catch (_) {}

    // 联网搜索
    try {
      final searches = await SearchDataStore.listAll(tenantId);
      final matched = searches
          .where((s) =>
              s.dataTags.of(DataTagDimension.business).contains(businessTag))
          .toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));
      for (final s in matched) {
        entries.add(BusinessDataEntry(
          source: DataSourceTag.webSearch,
          title: s.title,
          weight: s.weight,
          detail: BusinessContextService._trim(s.content, 120),
        ));
      }
    } catch (_) {}

    // 本地私有文件
    try {
      final sessions = await LocalFileStore.listSessions(tenantId);
      for (final s in sessions) {
        for (final f in s.files) {
          if (f.dataTags.of(DataTagDimension.business).contains(businessTag)) {
            entries.add(BusinessDataEntry(
              source: DataSourceTag.localPrivate,
              title: f.name,
              detail: BusinessContextService._formatSize(f.size),
            ));
          }
        }
      }
    } catch (_) {}

    // 信息公开
    if (businessTag == DataBusinessTag.business) {
      try {
        final ent = kEnterpriseSeedData.firstWhere(
          (e) => e.creditCode == tenantId,
          orElse: () => kEnterpriseSeedData[0],
        );
        if (ent.id.isNotEmpty) {
          entries.add(BusinessDataEntry(
            source: DataSourceTag.publicInfo,
            title: '工商照面信息',
            detail: '${ent.name} · ${ent.registeredCapital} · ${ent.industry}',
          ));
        }
      } catch (_) {}
    }
    if (businessTag == DataBusinessTag.tax && kTaxData[tenantId] != null) {
      entries.add(BusinessDataEntry(
        source: DataSourceTag.publicInfo,
        title: '税务信息',
        detail:
            '纳税等级 ${kTaxData[tenantId]!.taxRating} · 年纳税 ${kTaxData[tenantId]!.annualTaxAmount} 万元',
      ));
    }
    if (businessTag == DataBusinessTag.judicial &&
        kJudicialData[tenantId] != null) {
      entries.add(BusinessDataEntry(
        source: DataSourceTag.publicInfo,
        title: '司法信息',
        detail:
            '涉诉 ${kJudicialData[tenantId]!.lawsuitCount} 起 · 执行 ${kJudicialData[tenantId]!.enforcementCount} 起',
      ));
    }
    if (businessTag == DataBusinessTag.credit &&
        kCreditData[tenantId] != null) {
      entries.add(BusinessDataEntry(
        source: DataSourceTag.publicInfo,
        title: '信用信息',
        detail:
            '评级 ${kCreditData[tenantId]!.creditRating} · 信用分 ${kCreditData[tenantId]!.creditScore}',
      ));
    }

    return entries;
  }
}

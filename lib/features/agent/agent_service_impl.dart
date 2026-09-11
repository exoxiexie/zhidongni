/// Agent Harness 实现 · 基于 DeepSeek function calling 的轻量循环调度器
///
/// 核心循环（tool-call loop）：
///   模型调用(带 tools, 非流式) → 有 tool_calls? → 执行工具 → 结果回填 → 回到模型调用
///   无 tool_calls → 最终回复(流式 SSE)
/// 终止条件：maxSteps / timeout / 模型明确结束。
/// 目录隔离：本模块只属于 agent 域，不依赖其他业务模块。
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../contracts/agent_service.dart';
import '../../contracts/api_config.dart';
import '../../contracts/chat_service.dart';
import '../storage/search_data_store.dart';

class HttpAgentService implements AgentService {
  /// 搜索用模型
  static const String _searchModel = 'deepseek-v4-flash';

  final Dio _dio;

  /// 企业工商照面上下文（作为系统提示词注入每次 Agent 任务）
  String? _enterpriseContext;

  /// 当前租户ID（企业统一社会信用代码），用于搜索数据自动沉淀
  String? _tenantId;

  @override
  void setEnterpriseContext(String? contextText) {
    _enterpriseContext = contextText;
  }

  @override
  void setTenantId(String? tenantId) {
    _tenantId = tenantId;
  }

  HttpAgentService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 120),
            ));

  // ────────────────────────────────────────────────────────────
  //  Agent 主循环
  // ────────────────────────────────────────────────────────────

  @override
  Future<AgentResult> run({
    required List<ChatMessage> history,
    List<ToolDefinition> tools = const [],
    String model = 'deepseek-v4-flash',
    int maxSteps = 8,
    Duration timeout = const Duration(seconds: 90),
    AgentStreamCallback? onDelta,
    AgentToolStartCallback? onToolStart,
    AgentToolEndCallback? onToolEnd,
  }) async {
    // 把 ChatMessage 列表转成 OpenAI 格式 messages（含附件处理）
    final messages = await _buildMessages(history);
    final stepLogs = <AgentStepLog>[];
    var totalToolCalls = 0;
    var reply = '';
    var finished = false;
    final overall = Stopwatch()..start();

    for (var step = 1; step <= maxSteps; step++) {
      if (overall.elapsed > timeout) break;
      final stepTimer = Stopwatch()..start();

      // 判断是否为最后一步（无工具可用或达到步数上限时直接流式出最终回复）
      final isFinalStep = (step == maxSteps) || tools.isEmpty;

      if (isFinalStep) {
        // ── 最终回复：流式 SSE ──
        final streamReply = await _streamFinalReply(
          messages: messages,
          model: model,
          onDelta: onDelta,
        );
        reply = mdToCnText(streamReply);
        finished = true;
        stepLogs.add(AgentStepLog(
          step: step,
          toolCalls: const [],
          finished: true,
          elapsed: stepTimer.elapsed,
          promptTokens: 0,
          completionTokens: 0,
        ));
        break;
      }

      // ── 模型调用（带工具 schema，非流式，需要判断 tool_calls）──
      final resp = await _dio.post(
        ApiConfig.chatCompletionsUrl,
        data: {
          'model': model,
          'messages': messages,
          if (tools.isNotEmpty) 'tools': tools.map(_toToolSchema).toList(),
          if (tools.isNotEmpty) 'tool_choice': 'auto',
          'max_tokens': 2048,
        },
        options: Options(headers: {
          'X-Proxy-Token': ApiConfig.proxyToken,
          'Content-Type': 'application/json',
        }),
      );

      final data = resp.data as Map<String, dynamic>;
      final usage = (data['usage'] as Map?) ?? const {};
      final promptTokens = (usage['prompt_tokens'] as num?)?.toInt() ?? 0;
      final completionTokens =
          (usage['completion_tokens'] as num?)?.toInt() ?? 0;

      final choices = (data['choices'] as List?) ?? [];
      final msg = (choices.isEmpty
              ? null
              : (choices[0] as Map)['message'] as Map?)
          ?? const {};
      final content = msg['content']?.toString() ?? '';
      final rawToolCalls = (msg['tool_calls'] as List?) ?? [];

      // ── 无工具调用 → 这就是最终回复，用流式重新输出给用户 ──
      if (rawToolCalls.isEmpty) {
        // 非流式已经拿到了完整内容，但为了用户体验，用流式逐字输出
        if (onDelta != null) {
          // 把已拿到的内容按字符逐段回调（模拟流式，避免用户等太久）
          final processed = mdToCnText(content);
          for (var i = 0; i < processed.length; i += 3) {
            final chunk = processed.substring(
                i, (i + 3 < processed.length) ? i + 3 : processed.length);
            onDelta(chunk, reasoning: false);
          }
        }
        reply = mdToCnText(content);
        finished = true;
        stepLogs.add(AgentStepLog(
          step: step,
          toolCalls: const [],
          finished: true,
          elapsed: stepTimer.elapsed,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
        ));
        break;
      }

      // ── 有工具调用：assistant 消息入历史，逐个执行工具并回填 ──
      messages.add({
        'role': 'assistant',
        'content': content,
        'tool_calls': rawToolCalls,
      });

      final records = <ToolCallRecord>[];
      for (final raw in rawToolCalls) {
        final tc = raw as Map;
        final fn = (tc['function'] as Map?) ?? const {};
        final name = fn['name']?.toString() ?? '';
        final arguments = fn['arguments']?.toString() ?? '{}';
        Map<String, dynamic> args;
        try {
          args = (jsonDecode(arguments) as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
        } catch (_) {
          args = <String, dynamic>{};
        }

        onToolStart?.call(name);
        final result = await _executeTool(tools, name, args);
        onToolEnd?.call(name, result);
        totalToolCalls++;
        messages.add({
          'role': 'tool',
          'tool_call_id': tc['id']?.toString() ?? '',
          'content': result,
        });
        records.add(ToolCallRecord(
          id: tc['id']?.toString() ?? '',
          name: name,
          args: args,
          result: result,
        ));
      }

      stepLogs.add(AgentStepLog(
        step: step,
        toolCalls: records,
        finished: false,
        elapsed: stepTimer.elapsed,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
      ));
    }

    return AgentResult(
      reply: reply,
      steps: stepLogs.length,
      toolCalls: totalToolCalls,
      stepLogs: stepLogs,
      finished: finished,
    );
  }

  // ────────────────────────────────────────────────────────────
  //  最终回复：流式 SSE
  // ────────────────────────────────────────────────────────────

  Future<String> _streamFinalReply({
    required List<Map<String, dynamic>> messages,
    required String model,
    AgentStreamCallback? onDelta,
  }) async {
    final resp = await _dio.post<ResponseBody>(
      ApiConfig.chatCompletionsUrl,
      data: {
        'model': model,
        'messages': messages,
        'max_tokens': 2048,
        'stream': true,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'X-Proxy-Token': ApiConfig.proxyToken,
          'Content-Type': 'application/json',
        },
      ),
    );
    final body = resp.data;
    if (body == null) throw Exception('模型未返回内容');

    final reasoningBuf = StringBuffer();
    final contentBuf = StringBuffer();
    await for (final raw in utf8.decoder
        .bind(body.stream)
        .transform(const LineSplitter())) {
      final line = raw.trim();
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data == '[DONE]') break;
      Map<String, dynamic> json;
      try {
        json = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) continue;
      final delta = (choices[0] as Map)['delta'] as Map?;
      if (delta == null) continue;
      final reasoning = delta['reasoning_content']?.toString() ?? '';
      final content = delta['content']?.toString() ?? '';
      if (reasoning.isNotEmpty) {
        reasoningBuf.write(reasoning);
        onDelta?.call(reasoning, reasoning: true);
      }
      if (content.isNotEmpty) {
        contentBuf.write(content);
        onDelta?.call(content, reasoning: false);
      }
    }
    final reply = contentBuf.isNotEmpty
        ? contentBuf.toString()
        : reasoningBuf.toString();
    if (reply.trim().isEmpty) throw Exception('模型未返回内容');
    return reply;
  }

  // ────────────────────────────────────────────────────────────
  //  ChatMessage → OpenAI 格式 messages（含附件处理）
  // ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _buildMessages(
      List<ChatMessage> history) async {
    final messages = <Map<String, dynamic>>[];
    // ── 企业工商照面上下文：作为系统提示词注入 ──
    if (_enterpriseContext != null && _enterpriseContext!.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': '【当前服务企业主体信息】\n'
            '$_enterpriseContext\n\n'
            '请在回答用户问题时，结合以上企业主体信息给出针对性的建议和分析。'
            '如果用户的问题与该企业相关，请优先基于以上信息回答。',
      });
    }
    for (var i = 0; i < history.length; i++) {
      final m = history[i];
      final att = m.attachment;

      if (m.role == 'user' && att != null) {
        // 文档附件：文本注入 system 上下文
        if (att.type == ChatAttachmentType.document &&
            att.text != null &&
            att.text!.isNotEmpty) {
          messages.add({
            'role': 'system',
            'content': '用户上传了文档「${att.name}」，请基于文档内容回答用户问题，'
                '不要编造文档之外的事实。回答请使用中文。\n\n【文档内容】\n${att.text}',
          });
          messages.add({'role': 'user', 'content': m.content});
          continue;
        }
        // 图片附件：转 data URL 多模态
        if (att.type == ChatAttachmentType.image && att.filePath != null) {
          final bytes = await File(att.filePath!).readAsBytes();
          final b64 = base64Encode(bytes);
          messages.add({
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': m.content.isEmpty ? '请帮我分析这张图片。' : m.content,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:${_mimeFor(att.filePath!)};base64,$b64',
                },
              },
            ],
          });
          continue;
        }
      }

      messages.add({'role': m.role, 'content': m.content});
    }
    return messages;
  }

  String _mimeFor(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // ────────────────────────────────────────────────────────────
  //  工具执行
  // ────────────────────────────────────────────────────────────

  Future<String> _executeTool(
    List<ToolDefinition> tools,
    String name,
    Map<String, dynamic> args,
  ) async {
    for (final t in tools) {
      if (t.name == name) {
        try {
          return await t.execute(args);
        } catch (e) {
          return '工具执行失败：$e';
        }
      }
    }
    return '错误：未找到工具 "$name"';
  }

  Map<String, dynamic> _toToolSchema(ToolDefinition t) => {
        'type': 'function',
        'function': {
          'name': t.name,
          'description': t.description,
          'parameters': t.parameters,
        },
      };

  // ────────────────────────────────────────────────────────────
  //  联网搜索（DeepSeek Anthropic 兼容端点 + web_search 服务器工具）
  // ────────────────────────────────────────────────────────────

  /// 执行一次联网搜索，返回去重后的来源列表。
  Future<List<SearchSource>> searchWeb(String query) async {
    final resp = await _dio.post(
      ApiConfig.anthropicMessagesUrl,
      data: {
        'model': _searchModel,
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Perform a web search for the query: $query'},
            ],
          },
        ],
        'tools': [
          {'type': 'web_search_20250305', 'name': 'web_search', 'max_uses': 5},
        ],
      },
      options: Options(headers: {
        'X-Proxy-Token': ApiConfig.proxyToken,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }),
    );
    final blocks = resp.data?['content'] as List? ?? [];
    final sources = <SearchSource>[];
    final seen = <String>{};
    for (final b in blocks) {
      if (b is Map && b['type'] == 'web_search_tool_result') {
        final items = b['content'] as List? ?? [];
        for (final it in items) {
          if (it is Map) {
            final url = it['url']?.toString() ?? '';
            if (url.isEmpty || seen.contains(url)) continue;
            seen.add(url);
            final title = it['title']?.toString() ?? url;
            sources.add(SearchSource(title: title, url: url));
          }
        }
      }
    }

    // ── 联网搜索自动沉淀：搜索成功且有租户ID时，异步沉淀搜索数据，不阻塞返回 ──
    if (sources.isNotEmpty && _tenantId != null && _tenantId!.isNotEmpty) {
      final title = query.length > 30 ? '${query.substring(0, 30)}...' : query;
      // 沉淀内容 = 输入模型的搜索提炼上下文（格式化的搜索结果）
      final contentBuf = StringBuffer('# 搜索提炼内容\n\n');
      contentBuf.writeln('本次搜索共找到 ${sources.length} 条相关信息，整理如下：\n');
      for (var i = 0; i < sources.length; i++) {
        contentBuf.writeln('## ${i + 1}. ${sources[i].title}');
        contentBuf.writeln('- 链接：${sources[i].url}');
        contentBuf.writeln('');
      }
      // 异步执行，不 await，不阻塞搜索结果返回
      () async {
        try {
          await SearchDataStore.create(
            tenantId: _tenantId!,
            title: title.isEmpty ? '联网搜索' : title,
            searchQuery: query,
            content: contentBuf.toString(),
            sources: sources,
          );
        } catch (e) {
          debugPrint('Agent搜索数据自动沉淀失败: $e');
        }
      }();
    }

    return sources;
  }
}

/// 内置联网搜索工具定义（供 AgentService.run 注册使用）
ToolDefinition buildWebSearchTool(HttpAgentService service) => ToolDefinition(
      name: 'web_search',
      description: '当用户问题需要实时、最新的信息时使用，例如新闻、天气、股价、'
          '最新事件、近期动态等。返回搜索结果的标题和链接，供模型基于搜索结果回答。',
      parameters: {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': '搜索关键词，应简洁准确，例如"2026年AI最新新闻"',
          },
        },
        'required': ['query'],
      },
      execute: (args) async {
        final query = args['query']?.toString() ?? '';
        if (query.isEmpty) return '搜索关键词为空。';
        final sources = await service.searchWeb(query);
        if (sources.isEmpty) return '未找到相关搜索结果。';
        final buf = StringBuffer('搜索结果（共${sources.length}条）：\n');
        for (var i = 0; i < sources.length; i++) {
          buf.writeln('${i + 1}. ${sources[i].title}');
          buf.writeln('   ${sources[i].url}');
        }
        buf.writeln('\n请基于以上搜索结果回答用户问题，在回复末尾以"参考资料："列出主要来源。');
        return buf.toString();
      },
    );

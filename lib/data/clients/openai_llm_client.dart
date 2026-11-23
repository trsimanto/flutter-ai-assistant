import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/llm_client.dart';
import 'http_streaming.dart';

/// OpenAI Chat Completions with `stream: true`. Works with any
/// OpenAI-compatible endpoint (OpenAI, Groq, OpenRouter, local servers...).
class OpenAiLlmClient implements LlmClient {
  OpenAiLlmClient({
    required this.apiKey,
    required this.model,
    this.baseUrl = 'https://api.openai.com/v1',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _http;

  @override
  String get label => 'OpenAI · $model';

  @override
  Stream<String> streamReply({required List<ChatMessage> history, required String systemPrompt}) async* {
    final events = postSse(
      client: _http,
      uri: Uri.parse('$baseUrl/chat/completions'),
      headers: {'Authorization': 'Bearer $apiKey'},
      body: buildRequestBody(model: model, history: history, systemPrompt: systemPrompt),
    );
    await for (final data in events) {
      if (data.trim() == '[DONE]') break;
      final token = parseChunk(data);
      if (token != null && token.isNotEmpty) yield token;
    }
  }

  static Map<String, Object?> buildRequestBody({
    required String model,
    required List<ChatMessage> history,
    required String systemPrompt,
  }) {
    return {
      'model': model,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        for (final m in history) {'role': m.isUser ? 'user' : 'assistant', 'content': m.content},
      ],
    };
  }

  /// Extracts the text delta from one streamed chunk, e.g.
  /// `{"choices":[{"delta":{"content":"Hel"}}]}`.
  static String? parseChunk(String data) {
    final json = jsonDecode(data);
    if (json is! Map) return null;
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final delta = (choices.first as Map)['delta'];
    if (delta is! Map) return null;
    final content = delta['content'];
    return content is String ? content : null;
  }
}

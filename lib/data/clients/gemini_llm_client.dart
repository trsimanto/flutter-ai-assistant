import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/llm_client.dart';
import 'http_streaming.dart';

/// Google Gemini `streamGenerateContent` with `alt=sse`.
class GeminiLlmClient implements LlmClient {
  GeminiLlmClient({
    required this.apiKey,
    required this.model,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _http;

  @override
  String get label => 'Gemini · $model';

  @override
  Stream<String> streamReply({required List<ChatMessage> history, required String systemPrompt}) async* {
    final events = postSse(
      client: _http,
      uri: Uri.parse('$baseUrl/models/$model:streamGenerateContent?alt=sse'),
      headers: {'x-goog-api-key': apiKey},
      body: buildRequestBody(history: history, systemPrompt: systemPrompt),
    );
    await for (final data in events) {
      final text = parseChunk(data);
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  static Map<String, Object?> buildRequestBody({
    required List<ChatMessage> history,
    required String systemPrompt,
  }) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        for (final m in history)
          {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': m.content},
            ],
          },
      ],
    };
  }

  /// Extracts text from one chunk, e.g.
  /// `{"candidates":[{"content":{"parts":[{"text":"Hel"}],"role":"model"}}]}`.
  static String? parseChunk(String data) {
    final json = jsonDecode(data);
    if (json is! Map) return null;
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates.first as Map)['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final text = parts.whereType<Map>().map((p) => p['text']).whereType<String>().join();
    return text.isEmpty ? null : text;
  }
}

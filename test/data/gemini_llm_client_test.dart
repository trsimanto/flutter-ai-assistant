import 'dart:convert';

import 'package:ai_assistant/data/clients/gemini_llm_client.dart';
import 'package:ai_assistant/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeminiLlmClient.parseChunk', () {
    test('joins the text of all parts', () {
      const chunk = '{"candidates":[{"content":{"parts":[{"text":"Hel"},{"text":"lo"}],"role":"model"}}]}';
      expect(GeminiLlmClient.parseChunk(chunk), 'Hello');
    });

    test('returns null when there is no text (e.g. usage-only chunk)', () {
      expect(GeminiLlmClient.parseChunk('{"usageMetadata":{"totalTokenCount":12}}'), isNull);
      expect(GeminiLlmClient.parseChunk('{"candidates":[{"finishReason":"STOP"}]}'), isNull);
    });
  });

  test('maps assistant messages to the "model" role', () {
    final body = GeminiLlmClient.buildRequestBody(
      systemPrompt: 'sys',
      history: const [
        ChatMessage(id: '1', role: ChatRole.user, content: 'q'),
        ChatMessage(id: '2', role: ChatRole.assistant, content: 'a'),
      ],
    );
    final contents = body['contents']! as List;
    expect((contents[0] as Map)['role'], 'user');
    expect((contents[1] as Map)['role'], 'model');
  });

  test('streams text from alt=sse endpoint with the api key header', () async {
    late http.BaseRequest captured;
    final mock = MockClient.streaming((request, _) async {
      captured = request;
      const sse = 'data: {"candidates":[{"content":{"parts":[{"text":"Sa"}]}}]}\r\n\r\n'
          'data: {"candidates":[{"content":{"parts":[{"text":"lam"}]}}]}\r\n\r\n';
      return http.StreamedResponse(Stream.value(utf8.encode(sse)), 200);
    });
    final client = GeminiLlmClient(apiKey: 'test-key', model: 'gemini-test', httpClient: mock);

    final tokens = await client
        .streamReply(history: const [ChatMessage(id: '1', role: ChatRole.user, content: 'hi')], systemPrompt: 's')
        .toList();

    expect(tokens, ['Sa', 'lam']);
    expect(captured.url.path, '/v1beta/models/gemini-test:streamGenerateContent');
    expect(captured.url.queryParameters['alt'], 'sse');
    expect(captured.headers['x-goog-api-key'], 'test-key');
  });
}

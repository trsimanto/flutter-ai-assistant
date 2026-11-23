import 'dart:convert';

import 'package:ai_assistant/data/clients/openai_llm_client.dart';
import 'package:ai_assistant/domain/entities/chat_message.dart';
import 'package:ai_assistant/domain/repositories/llm_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAiLlmClient.parseChunk', () {
    test('returns the delta content', () {
      expect(OpenAiLlmClient.parseChunk('{"choices":[{"index":0,"delta":{"content":"Hel"}}]}'), 'Hel');
    });

    test('returns null for role-only and empty chunks', () {
      expect(OpenAiLlmClient.parseChunk('{"choices":[{"delta":{"role":"assistant"}}]}'), isNull);
      expect(OpenAiLlmClient.parseChunk('{"choices":[]}'), isNull);
    });
  });

  test('builds a request with system prompt and mapped roles', () {
    final body = OpenAiLlmClient.buildRequestBody(
      model: 'gpt-test',
      systemPrompt: 'be brief',
      history: const [
        ChatMessage(id: '1', role: ChatRole.user, content: 'hi'),
        ChatMessage(id: '2', role: ChatRole.assistant, content: 'hello'),
      ],
    );
    expect(body['stream'], isTrue);
    expect(body['messages'], [
      {'role': 'system', 'content': 'be brief'},
      {'role': 'user', 'content': 'hi'},
      {'role': 'assistant', 'content': 'hello'},
    ]);
  });

  test('streams tokens until [DONE] and sends the bearer token', () async {
    late http.BaseRequest captured;
    final mock = MockClient.streaming((request, _) async {
      captured = request;
      const sse = 'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n'
          'data: {"choices":[{"delta":{"content":" there"}}]}\n\n'
          'data: [DONE]\n\n';
      return http.StreamedResponse(Stream.value(utf8.encode(sse)), 200);
    });
    final client = OpenAiLlmClient(apiKey: 'test-key', model: 'm', httpClient: mock);

    final tokens = await client
        .streamReply(history: const [ChatMessage(id: '1', role: ChatRole.user, content: 'hi')], systemPrompt: 's')
        .toList();

    expect(tokens, ['Hi', ' there']);
    expect(captured.url.path, '/v1/chat/completions');
    expect(captured.headers['Authorization'], 'Bearer test-key');
  });

  test('throws LlmException with the API error message', () async {
    final mock = MockClient.streaming((_, __) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"error":{"message":"Invalid key"}}')),
          401,
        ));
    final client = OpenAiLlmClient(apiKey: 'bad', model: 'm', httpClient: mock);
    expect(
      client.streamReply(history: const [], systemPrompt: 's').toList(),
      throwsA(isA<LlmException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });
}

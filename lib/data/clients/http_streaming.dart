import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/llm_client.dart';
import '../sse/sse_parser.dart';

/// Sends a JSON POST and returns the SSE `data:` payloads of the response.
Stream<String> postSse({
  required http.Client client,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, Object?> body,
}) async* {
  final request = http.Request('POST', uri)
    ..headers.addAll({'Content-Type': 'application/json', 'Accept': 'text/event-stream', ...headers})
    ..body = jsonEncode(body);

  final response = await client.send(request);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final text = await response.stream.bytesToString();
    throw LlmException(_errorMessage(text), statusCode: response.statusCode);
  }
  yield* response.stream.transform(const SseDecoder());
}

String _errorMessage(String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map && json['error'] is Map && json['error']['message'] is String) {
      return json['error']['message'] as String;
    }
  } catch (_) {
    // Not JSON, fall through.
  }
  return body.isEmpty ? 'Request failed' : body;
}

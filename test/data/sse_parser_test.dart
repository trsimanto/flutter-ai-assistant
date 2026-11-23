import 'dart:convert';

import 'package:ai_assistant/data/sse/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SseDecoder', () {
    test('emits one payload per event and ignores comments', () async {
      final lines = Stream.fromIterable([
        ': keep-alive',
        'data: {"a":1}',
        '',
        'event: message',
        'data: {"b":2}',
        '',
      ]);
      expect(await SseDecoder.decodeLines(lines).toList(), ['{"a":1}', '{"b":2}']);
    });

    test('joins multi-line data fields', () async {
      final lines = Stream.fromIterable(['data: line1', 'data: line2', '']);
      expect(await SseDecoder.decodeLines(lines).toList(), ['line1\nline2']);
    });

    test('flushes the last event without a trailing blank line', () async {
      final lines = Stream.fromIterable(['data: [DONE]']);
      expect(await SseDecoder.decodeLines(lines).toList(), ['[DONE]']);
    });

    test('handles events split across byte chunks and CRLF', () async {
      const raw = 'data: {"x":"he"}\r\n\r\ndata: {"x":"llo"}\r\n\r\n';
      final bytes = utf8.encode(raw);
      final chunks = Stream<List<int>>.fromIterable([bytes.sublist(0, 7), bytes.sublist(7, 20), bytes.sublist(20)]);
      expect(await chunks.transform(const SseDecoder()).toList(), ['{"x":"he"}', '{"x":"llo"}']);
    });
  });
}

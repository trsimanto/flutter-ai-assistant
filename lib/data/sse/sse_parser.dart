import 'dart:async';
import 'dart:convert';

/// Turns a raw HTTP byte stream in Server-Sent Events format into the
/// payloads of its `data:` fields (one string per event).
///
/// Handles events split across network chunks, multi-line `data:` fields,
/// comments (`: keep-alive`) and both `\n` and `\r\n` line endings.
class SseDecoder extends StreamTransformerBase<List<int>, String> {
  const SseDecoder();

  @override
  Stream<String> bind(Stream<List<int>> stream) => decodeLines(stream.transform(utf8.decoder).transform(const LineSplitter()));

  /// Exposed separately so it can be unit-tested with plain strings.
  static Stream<String> decodeLines(Stream<String> lines) async* {
    final buffer = <String>[];
    await for (final line in lines) {
      if (line.isEmpty) {
        if (buffer.isNotEmpty) {
          yield buffer.join('\n');
          buffer.clear();
        }
        continue;
      }
      if (line.startsWith(':')) continue; // comment / keep-alive
      if (line.startsWith('data:')) {
        var value = line.substring(5);
        if (value.startsWith(' ')) value = value.substring(1);
        buffer.add(value);
      }
      // Other fields (event:, id:, retry:) are not needed by the chat providers.
    }
    if (buffer.isNotEmpty) yield buffer.join('\n');
  }
}

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/llm_client.dart';

/// Offline demo model. Streams a canned Markdown answer word by word so the
/// app is fully usable without an API key (and makes tests deterministic).
class FakeLlmClient implements LlmClient {
  const FakeLlmClient({this.delay = const Duration(milliseconds: 35), this.failWith});

  final Duration delay;

  /// When set, the stream throws this error after the first word (for tests).
  final Object? failWith;

  @override
  String get label => 'Demo mode';

  @override
  Stream<String> streamReply({required List<ChatMessage> history, required String systemPrompt}) async* {
    final question = history.isEmpty ? '' : history.last.content;
    final words = cannedAnswer(question).split(RegExp(r'(?<= )'));
    for (var i = 0; i < words.length; i++) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (failWith != null && i == 1) throw failWith!;
      yield words[i];
    }
  }

  static String cannedAnswer(String question) {
    final preview = question.length > 60 ? '${question.substring(0, 60)}...' : question;
    return 'This is **demo mode**, so the answer is generated locally.\n\n'
        'You asked: _${preview.replaceAll('\n', ' ')}_\n\n'
        'To get real answers:\n'
        '1. Open **Settings** (top right).\n'
        '2. Choose **OpenAI** or **Gemini**.\n'
        '3. Paste your API key. It is stored only on this device in secure storage.\n\n'
        '```dart\n'
        "final reply = await client.streamReply(history: history, systemPrompt: preset);\n"
        '```';
  }
}

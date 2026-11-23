import '../entities/chat_message.dart';
import '../entities/prompt_preset.dart';
import '../repositories/llm_client.dart';

/// Builds the request context (history + system prompt) and streams the reply.
class SendMessage {
  const SendMessage({this.maxHistory = 20});

  /// How many previous messages are sent as context, to keep requests small.
  final int maxHistory;

  Stream<String> call({
    required LlmClient client,
    required List<ChatMessage> history,
    required PromptPreset preset,
  }) {
    final context = history
        .where((m) => !m.isError && m.content.trim().isNotEmpty)
        .toList();
    final trimmed = context.length > maxHistory ? context.sublist(context.length - maxHistory) : context;
    return client.streamReply(history: trimmed, systemPrompt: preset.systemPrompt);
  }
}

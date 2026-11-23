import '../entities/chat_message.dart';

/// Provider-agnostic contract for a chat model that streams its answer.
abstract interface class LlmClient {
  /// Human readable name, shown in the app bar (e.g. "OpenAI · gpt-4o-mini").
  String get label;

  /// Streams the assistant reply token by token (or chunk by chunk).
  Stream<String> streamReply({required List<ChatMessage> history, required String systemPrompt});
}

class LlmException implements Exception {
  const LlmException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null ? message : 'HTTP $statusCode: $message';
}

import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/prompt_preset.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.preset = PromptPreset.general,
    this.isStreaming = false,
    this.modelLabel = 'Demo mode',
  });

  final List<ChatMessage> messages;
  final PromptPreset preset;
  final bool isStreaming;
  final String modelLabel;

  bool get canRetry => !isStreaming && messages.isNotEmpty && messages.last.role == ChatRole.assistant;

  ChatState copyWith({
    List<ChatMessage>? messages,
    PromptPreset? preset,
    bool? isStreaming,
    String? modelLabel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      preset: preset ?? this.preset,
      isStreaming: isStreaming ?? this.isStreaming,
      modelLabel: modelLabel ?? this.modelLabel,
    );
  }

  @override
  List<Object?> get props => [messages, preset, isStreaming, modelLabel];
}

import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.isError = false,
  });

  final String id;
  final ChatRole role;
  final String content;
  final bool isStreaming;
  final bool isError;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? content, bool? isStreaming, bool? isError}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [id, role, content, isStreaming, isError];
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/prompt_preset.dart';
import '../../domain/repositories/llm_client.dart';
import '../../domain/usecases/send_message.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required LlmClient client, SendMessage sendMessage = const SendMessage()})
      : _client = client,
        _sendMessage = sendMessage,
        super(ChatState(modelLabel: client.label));

  LlmClient _client;
  final SendMessage _sendMessage;
  StreamSubscription<String>? _subscription;
  Completer<void>? _done;
  int _idCounter = 0;

  /// The model currently used to answer.
  LlmClient get client => _client;

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  /// Swap the model (e.g. after the user pastes an API key in Settings).
  void updateClient(LlmClient client) {
    _client = client;
    emit(state.copyWith(modelLabel: client.label));
  }

  void selectPreset(PromptPreset preset) => emit(state.copyWith(preset: preset));

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;
    final user = ChatMessage(id: _nextId(), role: ChatRole.user, content: trimmed);
    await _generate([...state.messages, user]);
  }

  /// Regenerates the last answer.
  Future<void> retry() async {
    if (!state.canRetry) return;
    final history = [...state.messages]..removeLast();
    await _generate(history);
  }

  /// Stops streaming and keeps whatever was generated so far.
  Future<void> stop() async {
    await _cancel();
    _finishLast();
  }

  Future<void> newChat() async {
    await _cancel();
    emit(state.copyWith(messages: const [], isStreaming: false));
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    final done = _done;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _generate(List<ChatMessage> history) async {
    await _cancel();
    final reply = ChatMessage(id: _nextId(), role: ChatRole.assistant, content: '', isStreaming: true);
    emit(state.copyWith(messages: [...history, reply], isStreaming: true));

    final completer = _done = Completer<void>();
    final buffer = StringBuffer();
    _subscription = _sendMessage(client: _client, history: history, preset: state.preset).listen(
      (token) {
        buffer.write(token);
        _updateLast((m) => m.copyWith(content: buffer.toString()));
      },
      onError: (Object error) {
        final partial = buffer.toString();
        final message = error is LlmException ? error.toString() : 'Something went wrong: $error';
        _updateLast(
          (m) => m.copyWith(
            content: partial.isEmpty ? message : '$partial\n\n_${message}_',
            isStreaming: false,
            isError: true,
          ),
        );
        emit(state.copyWith(isStreaming: false));
        _subscription = null;
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        _finishLast();
        _subscription = null;
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  void _finishLast() {
    if (state.messages.isEmpty) {
      emit(state.copyWith(isStreaming: false));
      return;
    }
    _updateLast((m) => m.copyWith(isStreaming: false));
    emit(state.copyWith(isStreaming: false));
  }

  void _updateLast(ChatMessage Function(ChatMessage) update) {
    if (isClosed || state.messages.isEmpty) return;
    final messages = [...state.messages];
    messages[messages.length - 1] = update(messages.last);
    emit(state.copyWith(messages: messages));
  }

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}

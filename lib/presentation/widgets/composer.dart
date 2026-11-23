import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class Composer extends StatefulWidget {
  const Composer({super.key});

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<ChatCubit>().send(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = context.select<ChatCubit, bool>((c) => c.state.isStreaming);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('composer_field'),
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocSelector<ChatCubit, ChatState, bool>(
            selector: (s) => s.isStreaming,
            builder: (context, streaming) => streaming
                ? IconButton.filledTonal(
                    key: const Key('stop_button'),
                    tooltip: 'Stop generating',
                    icon: const Icon(Icons.stop_rounded),
                    onPressed: context.read<ChatCubit>().stop,
                  )
                : IconButton.filled(
                    key: const Key('send_button'),
                    tooltip: 'Send',
                    icon: const Icon(Icons.arrow_upward_rounded),
                    onPressed: isStreaming ? null : _submit,
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/composer.dart';
import '../widgets/empty_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/preset_chips.dart';
import '../widgets/settings_sheet.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<ChatCubit, ChatState, String>(
          selector: (s) => s.modelLabel,
          builder: (context, label) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Assistant'),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: cubit.newChat,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PresetChips(),
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listenWhen: (a, b) => a.messages != b.messages,
                listener: (_, __) => _scrollToBottom(),
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return EmptyState(onSuggestion: cubit.send);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isLast = index == state.messages.length - 1;
                      return MessageBubble(
                        message: message,
                        onRetry: isLast && state.canRetry ? cubit.retry : null,
                      );
                    },
                  );
                },
              ),
            ),
            const Composer(),
          ],
        ),
      ),
    );
  }
}

import 'package:ai_assistant/data/clients/fake_llm_client.dart';
import 'package:ai_assistant/presentation/cubit/chat_cubit.dart';
import 'package:ai_assistant/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sending a message shows the question and the streamed answer', (tester) async {
    final cubit = ChatCubit(client: const FakeLlmClient(delay: Duration.zero));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const ChatPage()),
      ),
    );

    expect(find.text('How can I help?'), findsOneWidget);
    expect(find.text('Code reviewer'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('composer_field')), 'What is Flutter?');
    await tester.tap(find.byKey(const Key('send_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('What is Flutter?'), findsOneWidget);
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(cubit.state.messages.last.content, contains('demo mode'));
    expect(find.byKey(const Key('send_button')), findsOneWidget);
  });
}

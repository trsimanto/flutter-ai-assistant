import 'dart:async';

import 'package:ai_assistant/data/clients/fake_llm_client.dart';
import 'package:ai_assistant/domain/entities/chat_message.dart';
import 'package:ai_assistant/domain/entities/prompt_preset.dart';
import 'package:ai_assistant/domain/repositories/llm_client.dart';
import 'package:ai_assistant/presentation/cubit/chat_cubit.dart';
import 'package:ai_assistant/presentation/cubit/chat_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLlmClient extends Mock implements LlmClient {}

void main() {
  const fake = FakeLlmClient(delay: Duration.zero);

  group('ChatCubit', () {
    blocTest<ChatCubit, ChatState>(
      'streams the fake answer into a single assistant message',
      build: () => ChatCubit(client: fake),
      act: (cubit) => cubit.send('Hello'),
      verify: (cubit) {
        final messages = cubit.state.messages;
        expect(messages, hasLength(2));
        expect(messages.first.role, ChatRole.user);
        expect(messages.last.role, ChatRole.assistant);
        expect(messages.last.content, FakeLlmClient.cannedAnswer('Hello'));
        expect(messages.last.isStreaming, isFalse);
        expect(cubit.state.isStreaming, isFalse);
      },
    );

    blocTest<ChatCubit, ChatState>(
      'ignores blank input',
      build: () => ChatCubit(client: fake),
      act: (cubit) => cubit.send('   '),
      expect: () => const <ChatState>[],
    );

    blocTest<ChatCubit, ChatState>(
      'marks the reply as an error and keeps partial text when the stream fails',
      build: () => ChatCubit(client: const FakeLlmClient(delay: Duration.zero, failWith: LlmException('boom'))),
      act: (cubit) => cubit.send('Hi'),
      verify: (cubit) {
        final last = cubit.state.messages.last;
        expect(last.isError, isTrue);
        expect(last.content, contains('boom'));
        expect(cubit.state.canRetry, isTrue);
      },
    );

    blocTest<ChatCubit, ChatState>(
      'retry regenerates only the last answer',
      build: () => ChatCubit(client: fake),
      act: (cubit) async {
        await cubit.send('Hi');
        await cubit.retry();
      },
      verify: (cubit) => expect(cubit.state.messages, hasLength(2)),
    );

    blocTest<ChatCubit, ChatState>(
      'sends the selected preset as the system prompt',
      setUp: () {
        registerFallbackValue(<ChatMessage>[]);
      },
      build: () {
        final client = MockLlmClient();
        when(() => client.label).thenReturn('mock');
        when(() => client.streamReply(history: any(named: 'history'), systemPrompt: any(named: 'systemPrompt')))
            .thenAnswer((_) => Stream.fromIterable(['ok']));
        return ChatCubit(client: client);
      },
      act: (cubit) async {
        cubit.selectPreset(PromptPreset.translateBangla);
        await cubit.send('Good morning');
      },
      verify: (cubit) {
        final client = cubit.client as MockLlmClient;
        verify(() => client.streamReply(
              history: any(named: 'history'),
              systemPrompt: PromptPreset.translateBangla.systemPrompt,
            )).called(1);
        expect(cubit.state.messages.last.content, 'ok');
      },
    );

    test('stop keeps the partial answer and ends streaming', () async {
      final controller = StreamController<String>();
      final client = MockLlmClient();
      when(() => client.label).thenReturn('mock');
      registerFallbackValue(<ChatMessage>[]);
      when(() => client.streamReply(history: any(named: 'history'), systemPrompt: any(named: 'systemPrompt')))
          .thenAnswer((_) => controller.stream);
      final cubit = ChatCubit(client: client);

      unawaited(cubit.send('Hi'));
      controller.add('Partial');
      await Future<void>.delayed(Duration.zero);
      await cubit.stop();

      expect(cubit.state.isStreaming, isFalse);
      expect(cubit.state.messages.last.content, 'Partial');
      expect(cubit.state.messages.last.isStreaming, isFalse);
      await controller.close();
      await cubit.close();
    });

    blocTest<ChatCubit, ChatState>(
      'newChat clears the conversation',
      build: () => ChatCubit(client: fake),
      act: (cubit) async {
        await cubit.send('Hi');
        await cubit.newChat();
      },
      verify: (cubit) => expect(cubit.state.messages, isEmpty),
    );
  });
}

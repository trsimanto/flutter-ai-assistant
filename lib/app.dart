import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/llm_config.dart';
import 'data/clients/llm_client_factory.dart';
import 'data/settings/settings_repository.dart';
import 'presentation/cubit/chat_cubit.dart';
import 'presentation/cubit/settings_cubit.dart';
import 'presentation/pages/chat_page.dart';

class AiAssistantApp extends StatelessWidget {
  const AiAssistantApp({super.key, required this.settingsRepository, required this.initialConfig});

  final SettingsRepository settingsRepository;
  final LlmConfig initialConfig;

  static const _seed = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(repository: settingsRepository, initial: initialConfig)..load(),
        ),
        BlocProvider(create: (_) => ChatCubit(client: createLlmClient(initialConfig))),
      ],
      child: BlocListener<SettingsCubit, LlmConfig>(
        listener: (context, config) => context.read<ChatCubit>().updateClient(createLlmClient(config)),
        child: MaterialApp(
          title: 'AI Assistant',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
          darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark, useMaterial3: true),
          home: const ChatPage(),
        ),
      ),
    );
  }
}

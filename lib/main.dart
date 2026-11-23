import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/llm_config.dart';
import 'data/settings/settings_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AiAssistantApp(
      settingsRepository: SettingsRepository(),
      initialConfig: LlmConfig.fromEnvironment(),
    ),
  );
}

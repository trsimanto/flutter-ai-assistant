import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/llm_config.dart';
import '../cubit/settings_cubit.dart';

Future<void> showSettingsSheet(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: cubit, child: const _SettingsSheet()),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late LlmProvider _provider;
  late final TextEditingController _key;
  late final TextEditingController _model;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final config = context.read<SettingsCubit>().state;
    _provider = config.provider == LlmProvider.fake ? LlmProvider.openai : config.provider;
    _key = TextEditingController(text: config.apiKey);
    _model = TextEditingController(text: config.provider == LlmProvider.fake ? '' : config.model);
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SettingsCubit>().save(provider: _provider, apiKey: _key.text.trim(), model: _model.text);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await context.read<SettingsCubit>().reset();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Model settings', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<LlmProvider>(
            segments: const [
              ButtonSegment(value: LlmProvider.openai, label: Text('OpenAI')),
              ButtonSegment(value: LlmProvider.gemini, label: Text('Gemini')),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => setState(() => _provider = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            decoration: InputDecoration(
              labelText: 'Model (optional)',
              hintText: LlmConfig.defaultModel(_provider),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The key is stored only on this device, in the iOS Keychain / Android Keystore. '
            'Leave it empty to use demo mode.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(onPressed: _reset, child: const Text('Reset to demo')),
              const Spacer(),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/llm_config.dart';
import '../../data/settings/settings_repository.dart';

class SettingsCubit extends Cubit<LlmConfig> {
  SettingsCubit({required SettingsRepository repository, required LlmConfig initial})
      : _repository = repository,
        _environment = initial,
        super(initial);

  final SettingsRepository _repository;
  final LlmConfig _environment;

  Future<void> load() async => emit(await _repository.load(_environment));

  Future<void> save({required LlmProvider provider, required String apiKey, String? model}) async {
    final config = LlmConfig(
      provider: apiKey.isEmpty ? LlmProvider.fake : provider,
      apiKey: apiKey,
      model: (model == null || model.trim().isEmpty) ? LlmConfig.defaultModel(provider) : model.trim(),
      baseUrl: LlmConfig.defaultBaseUrl(provider),
    );
    await _repository.save(config);
    emit(config);
  }

  Future<void> reset() async {
    await _repository.clear();
    emit(_environment);
  }
}

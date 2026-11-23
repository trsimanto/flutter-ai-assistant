import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/llm_config.dart';

/// Persists the provider choice and API key in the platform keystore
/// (Keychain on iOS, EncryptedSharedPreferences/Keystore on Android).
class SettingsRepository {
  SettingsRepository({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kProvider = 'llm_provider';
  static const _kKey = 'llm_api_key';
  static const _kModel = 'llm_model';

  Future<LlmConfig> load(LlmConfig fallback) async {
    final values = await _storage.readAll();
    final key = values[_kKey];
    if (key == null || key.isEmpty) return fallback;
    final provider = LlmConfig.parseProvider(values[_kProvider] ?? '');
    final model = values[_kModel];
    return LlmConfig(
      provider: provider,
      apiKey: key,
      model: (model == null || model.isEmpty) ? LlmConfig.defaultModel(provider) : model,
      baseUrl: LlmConfig.defaultBaseUrl(provider),
    );
  }

  Future<void> save(LlmConfig config) async {
    await _storage.write(key: _kProvider, value: config.provider.name);
    await _storage.write(key: _kKey, value: config.apiKey);
    await _storage.write(key: _kModel, value: config.model);
  }

  Future<void> clear() => _storage.deleteAll();
}

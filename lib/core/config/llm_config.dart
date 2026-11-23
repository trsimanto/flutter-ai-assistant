import 'package:equatable/equatable.dart';

enum LlmProvider { fake, openai, gemini }

/// Runtime configuration. Defaults come from `--dart-define`, and can be
/// overridden from the in-app Settings sheet (stored in secure storage).
class LlmConfig extends Equatable {
  const LlmConfig({
    required this.provider,
    required this.apiKey,
    required this.model,
    required this.baseUrl,
  });

  final LlmProvider provider;
  final String apiKey;
  final String model;
  final String baseUrl;

  static const _envProvider = String.fromEnvironment('LLM_PROVIDER');
  static const _envKey = String.fromEnvironment('LLM_API_KEY');
  static const _envModel = String.fromEnvironment('LLM_MODEL');
  static const _envBaseUrl = String.fromEnvironment('LLM_BASE_URL');

  factory LlmConfig.fromEnvironment() {
    final provider = parseProvider(_envProvider);
    return LlmConfig(
      provider: _envKey.isEmpty ? LlmProvider.fake : provider,
      apiKey: _envKey,
      model: _envModel.isEmpty ? defaultModel(provider) : _envModel,
      baseUrl: _envBaseUrl.isEmpty ? defaultBaseUrl(provider) : _envBaseUrl,
    );
  }

  static LlmProvider parseProvider(String value) => switch (value.toLowerCase()) {
        'openai' => LlmProvider.openai,
        'gemini' => LlmProvider.gemini,
        _ => LlmProvider.fake,
      };

  static String defaultModel(LlmProvider provider) => switch (provider) {
        LlmProvider.openai => 'gpt-4o-mini',
        LlmProvider.gemini => 'gemini-2.5-flash',
        LlmProvider.fake => 'demo',
      };

  static String defaultBaseUrl(LlmProvider provider) => switch (provider) {
        LlmProvider.openai => 'https://api.openai.com/v1',
        LlmProvider.gemini => 'https://generativelanguage.googleapis.com/v1beta',
        LlmProvider.fake => '',
      };

  LlmConfig copyWith({LlmProvider? provider, String? apiKey, String? model, String? baseUrl}) {
    return LlmConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  @override
  List<Object?> get props => [provider, apiKey, model, baseUrl];
}

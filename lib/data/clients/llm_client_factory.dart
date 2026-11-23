import '../../core/config/llm_config.dart';
import '../../domain/repositories/llm_client.dart';
import 'fake_llm_client.dart';
import 'gemini_llm_client.dart';
import 'openai_llm_client.dart';

LlmClient createLlmClient(LlmConfig config) {
  if (config.apiKey.isEmpty) return const FakeLlmClient();
  return switch (config.provider) {
    LlmProvider.openai => OpenAiLlmClient(apiKey: config.apiKey, model: config.model, baseUrl: config.baseUrl),
    LlmProvider.gemini => GeminiLlmClient(apiKey: config.apiKey, model: config.model, baseUrl: config.baseUrl),
    LlmProvider.fake => const FakeLlmClient(),
  };
}

import 'package:equatable/equatable.dart';

/// A one-tap system prompt that changes how the assistant answers.
class PromptPreset extends Equatable {
  const PromptPreset({required this.id, required this.label, required this.systemPrompt});

  final String id;
  final String label;
  final String systemPrompt;

  static const general = PromptPreset(
    id: 'general',
    label: 'General',
    systemPrompt: 'You are a helpful, concise assistant. Use Markdown when it helps readability.',
  );

  static const codeReviewer = PromptPreset(
    id: 'code_reviewer',
    label: 'Code reviewer',
    systemPrompt:
        'You are a senior mobile engineer reviewing code. Point out bugs, performance and security issues first, '
        'then readability. Suggest concrete fixes with short code snippets.',
  );

  static const eli5 = PromptPreset(
    id: 'eli5',
    label: "Explain like I'm 5",
    systemPrompt: 'Explain everything in very simple words with a short everyday analogy. Keep it under 120 words.',
  );

  static const translateBangla = PromptPreset(
    id: 'translate_bn',
    label: 'Translate to Bangla',
    systemPrompt: 'Translate the user message into natural, fluent Bangla. Reply with the translation only.',
  );

  static const all = [general, codeReviewer, eli5, translateBangla];

  @override
  List<Object?> get props => [id];
}

import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const _suggestions = [
    'Review this Kotlin: fun sum(a: List<Int>) = a.reduce { x, y -> x + y }',
    'Explain WebRTC like I am 5',
    'Write a Flutter Cubit that loads a list of users',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Icon(Icons.auto_awesome, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('How can I help?', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Pick a style above, then ask a question. Answers stream in as they are generated.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => onSuggestion(s),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
              ),
              child: Text(s),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prompt_preset.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class PresetChips extends StatelessWidget {
  const PresetChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: BlocSelector<ChatCubit, ChatState, PromptPreset>(
        selector: (s) => s.preset,
        builder: (context, selected) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: PromptPreset.all.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final preset = PromptPreset.all[index];
            return ChoiceChip(
              label: Text(preset.label),
              selected: preset == selected,
              onSelected: (_) => context.read<ChatCubit>().selectPreset(preset),
            );
          },
        ),
      ),
    );
  }
}

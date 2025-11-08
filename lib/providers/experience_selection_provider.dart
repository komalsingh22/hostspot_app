import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience.dart';

class ExperienceSelectionState {
  final List<Experience> experiences;
  final Set<String> selectedExperienceIds;
  final String description;

  ExperienceSelectionState({
    required this.experiences,
    this.selectedExperienceIds = const {},
    this.description = '',
  });

  ExperienceSelectionState copyWith({
    List<Experience>? experiences,
    Set<String>? selectedExperienceIds,
    String? description,
  }) {
    return ExperienceSelectionState(
      experiences: experiences ?? this.experiences,
      selectedExperienceIds:
          selectedExperienceIds ?? this.selectedExperienceIds,
      description: description ?? this.description,
    );
  }
}

class ExperienceSelectionNotifier
    extends StateNotifier<ExperienceSelectionState> {
  ExperienceSelectionNotifier()
    : super(ExperienceSelectionState(experiences: []));

  void setExperiences(List<Experience> experiences) {
    state = state.copyWith(experiences: experiences);
  }

  void toggleExperienceSelection(
    String experienceId,
    List<Experience> allExperiences,
  ) {
    final newSelectedIds = Set<String>.from(state.selectedExperienceIds);

    if (newSelectedIds.contains(experienceId)) {
      newSelectedIds.remove(experienceId);
    } else {
      newSelectedIds.add(experienceId);
    }

    // Reorder experiences: selected ones first, maintaining their selection order
    final selectedExperiences = <Experience>[];
    final unselectedExperiences = <Experience>[];

    for (final id in newSelectedIds) {
      final experience = allExperiences.firstWhere((e) => e.id == id);
      selectedExperiences.add(experience);
    }

    for (final experience in allExperiences) {
      if (!newSelectedIds.contains(experience.id)) {
        unselectedExperiences.add(experience);
      }
    }

    final reorderedExperiences = [
      ...selectedExperiences,
      ...unselectedExperiences,
    ];

    state = state.copyWith(
      experiences: reorderedExperiences,
      selectedExperienceIds: newSelectedIds,
    );
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }
}

final experienceSelectionProvider =
    StateNotifierProvider<
      ExperienceSelectionNotifier,
      ExperienceSelectionState
    >((ref) {
      return ExperienceSelectionNotifier();
    });

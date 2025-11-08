import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience.dart';
import '../services/experience_service.dart';

final experienceServiceProvider = Provider<ExperienceService>((ref) {
  return ExperienceService();
});

final experiencesProvider = FutureProvider<List<Experience>>((ref) async {
  final service = ref.read(experienceServiceProvider);
  return await service.fetchExperiences();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostspot_app/main.dart';
import 'package:hostspot_app/models/experience.dart';
import 'package:hostspot_app/providers/experience_provider.dart';
import 'package:hostspot_app/screens/experience_selection_screen.dart';
import 'package:hostspot_app/services/experience_service.dart';

// Create a mock ExperienceService
class MockExperienceService extends ExperienceService {
  @override
  Future<List<Experience>> fetchExperiences({String? apiUrl}) async {
    // Return a mock list of experiences
    return [
      Experience(id: '1', name: 'Test Experience 1', imageUrl: ''),
      Experience(id: '2', name: 'Test Experience 2', imageUrl: ''),
    ];
  }
}

void main() {
  testWidgets('ExperienceSelectionScreen has a title and message', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the experienceServiceProvider with the mock
          experienceServiceProvider.overrideWithValue(MockExperienceService()),
        ],
        child: const MyApp(),
      ),
    );

    // The first frame is a loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Re-render the widget after the mock future has completed
    await tester.pump();

    // The second frame should show the list of experiences
    expect(find.byType(ExperienceSelectionScreen), findsOneWidget);
    expect(find.text('Test Experience 1'), findsOneWidget);
    expect(find.text('Test Experience 2'), findsOneWidget);
  });
}

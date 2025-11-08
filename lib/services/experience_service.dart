import 'package:dio/dio.dart';
import '../models/experience.dart';

class ExperienceService {
  final Dio _dio = Dio();

  Future<List<Experience>> fetchExperiences({String? apiUrl}) async {
    try {
      final url =
          apiUrl ??
          'https://staging.chamberofsecrets.8club.co/v1/experiences?active=true';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle the API response structure
        if (data is Map && data.containsKey('data')) {
          final experiencesData = data['data'];
          if (experiencesData is Map &&
              experiencesData.containsKey('experiences')) {
            final List<dynamic> experiences = experiencesData['experiences'];
            return experiences
                .map((json) => Experience.fromJson(json))
                .toList();
          }
        }

        // Fallback: if response is directly a list
        if (data is List) {
          return data.map((json) => Experience.fromJson(json)).toList();
        }

        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load experiences');
      }
    } catch (e) {
      // Fallback to mock data if API call fails
      // ignore: avoid_print
      print('Error fetching experiences: $e');
      return _getMockExperiences();
    }
  }

  List<Experience> _getMockExperiences() {
    // Mock data matching the design from images
    return [
      Experience(
        id: '1',
        name: 'PARTY',
        imageUrl:
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
        iconUrl: null,
      ),
      Experience(
        id: '2',
        name: 'DINNER',
        imageUrl:
            'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400',
        iconUrl: null,
      ),
      Experience(
        id: '3',
        name: 'BRUNCH',
        imageUrl:
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
        iconUrl: null,
      ),
      Experience(
        id: '4',
        name: 'DRINKS',
        imageUrl:
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400',
        iconUrl: null,
      ),
    ];
  }
}

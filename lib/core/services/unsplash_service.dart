import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/unsplash_image.dart';

/// Service class for Unsplash API interactions
class UnsplashService {
  final Dio _dio;

  UnsplashService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: UnsplashConfig.baseUrl,
            headers: {
              'Authorization': 'Client-ID ${UnsplashConfig.accessKey}',
              'Accept-Version': 'v1',
            },
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  /// Search for photos by query
  /// Returns the first matching image or null if none found
  Future<UnsplashImage?> searchPhotos(String query) async {
    try {
      final response = await _dio.get(
        UnsplashConfig.searchPhotosEndpoint,
        queryParameters: {
          'query': query,
          'per_page': UnsplashConfig.defaultPerPage,
          'orientation': UnsplashConfig.defaultOrientation,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          return UnsplashImage.fromJson(results[0]);
        }
      }
      return null;
    } on DioException catch (e) {
      print('Error searching photos: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }

  /// Get a random photo by query
  /// Useful as a fallback when search returns no results
  Future<UnsplashImage?> getRandomPhoto(String query) async {
    try {
      final response = await _dio.get(
        UnsplashConfig.randomPhotoEndpoint,
        queryParameters: {
          'query': query,
          'orientation': UnsplashConfig.defaultOrientation,
        },
      );

      if (response.statusCode == 200) {
        return UnsplashImage.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Error getting random photo: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }

  /// Get image for a skill based on skill name and category
  /// Uses skill-aware keywords before random fallback for better relevance.
  Future<String?> getSkillImage(String skillName, String category) async {
    final queries = _buildSkillQueries(skillName, category);
    UnsplashImage? image;

    for (final query in queries) {
      image = await searchPhotos(query);
      if (image != null) break;
    }

    image ??= await getRandomPhoto('$skillName $category learning');

    return image?.regularUrl;
  }

  List<String> _buildSkillQueries(String skillName, String category) {
    final lowerSkill = skillName.toLowerCase();
    final lowerCategory = category.toLowerCase();
    final queries = <String>[
      '$skillName learning',
      '$skillName tutorial',
      '$skillName course',
      '$category education',
    ];

    if (lowerCategory.contains('language') ||
        lowerSkill.contains('english') ||
        lowerSkill.contains('spoken')) {
      queries.addAll([
        'english conversation classroom',
        'language learning speaking practice',
      ]);
    }
    if (lowerCategory.contains('programming') ||
        lowerSkill.contains('java') ||
        lowerSkill.contains('code')) {
      queries.addAll([
        'programming coding laptop',
        'software developer coding screen',
      ]);
    }
    if (lowerCategory.contains('design') || lowerSkill.contains('figma')) {
      queries.addAll([
        'ui ux design workspace',
        'graphic design creative desk',
      ]);
    }
    if (lowerCategory.contains('music') || lowerSkill.contains('flute')) {
      queries.addAll([
        'flute music lesson',
        'music practice instrument learning',
      ]);
    }

    return queries.toSet().toList();
  }
}

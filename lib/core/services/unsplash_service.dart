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
  /// First tries skill name, then falls back to category
  Future<String?> getSkillImage(String skillName, String category) async {
    // Try searching by skill name first
    UnsplashImage? image = await searchPhotos(skillName);

    // If no results, try category
    if (image == null) {
      image = await searchPhotos(category);
    }

    // If still no results, try random photo with category
    if (image == null) {
      image = await getRandomPhoto(category);
    }

    return image?.regularUrl;
  }
}

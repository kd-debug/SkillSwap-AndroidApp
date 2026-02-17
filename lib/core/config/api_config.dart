/// Configuration for Unsplash API
/// Contains API credentials and endpoints
class UnsplashConfig {
  // API Credentials
  static const String accessKey = 'rn3bfr-SUN8jb9j2_JEP7sLhEKYfn5fQ0JxhWBgLmCk';
  static const String secretKey = 'j4BxDgPPUTINfRw3UljwMk8v9jxCvN0RbHTs87HtEKE';

  // API Endpoints
  static const String baseUrl = 'https://api.unsplash.com';
  static const String searchPhotosEndpoint = '/search/photos';
  static const String randomPhotoEndpoint = '/photos/random';

  // API Parameters
  static const int defaultPerPage = 1; // We only need 1 image per skill
  static const String defaultOrientation = 'landscape';
}

/// Model class for Unsplash image data
class UnsplashImage {
  final String id;
  final String regularUrl;
  final String smallUrl;
  final String thumbUrl;
  final String photographerName;
  final String photographerUsername;
  final String? description;

  UnsplashImage({
    required this.id,
    required this.regularUrl,
    required this.smallUrl,
    required this.thumbUrl,
    required this.photographerName,
    required this.photographerUsername,
    this.description,
  });

  /// Create UnsplashImage from JSON response
  factory UnsplashImage.fromJson(Map<String, dynamic> json) {
    return UnsplashImage(
      id: json['id'] as String,
      regularUrl: json['urls']['regular'] as String,
      smallUrl: json['urls']['small'] as String,
      thumbUrl: json['urls']['thumb'] as String,
      photographerName: json['user']['name'] as String,
      photographerUsername: json['user']['username'] as String,
      description: json['description'] as String?,
    );
  }

  /// Convert UnsplashImage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'urls': {
        'regular': regularUrl,
        'small': smallUrl,
        'thumb': thumbUrl,
      },
      'user': {
        'name': photographerName,
        'username': photographerUsername,
      },
      'description': description,
    };
  }
}

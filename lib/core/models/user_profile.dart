class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final List<String> interests;
  final String? profileImageUrl;
  final String? profileImagePath;
  final double? latitude;
  final double? longitude;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.interests,
    this.profileImageUrl,
    this.profileImagePath,
    this.latitude,
    this.longitude,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      profileImageUrl: map['profileImageUrl'] as String?,
      profileImagePath: map['profileImagePath'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'interests': interests,
      'profileImageUrl': profileImageUrl,
      'profileImagePath': profileImagePath,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    List<String>? interests,
    String? profileImageUrl,
    String? profileImagePath,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

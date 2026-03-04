class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final List<String> interests;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.interests,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'interests': interests,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    List<String>? interests,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
    );
  }
}

class OfferedSkill {
  final String id;
  final String userId;
  final String userName;
  final String name;
  final String category;
  final String level;
  final String about;
  final List<String> learningPoints;
  final String? imageUrl;

  OfferedSkill({
    required this.id,
    required this.userId,
    required this.userName,
    required this.name,
    required this.category,
    required this.level,
    required this.about,
    required this.learningPoints,
    this.imageUrl,
  });

  factory OfferedSkill.fromMap(Map<String, dynamic> map, String id) {
    return OfferedSkill(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      level: map['level'] ?? '',
      about: map['about'] ?? '',
      learningPoints: List<String>.from(map['learningPoints'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'name': name,
      'category': category,
      'level': level,
      'about': about,
      'learningPoints': learningPoints,
      'imageUrl': imageUrl,
    };
  }
}

class WantedSkill {
  final String id;
  final String userId;
  final String name;
  final String level;
  final String remarks;
  final List<String> otherRelevantSkills;

  WantedSkill({
    required this.id,
    required this.userId,
    required this.name,
    required this.level,
    required this.remarks,
    required this.otherRelevantSkills,
  });

  factory WantedSkill.fromMap(Map<String, dynamic> map, String id) {
    return WantedSkill(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? '',
      remarks: map['remarks'] ?? '',
      otherRelevantSkills: List<String>.from(map['otherRelevantSkills'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'level': level,
      'remarks': remarks,
      'otherRelevantSkills': otherRelevantSkills,
    };
  }
}

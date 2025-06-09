import '../../domain/Entites/community.dart';

class CommunityModel extends Community {
  CommunityModel({
    required String id,
    required String name,
    required String description,
    required String category,
    required String iconUrl,
    String rulesPictureUrl = '',
    required int memberCount,
    required String createdBy,
    required bool isPrivate,
    required DateTime createdAt,
    List<String>? rules,
  }) : super(
          id: id,
          name: name,
          description: description,
          category: category,
          iconUrl: iconUrl,
          rulesPictureUrl: rulesPictureUrl,
          memberCount: memberCount,
          createdBy: createdBy,
          isPrivate: isPrivate,
          createdAt: createdAt,
          rules: rules ?? const [
            '1. Be respectful to others',
            '2. No spam or self-promotion',
            '3. Stay on topic',
            '4. No hate speech or harassment',
            '5. Follow the community guidelines'
          ],
        );

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    List<String> rulesList = [];
    if (json['rules'] != null) {
      rulesList = List<String>.from(json['rules']);
    } else {
      // Default rules
      rulesList = [
        '1. Be respectful to others',
        '2. No spam or self-promotion',
        '3. Stay on topic',
        '4. No hate speech or harassment',
        '5. Follow the community guidelines'
      ];
    }
    
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      rulesPictureUrl: json['rulesPictureUrl'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      createdBy: json['createdBy'] ?? '',
      isPrivate: json['isPrivate'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      rules: rulesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'iconUrl': iconUrl,
      'rulesPictureUrl': rulesPictureUrl,
      'memberCount': memberCount,
      'createdBy': createdBy,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'rules': rules,
    };
  }
} 
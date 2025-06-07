import '../../domain/Entites/community.dart';

class CommunityModel extends Community {
  CommunityModel({
    required String id,
    required String name,
    required String description,
    required String category,
    required String iconUrl,
    required int memberCount,
    required String createdBy,
    required bool isPrivate,
    required DateTime createdAt,
  }) : super(
          id: id,
          name: name,
          description: description,
          category: category,
          iconUrl: iconUrl,
          memberCount: memberCount,
          createdBy: createdBy,
          isPrivate: isPrivate,
          createdAt: createdAt,
        );

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      createdBy: json['createdBy'] ?? '',
      isPrivate: json['isPrivate'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'iconUrl': iconUrl,
      'memberCount': memberCount,
      'createdBy': createdBy,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 
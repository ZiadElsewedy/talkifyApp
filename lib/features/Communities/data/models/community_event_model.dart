import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/Entites/community_event.dart';

class CommunityEventModel extends CommunityEvent {
  CommunityEventModel({
    required String id,
    required String communityId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    required DateTime createdAt,
    required String location,
    required bool isOnline,
    required String meetingLink,
    required List<String> attendees,
  }) : super(
          id: id,
          communityId: communityId,
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          createdBy: createdBy,
          createdAt: createdAt,
          location: location,
          isOnline: isOnline,
          meetingLink: meetingLink,
          attendees: attendees,
        );

  factory CommunityEventModel.fromJson(Map<String, dynamic> json) {
    return CommunityEventModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['startDate'] != null
          ? (json['startDate'] is Timestamp 
              ? (json['startDate'] as Timestamp).toDate() 
              : json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] is Timestamp 
              ? (json['endDate'] as Timestamp).toDate() 
              : json['endDate'])
          : DateTime.now().add(const Duration(hours: 1)),
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : json['createdAt'])
          : DateTime.now(),
      location: json['location'] ?? '',
      isOnline: json['isOnline'] ?? false,
      meetingLink: json['meetingLink'] ?? '',
      attendees: json['attendees'] != null
          ? List<String>.from(json['attendees'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'isOnline': isOnline,
      'meetingLink': meetingLink,
      'attendees': attendees,
    };
  }
} 
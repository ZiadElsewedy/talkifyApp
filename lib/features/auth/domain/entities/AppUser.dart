import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String profilePictureUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.profilePictureUrl,
    this.isOnline = false,
    this.lastSeen,
  });
// convert app user to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
// convert json to app user
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null ? 
        (json['lastSeen'] is Timestamp ? 
          (json['lastSeen'] as Timestamp).toDate() : 
          DateTime.parse(json['lastSeen'].toString())) : 
        null,
    );
  }
  @override
  String toString() {
    return 'AppUser{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, profilePictureUrl: $profilePictureUrl, isOnline: $isOnline, lastSeen: $lastSeen}';
  }
}
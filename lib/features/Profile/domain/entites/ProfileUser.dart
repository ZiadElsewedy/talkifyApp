import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfileUser extends AppUser {
  // Constructor
  final String bio;
  final String backgroundprofilePictureUrl;

  ProfileUser({
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.profilePictureUrl,
    required this.bio,
    required this.backgroundprofilePictureUrl,
  });
// update the ProfileUser 
ProfileUser copywith ({
  String? newprofilePictureUrl,
  String? newBio,
  String? newName,
  String? newbackgroundprofilePictureUrl,
}) {
  return ProfileUser(
    id: id,
    name: newName ?? name,
    email: email,
    phoneNumber: phoneNumber,
    profilePictureUrl: newprofilePictureUrl ?? profilePictureUrl,
    bio: newBio ?? bio,
    backgroundprofilePictureUrl: newbackgroundprofilePictureUrl ?? backgroundprofilePictureUrl,
  );
}
// convert ProfileUser to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'backgroundprofilePictureUrl': backgroundprofilePictureUrl,
    };
  }
// convert json to ProfileUser
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] ?? '',
      profilePictureUrl: json['profilePictureUrl']  ?? '',
      bio: json['bio'] as String,
      backgroundprofilePictureUrl: json['backgroundprofilePictureUrl'] ?? '',
    );
  }
  @override
  String toString() {
    return 'ProfileUser{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, profilePictureUrl: $profilePictureUrl, bio: $bio}';
  }
}
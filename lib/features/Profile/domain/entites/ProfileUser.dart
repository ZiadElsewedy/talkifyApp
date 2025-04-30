import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfileUser extends AppUser {
  // Constructor
  final String bio;

  ProfileUser({
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.profilePictureUrl,
    required this.bio,
  });
// update the ProfileUser 
ProfileUser copywith ({
  String? newprofilePictureUrl,
  String? newBio,
}) {
  return ProfileUser(
    id: id,
    name: name,
    email: email,
    phoneNumber: phoneNumber,
    profilePictureUrl: newprofilePictureUrl ?? profilePictureUrl,
    bio: newBio ?? bio,
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
    };
  }
// convert json to ProfileUser
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String,
      bio: json['bio'] as String,
    );
  }
  @override
  String toString() {
    return 'ProfileUser{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, profilePictureUrl: $profilePictureUrl, bio: $bio}';
  }
}
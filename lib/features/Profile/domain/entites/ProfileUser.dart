import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfileUser extends AppUser {
  // Constructor
  final String bio;
  final String backgroundprofilePictureUrl;
  final String HintDescription;
  final List<String> followers;
  final List<String> following;

  ProfileUser({
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.profilePictureUrl,
    required this.bio,
    required this.backgroundprofilePictureUrl,
    required this.HintDescription,
    required this.followers,
    required this.following,  
  });
// update the ProfileUser 
ProfileUser copywith ({
  String? newprofilePictureUrl,
  String? newBio,
  String? newName,
  String? newbackgroundprofilePictureUrl,
  String? newHintDescription,
  List<String>? newfollowers,
  List<String>? newfollowing,
}) {
  return ProfileUser(
    id: id,
    name: newName ?? name,
    email: email,
    phoneNumber: phoneNumber,
    profilePictureUrl: newprofilePictureUrl ?? profilePictureUrl,
    bio: newBio ?? bio,
    backgroundprofilePictureUrl: newbackgroundprofilePictureUrl ?? backgroundprofilePictureUrl,
    HintDescription: newHintDescription ?? HintDescription,
    followers: newfollowers ?? followers,
    following: newfollowing ?? following,
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
      'HintDescription': HintDescription,
      'followers': followers,
      'following': following,
    };
  }
// convert json to ProfileUser
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      bio: json['bio'] ?? '',
      backgroundprofilePictureUrl: json['backgroundprofilePictureUrl'] ?? '',
      HintDescription: json['HintDescription'] ?? '',
      followers: (json['followers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      following: (json['following'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
  @override
  String toString() {
    return 'ProfileUser{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, profilePictureUrl: $profilePictureUrl, bio: $bio, HintDescription: $HintDescription, followers: $followers, following: $following}';
  }
}
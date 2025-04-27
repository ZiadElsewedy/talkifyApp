class AppUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String profilePictureUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.profilePictureUrl,
  });

  @override
  String toString() {
    return 'AppUser{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, profilePictureUrl: $profilePictureUrl}';
  }
}
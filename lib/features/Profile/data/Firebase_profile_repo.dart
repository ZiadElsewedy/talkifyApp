import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class FirebaseProfileRepo  implements ProfileRepo{
  @override
  Future<AppUser?> FetchUserProfile() {
    // TODO: implement FettchUserProfile
    throw UnimplementedError();
  }
  @override
  Future<void> updateUserProfile(AppUser UpdateProfile) {
    // TODO: implement updateUserProfile
    throw UnimplementedError();
  }
}
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

abstract class SearchRepo {
  Future<List<ProfileUser>> searchUsers(String query);
}


import 'package:talkifyapp/features/Search/Domain/SearchRepo.dart';
  import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseSearchRepo implements SearchRepo {
    @override
    Future<List<ProfileUser>> searchUsers(String query) async {
  try {
  final users = await FirebaseFirestore.instance.collection('users')
.where('username', isGreaterThanOrEqualTo: query)
 .where('username', isLessThanOrEqualTo: "$query\uFFFF")
 .get();

  return users.docs.map((doc) => ProfileUser.fromJson(doc.data())).toList();
} on Exception catch (e) {
  print("error in search users: $e");
  return [];
}
    }
}

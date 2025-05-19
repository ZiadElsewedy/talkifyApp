import 'package:talkifyapp/features/Search/Domain/SearchRepo.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSearchRepo implements SearchRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ProfileUser>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Search by name
      final QuerySnapshot nameQuerySnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      // Search by username if it exists
      final QuerySnapshot usernameQuerySnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      // Combine and deduplicate results
      final Set<String> processedIds = {};
      final List<ProfileUser> results = [];

      // Process name results
      for (var doc in nameQuerySnapshot.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          results.add(_createProfileUser(doc.id, data));
        }
      }

      // Process username results
      for (var doc in usernameQuerySnapshot.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          results.add(_createProfileUser(doc.id, data));
        }
      }

      return results;
    } on FirebaseException catch (e) {
      print("Firebase error in search users: $e");
      throw Exception('Failed to search users: ${e.message}');
    } catch (e) {
      print("Error in search users: $e");
      throw Exception('Failed to search users: $e');
    }
  }

  ProfileUser _createProfileUser(String id, Map<String, dynamic> data) {
    return ProfileUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      bio: data['bio'] ?? '',
      backgroundprofilePictureUrl: data['backgroundprofilePictureUrl'] ?? '',
      HintDescription: data['HintDescription'] ?? '',
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
    );
  }
}

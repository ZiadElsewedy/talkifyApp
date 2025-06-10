import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Notifcations/data/notification_service.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  @override
  Future<ProfileUser?> fetchUserProfile(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Cannot fetch profile: Empty user ID provided');
      }
      
      final userDoc = await firestore.collection('users').doc(id).get();
      
      if (!userDoc.exists) {
        throw Exception('User document not found for ID: $id');
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User document exists but data is null for ID: $id');
      }

      return ProfileUser.fromJson({
        'id': id,
        ...userData,
      });
    } catch (e, stackTrace) {
      print('Error fetching user profile for ID $id: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(ProfileUser updateProfile) async {
    try {
      if (updateProfile.id.isEmpty) {
        throw Exception('Cannot update profile: Empty user ID provided');
      }

      final userDoc = await firestore.collection('users').doc(updateProfile.id).get();
      if (!userDoc.exists) {
        throw Exception('User document not found for ID: ${updateProfile.id}');
      }

      // Use the toJson method from ProfileUser for consistency
      final userData = updateProfile.toJson();
      
      // Remove the ID field since it's the document ID
      userData.remove('id');
      
      await firestore.collection('users').doc(updateProfile.id).update(userData);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> ToggleFollow(String currentUserId, String otherUserId) async {
    try {
      // Validate inputs
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        throw Exception("User IDs cannot be empty");
      }

      // Prevent self-following
      if (currentUserId == otherUserId) {
        throw Exception("Users cannot follow themselves");
      }

      bool isFollowing = false;
      bool didFollow = false; // Track if we're following or unfollowing

      // Use a transaction to ensure atomic updates
      await firestore.runTransaction((transaction) async {
        // Get both user documents
        final currentUserDoc = await transaction.get(firestore.collection('users').doc(currentUserId));
        final otherUserDoc = await transaction.get(firestore.collection('users').doc(otherUserId));
        
        if (!currentUserDoc.exists || !otherUserDoc.exists) {
          throw Exception("One or both user documents not found");
        }

        // Get current following/followers lists
        final currentUserFollowing = List<String>.from(currentUserDoc.data()?['following'] ?? []);
        final otherUserFollowers = List<String>.from(otherUserDoc.data()?['followers'] ?? []);

        // Clean up any self-following that might exist
        currentUserFollowing.remove(currentUserId);
        otherUserFollowers.remove(otherUserId);

        // Determine if we're following or unfollowing
        isFollowing = currentUserFollowing.contains(otherUserId);

        if (isFollowing) {
          // Unfollow: Remove from both lists
          currentUserFollowing.remove(otherUserId);
          otherUserFollowers.remove(currentUserId);
          didFollow = false;
          
          // Remove the follow notification when unfollowing
          try {
            await _notificationService.removeFollowNotification(
              followerId: currentUserId,
              followedId: otherUserId
            );
          } catch (e) {
            print('Error removing follow notification: $e');
            // Continue with the unfollow operation even if notification removal fails
          }
        } else {
          // Follow: Add to both lists
          currentUserFollowing.add(otherUserId);
          otherUserFollowers.add(currentUserId);
          didFollow = true;
        }

        // Update both documents atomically
        transaction.update(firestore.collection('users').doc(currentUserId), {
          'following': currentUserFollowing,
        });

        transaction.update(firestore.collection('users').doc(otherUserId), {
          'followers': otherUserFollowers,
        });
      });

      // If we just followed the user (not unfollowed), create a notification
      if (didFollow) {
        // Get the user's name and profile picture
        final currentUserDoc = await firestore.collection('users').doc(currentUserId).get();
        if (currentUserDoc.exists) {
          final userData = currentUserDoc.data() as Map<String, dynamic>;
          final userName = userData['name'] as String? ?? 'User';
          final profilePicture = userData['profilePicture'] as String? ?? '';
          
          // Create follow notification
          await _notificationService.createFollowNotification(
            followedUserId: otherUserId,
            followerUserId: currentUserId,
            followerUserName: userName,
            followerProfilePic: profilePicture,
          );
        }
      }

      return didFollow; // Return true if now following, false if now unfollowing
    } catch (e, stackTrace) {
      print('Error toggling follow relationship: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<bool> isFollowing(String currentUserId, String otherUserId) async {
    try {
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        throw Exception("User IDs cannot be empty");
      }

      final userDoc = await firestore.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
      return followers.contains(currentUserId);
    } catch (e) {
      print('Error checking follow status: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<ProfileUser>> getMutualFriends(String userId1, String userId2) async {
    try {
      if (userId1.isEmpty || userId2.isEmpty) {
        throw Exception("User IDs cannot be empty");
      }
      
      // Fetch both users
      final user1Doc = await firestore.collection('users').doc(userId1).get();
      final user2Doc = await firestore.collection('users').doc(userId2).get();
      
      if (!user1Doc.exists || !user2Doc.exists) {
        throw Exception("One or both user documents not found");
      }
      
      // Get following lists for both users
      final user1Following = List<String>.from(user1Doc.data()?['following'] ?? []);
      final user2Following = List<String>.from(user2Doc.data()?['following'] ?? []);
      
      // Find common connections (mutual friends)
      final mutualFriendIds = user1Following.toSet().intersection(user2Following.toSet()).toList();
      
      // Fetch profile details for mutual friends
      final List<ProfileUser> mutualFriends = [];
      for (final friendId in mutualFriendIds) {
        final friendDoc = await firestore.collection('users').doc(friendId).get();
        if (friendDoc.exists && friendDoc.data() != null) {
          mutualFriends.add(ProfileUser.fromJson({
            'id': friendId,
            ...friendDoc.data()!,
          }));
        }
      }
      
      return mutualFriends;
    } catch (e) {
      print('Error getting mutual friends: $e');
      throw Exception('Failed to get mutual friends: $e');
    }
  }
  
  @override
  Future<List<ProfileUser>> getSuggestedUsers(String userId, {int limit = 5}) async {
    try {
      print("Starting getSuggestedUsers for userId: $userId with limit: $limit");
      if (userId.isEmpty) {
        throw Exception("User ID cannot be empty");
      }
      
      // Fetch the current user
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception("User document not found");
      }
      
      // Get user's following and followers
      final following = List<String>.from(userDoc.data()?['following'] ?? []);
      final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
      
      print("User is following ${following.length} people and has ${followers.length} followers");
      
      // Create a set of users to exclude (self, already following)
      final Set<String> excludeUsers = {userId, ...following};
      
      // First priority: Users followed by people the user follows (Instagram-like logic)
      final Set<String> suggestedUserIds = {};
      
      // Find users followed by people the user follows
      print("Looking for users followed by people the user follows...");
      for (final followedId in following) {
        final followedUserDoc = await firestore.collection('users').doc(followedId).get();
        if (followedUserDoc.exists) {
          final followedUserFollowing = List<String>.from(followedUserDoc.data()?['following'] ?? []);
          
          // Add users that the followed user follows, but the current user doesn't follow yet
          for (final suggestion in followedUserFollowing) {
            if (!excludeUsers.contains(suggestion)) {
              suggestedUserIds.add(suggestion);
            }
          }
        }
      }
      
      print("Found ${suggestedUserIds.length} suggestions from connections");
      
      // Second priority: Followers that the user doesn't follow back
      print("Looking for followers that the user doesn't follow back...");
      int followerSuggestions = 0;
      for (final followerId in followers) {
        if (!excludeUsers.contains(followerId)) {
          suggestedUserIds.add(followerId);
          followerSuggestions++;
        }
      }
      
      print("Found $followerSuggestions suggestions from followers not followed back");
      
      // Third priority: Popular users (users with many followers)
      if (suggestedUserIds.length < limit) {
        print("Looking for popular users...");
        // Get a batch of users the current user is not following
        final popularUsersQuery = await firestore.collection('users')
            .limit(20)  // Get a reasonable batch to analyze
            .get();
            
        print("Found ${popularUsersQuery.docs.length} total users to check for popularity");
            
        // Manually filter and sort by follower count
        final List<Map<String, dynamic>> popularUsers = [];
        
        for (final doc in popularUsersQuery.docs) {
          final id = doc.id;
          if (!excludeUsers.contains(id) && !suggestedUserIds.contains(id)) {
            final userData = doc.data();
            final followerCount = (userData['followers'] as List<dynamic>?)?.length ?? 0;
            
            popularUsers.add({
              'id': id,
              'data': userData,
              'followerCount': followerCount
            });
          }
        }
        
        print("Found ${popularUsers.length} potential popular users after filtering");
        
        // Sort by follower count
        popularUsers.sort((a, b) => (b['followerCount'] as int).compareTo(a['followerCount'] as int));
        
        // Add top users to suggestions
        int popularAdded = 0;
        for (final user in popularUsers) {
          if (suggestedUserIds.length >= limit) break;
          suggestedUserIds.add(user['id'] as String);
          popularAdded++;
        }
        
        print("Added $popularAdded popular users to suggestions");
      }
      
      // Even if we don't have suggestions, let's create at least one dummy suggestion
      if (suggestedUserIds.isEmpty) {
        print("No suggestions found, checking for any users to suggest");
        
        // Get ANY users that aren't the current user
        final anyUsersQuery = await firestore.collection('users')
            .limit(5)
            .get();
            
        for (final doc in anyUsersQuery.docs) {
          final id = doc.id;
          if (id != userId && !excludeUsers.contains(id)) {
            suggestedUserIds.add(id);
            print("Added fallback suggestion: $id");
          }
        }
        
        print("Added ${suggestedUserIds.length} random users as fallback suggestions");
      }
      
      print("Total suggestions before fetching details: ${suggestedUserIds.length}");
      
      // Fetch full profile details for suggested users
      final List<ProfileUser> suggestedUsers = [];
      
      // Limit the number of suggested users
      final limitedSuggestionIds = suggestedUserIds.take(limit).toList();
      
      for (final suggestedId in limitedSuggestionIds) {
        final suggestedUserDoc = await firestore.collection('users').doc(suggestedId).get();
        if (suggestedUserDoc.exists && suggestedUserDoc.data() != null) {
          suggestedUsers.add(ProfileUser.fromJson({
            'id': suggestedId,
            ...suggestedUserDoc.data()!,
          }));
        }
      }
      
      // BACKUP: If we still have no suggestions, add hardcoded test suggestions
      if (suggestedUsers.isEmpty) {
        print("Adding hardcoded test suggestions");
        
        // Hardcoded suggestion 1
        try {
          // Get a real user from the database to use as a suggestion (not the current user)
          final backupQuery = await firestore.collection('users').limit(3).get();
          for (final doc in backupQuery.docs) {
            if (doc.id != userId) {
              final data = doc.data();
              suggestedUsers.add(ProfileUser(
                id: doc.id,
                name: data['name'] as String? ?? 'User',
                email: data['email'] as String? ?? '',
                phoneNumber: data['phoneNumber'] as String? ?? '',
                profilePictureUrl: data['profilePictureUrl'] as String? ?? '',
                bio: data['bio'] as String? ?? '',
                backgroundprofilePictureUrl: data['backgroundprofilePictureUrl'] as String? ?? '',
                HintDescription: data['HintDescription'] as String? ?? '',
                followers: List<String>.from(data['followers'] ?? []),
                following: List<String>.from(data['following'] ?? []),
              ));
              
              print("Added hardcoded suggestion from database: ${doc.id}");
            }
          }
        } catch (e) {
          print("Error adding database test suggestions: $e");
        }
        
        // As a fallback, create completely fake suggestions if we couldn't get real ones
        if (suggestedUsers.isEmpty) {
          suggestedUsers.add(ProfileUser(
            id: 'test_user_1',
            name: 'Test User 1',
            email: 'test1@example.com',
            phoneNumber: '',
            profilePictureUrl: 'https://via.placeholder.com/150',
            bio: 'This is a test user',
            backgroundprofilePictureUrl: '',
            HintDescription: 'Test account',
            followers: [],
            following: [],
          ));
          
          suggestedUsers.add(ProfileUser(
            id: 'test_user_2',
            name: 'Test User 2',
            email: 'test2@example.com',
            phoneNumber: '',
            profilePictureUrl: 'https://via.placeholder.com/150',
            bio: 'Another test user',
            backgroundprofilePictureUrl: '',
            HintDescription: 'Test account 2',
            followers: [],
            following: [],
          ));
          
          print("Added completely fake hardcoded suggestions");
        }
      }
      
      print("Returning ${suggestedUsers.length} final suggested users");
      
      return suggestedUsers;
    } catch (e) {
      print('Error getting suggested users: $e');
      throw Exception('Failed to get suggested users: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/Entites/community.dart';
import '../../domain/Entites/community_message.dart';
import '../../domain/Entites/community_member.dart';
import '../../domain/Entites/community_event.dart';
import '../../domain/repo/community_repository.dart';
import '../models/community_model.dart';
import '../models/community_message_model.dart';
import '../models/community_member_model.dart';
import '../models/community_event_model.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Community operations
  @override
  Future<List<Community>> getCommunities() async {
    final querySnapshot = await _firestore.collection('communities').get();
    return querySnapshot.docs
        .map((doc) => CommunityModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  @override
  Future<List<Community>> getTrendingCommunities() async {
    final querySnapshot = await _firestore
        .collection('communities')
        .orderBy('memberCount', descending: true)
        .limit(10)
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommunityModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  @override
  Future<List<Community>> searchCommunities(String query) async {
    final querySnapshot = await _firestore
        .collection('communities')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommunityModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  @override
  Future<Community> getCommunityById(String id) async {
    final docSnapshot = await _firestore.collection('communities').doc(id).get();
    
    if (!docSnapshot.exists) {
      throw Exception('Community not found');
    }
    
    return CommunityModel.fromJson({
      'id': docSnapshot.id,
      ...docSnapshot.data()!,
    });
  }

  @override
  Future<Community> createCommunity(Community community) async {
    final communityMap = (community as CommunityModel).toJson();
    
    // Remove id as Firestore will generate one
    communityMap.remove('id');
    
    // Create the community document
    final docRef = await _firestore.collection('communities').add(communityMap);
    
    // Make the creator an admin of the community
    await _addCreatorAsAdmin(docRef.id, community.createdBy);
    
    // Get the newly created community
    final newCommunity = await getCommunityById(docRef.id);
    return newCommunity;
  }

  Future<void> _addCreatorAsAdmin(String communityId, String userId) async {
    // Get user data from users collection
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('User not found');
    }
    
    final userData = userDoc.data()!;
    
    final member = CommunityMemberModel(
      id: '', // Will be set by Firestore
      communityId: communityId,
      userId: userId,
      userName: userData['name'] ?? 'Anonymous',
      userAvatar: userData['profilePictureUrl'] ?? '',
      role: MemberRole.admin, // Make the creator an admin
      joinedAt: DateTime.now(),
    );
    
    final memberMap = member.toJson();
    memberMap.remove('id');
    
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .add(memberMap);
  }

  @override
  Future<void> updateCommunity(Community community) async {
    // Convert Community to CommunityModel if needed
    CommunityModel communityModel;
    if (community is CommunityModel) {
      communityModel = community;
    } else {
      communityModel = CommunityModel(
        id: community.id,
        name: community.name,
        description: community.description,
        category: community.category,
        iconUrl: community.iconUrl,
        rulesPictureUrl: community.rulesPictureUrl,
        memberCount: community.memberCount,
        createdBy: community.createdBy,
        isPrivate: community.isPrivate,
        createdAt: community.createdAt,
        rules: community.rules,
      );
    }
    
    final communityMap = communityModel.toJson();
    
    // Remove id from the map as it's used as the document ID
    communityMap.remove('id');
    
    print("REPOSITORY: Updating community ${community.id} with data: $communityMap");
    
    await _firestore
        .collection('communities')
        .doc(community.id)
        .update(communityMap);
  }

  @override
  Future<void> deleteCommunity(String id) async {
    await _firestore.collection('communities').doc(id).delete();
  }

  // Member operations
  @override
  Future<List<CommunityMember>> getCommunityMembers(String communityId) async {
    try {
      final querySnapshot = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .get();
      
      print("REPOSITORY: Found ${querySnapshot.docs.length} members in community $communityId");
      
      final List<CommunityMember> members = [];
      
      // Create a list of futures to fetch user data for members
      for (var doc in querySnapshot.docs) {
        final memberData = doc.data();
        final userId = memberData['userId'] as String;
        
        // Ensure we have user data
        if (userId != null && userId.isNotEmpty) {
          try {
            // Get latest user data from users collection
            final userDoc = await _firestore.collection('users').doc(userId).get();
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              
              // Create member with updated user data
              members.add(CommunityMemberModel.fromJson({
                'id': doc.id,
                'communityId': memberData['communityId'] ?? communityId,
                'userId': userId,
                // Use latest user data if available, fall back to stored data
                'userName': userData['name'] ?? memberData['userName'] ?? 'Unknown User',
                'userAvatar': userData['profilePictureUrl'] ?? memberData['userAvatar'] ?? '',
                'role': memberData['role'] ?? 'member',
                'joinedAt': memberData['joinedAt'] ?? DateTime.now().toIso8601String(),
              }));
              
              print("REPOSITORY: Added member ${userData['name']} (${userId}) with avatar: ${userData['profilePictureUrl'] ?? 'none'}");
            } else {
              // If user doc doesn't exist, use the stored data
              members.add(CommunityMemberModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }));
              print("REPOSITORY: User document not found for $userId, using stored member data");
            }
          } catch (e) {
            print("REPOSITORY: Error fetching user data for member $userId: $e");
            // If there's an error, still add the member with available data
            members.add(CommunityMemberModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }));
          }
        } else {
          // If userId is missing/invalid, use whatever data we have
          members.add(CommunityMemberModel.fromJson({
            'id': doc.id,
            ...doc.data(),
          }));
          print("REPOSITORY: Invalid userId in member document ${doc.id}");
        }
      }
      
      print("REPOSITORY: Returning ${members.length} members");
      return members;
    } catch (e) {
      print("REPOSITORY: Error in getCommunityMembers: $e");
      rethrow;
    }
  }

  @override
  Future<CommunityMember> joinCommunity(String communityId, String userId) async {
    // Get user data from users collection
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('User not found');
    }
    
    final userData = userDoc.data()!;
    
    final member = CommunityMemberModel(
      id: '', // Will be set by Firestore
      communityId: communityId,
      userId: userId,
      userName: userData['name'] ?? 'Anonymous',
      userAvatar: userData['profilePictureUrl'] ?? '',
      role: MemberRole.member,
      joinedAt: DateTime.now(),
    );
    
    final memberMap = member.toJson();
    memberMap.remove('id');
    
    final docRef = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .add(memberMap);
    
    // Update member count
    final communityDoc = await _firestore.collection('communities').doc(communityId).get();
    final currentCount = communityDoc.data()?['memberCount'] ?? 0;
    
    await _firestore
        .collection('communities')
        .doc(communityId)
        .update({'memberCount': currentCount + 1});
    
    return CommunityMemberModel.fromJson({
      'id': docRef.id,
      ...memberMap,
    });
  }

  @override
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      // Use a transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Find the member document
        final querySnapshot = await _firestore
            .collection('communities')
            .doc(communityId)
            .collection('members')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isEmpty) {
          throw Exception('User is not a member of this community');
        }
        
        final memberDoc = querySnapshot.docs.first;
        final communityRef = _firestore.collection('communities').doc(communityId);
        
        // Get current member count
        final communityDoc = await transaction.get(communityRef);
        final currentCount = communityDoc.data()?['memberCount'] ?? 0;
        
        // Delete the member document
        transaction.delete(memberDoc.reference);
        
        // Update member count if needed
        if (currentCount > 0) {
          transaction.update(communityRef, {'memberCount': currentCount - 1});
        }
      });
    } catch (e) {
      throw Exception('Failed to leave community: $e');
    }
  }

  @override
  Future<void> updateMemberRole(String communityId, String userId, MemberRole role) async {
    // Find the member document
    final querySnapshot = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('userId', isEqualTo: userId)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Member not found');
    }
    
    final memberDoc = querySnapshot.docs.first;
    
    // Get the latest user data to ensure profile pic is updated
    final userDoc = await _firestore.collection('users').doc(userId).get();
    String userAvatar = '';
    
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      userAvatar = userData['profilePictureUrl'] ?? '';
    }
    
    // Update the member role and profile picture
    await memberDoc.reference.update({
      'role': role.toString().split('.').last,
      'userAvatar': userAvatar,
    });
  }

  // Message operations
  @override
  Future<List<CommunityMessage>> getCommunityMessages(String communityId) async {
    final querySnapshot = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommunityMessageModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  @override
  Future<CommunityMessage> sendMessage(CommunityMessage message) async {
    final messageMap = (message as CommunityMessageModel).toJson();
    
    // Remove id as Firestore will generate one
    messageMap.remove('id');
    
    final docRef = await _firestore
        .collection('communities')
        .doc(message.communityId)
        .collection('messages')
        .add(messageMap);
    
    return CommunityMessageModel.fromJson({
      'id': docRef.id,
      ...messageMap,
    });
  }

  @override
  Future<void> pinMessage(String messageId, bool isPinned) async {
    // Need to find the community ID first
    final querySnapshot = await _firestore
        .collectionGroup('messages')
        .where(FieldPath.documentId, isEqualTo: messageId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Message not found');
    }
    
    final messagePath = querySnapshot.docs.first.reference.path;
    final pathParts = messagePath.split('/');
    
    if (pathParts.length < 4) {
      throw Exception('Invalid message path');
    }
    
    final communityId = pathParts[pathParts.length - 3];
    
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': isPinned});
  }

  @override
  Future<List<CommunityMessage>> getPinnedMessages(String communityId) async {
    final querySnapshot = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .where('isPinned', isEqualTo: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommunityMessageModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  // Event operations
  @override
  Future<List<CommunityEvent>> getCommunityEvents(String communityId) async {
    final querySnapshot = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('events')
        .orderBy('startDate', descending: false)
        .where('startDate', isGreaterThanOrEqualTo: DateTime.now())
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommunityEventModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  @override
  Future<CommunityEvent> createEvent(CommunityEvent event) async {
    final eventMap = (event as CommunityEventModel).toJson();
    
    // Remove id as Firestore will generate one
    eventMap.remove('id');
    
    // Make sure we store the communityId as a field in the event document
    // This will help us locate events in the future without complex queries
    if (!eventMap.containsKey('communityId')) {
      eventMap['communityId'] = event.communityId;
      print("OPTIMIZE: Added communityId to event for easier retrieval");
    }
    
    final docRef = await _firestore
        .collection('communities')
        .doc(event.communityId)
        .collection('events')
        .add(eventMap);
    
    return CommunityEventModel.fromJson({
      'id': docRef.id,
      ...eventMap,
    });
  }

  @override
  Future<void> updateEvent(CommunityEvent event) async {
    final eventMap = (event as CommunityEventModel).toJson();
    
    // Remove id from the map as it's used as the document ID
    eventMap.remove('id');
    
    await _firestore
        .collection('communities')
        .doc(event.communityId)
        .collection('events')
        .doc(event.id)
        .update(eventMap);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      print("FIXED-V2: Deleting event $eventId");
      
      // Using the same approach as our fixed join/leave event methods
      // Instead of using collection group queries with FieldPath.documentId which causes errors
      
      // Step 1: Get all communities
      final communitiesSnapshot = await _firestore.collection('communities').get();
      
      // Step 2: Search for the event in each community
      bool eventFound = false;
      for (final communityDoc in communitiesSnapshot.docs) {
        try {
          // Try to get the event directly
          final eventRef = _firestore
              .collection('communities')
              .doc(communityDoc.id)
              .collection('events')
              .doc(eventId);
              
          final eventDoc = await eventRef.get();
          
          // If we found the event
          if (eventDoc.exists) {
            print("FIXED-V2: Found event to delete in community ${communityDoc.id}");
            eventFound = true;
            
            // Delete the event document directly
            await eventRef.delete();
            
            print("FIXED-V2: Successfully deleted event");
            break;
          }
        } catch (e) {
          print("FIXED-V2: Error checking community ${communityDoc.id}: $e");
          // Continue to next community
        }
      }
      
      if (!eventFound) {
        throw Exception('Event not found in any community');
      }
      
    } catch (e) {
      print("FIXED-V2: Error deleting event: $e");
      throw Exception('Failed to delete event. Please try again.');
    }
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      print("FIXED-V2: Joining event $eventId for user $userId");
      
      // COMPLETELY DIFFERENT APPROACH:
      // Instead of using collection group queries with FieldPath.documentId which is causing errors,
      // we'll query for all communities and then look for the event directly
      
      // Step 1: Get all communities
      final communitiesSnapshot = await _firestore.collection('communities').get();
      
      // Step 2: Search for the event in each community
      bool eventFound = false;
      for (final communityDoc in communitiesSnapshot.docs) {
        try {
          // Try to get the event directly without any complex queries
          final eventRef = _firestore
              .collection('communities')
              .doc(communityDoc.id)
              .collection('events')
              .doc(eventId);
              
          final eventDoc = await eventRef.get();
          
          // If we found the event
          if (eventDoc.exists) {
            print("FIXED-V2: Found event in community ${communityDoc.id}");
            eventFound = true;
            
            // Get current attendees
            Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
            List<String> attendees = [];
            
            if (data.containsKey('attendees') && data['attendees'] != null) {
              attendees = List<String>.from(data['attendees']);
            }
            
            // Add user if not already attending
            if (!attendees.contains(userId)) {
              attendees.add(userId);
            }
            
            // Update the event document directly
            await eventRef.update({
              'attendees': attendees
            });
            
            print("FIXED-V2: Successfully joined event");
            break;
          }
        } catch (e) {
          print("FIXED-V2: Error checking community ${communityDoc.id}: $e");
          // Continue to next community
        }
      }
      
      if (!eventFound) {
        throw Exception('Event not found in any community');
      }
      
    } catch (e) {
      print("FIXED-V2: Error joining event: $e");
      // Create a more user-friendly error message
      throw Exception('Failed to join event. Please try again.');
    }
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      print("FIXED-V2: Leaving event $eventId for user $userId");
      
      // COMPLETELY DIFFERENT APPROACH:
      // Instead of using collection group queries with FieldPath.documentId which is causing errors,
      // we'll query for all communities and then look for the event directly
      
      // Step 1: Get all communities
      final communitiesSnapshot = await _firestore.collection('communities').get();
      
      // Step 2: Search for the event in each community
      bool eventFound = false;
      for (final communityDoc in communitiesSnapshot.docs) {
        try {
          // Try to get the event directly without any complex queries
          final eventRef = _firestore
              .collection('communities')
              .doc(communityDoc.id)
              .collection('events')
              .doc(eventId);
              
          final eventDoc = await eventRef.get();
          
          // If we found the event
          if (eventDoc.exists) {
            print("FIXED-V2: Found event in community ${communityDoc.id}");
            eventFound = true;
            
            // Get current attendees
            Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
            List<String> attendees = [];
            
            if (data.containsKey('attendees') && data['attendees'] != null) {
              attendees = List<String>.from(data['attendees']);
            }
            
            // Remove user if already attending
            if (attendees.contains(userId)) {
              attendees.remove(userId);
            }
            
            // Update the event document directly
            await eventRef.update({
              'attendees': attendees
            });
            
            print("FIXED-V2: Successfully left event");
            break;
          }
        } catch (e) {
          print("FIXED-V2: Error checking community ${communityDoc.id}: $e");
          // Continue to next community
        }
      }
      
      if (!eventFound) {
        throw Exception('Event not found in any community');
      }
      
    } catch (e) {
      print("FIXED-V2: Error leaving event: $e");
      // Create a more user-friendly error message
      throw Exception('Failed to leave event. Please try again.');
    }
  }
} 
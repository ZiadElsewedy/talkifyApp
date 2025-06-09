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
        memberCount: community.memberCount,
        createdBy: community.createdBy,
        isPrivate: community.isPrivate,
        createdAt: community.createdAt,
      );
    }
    
    final communityMap = communityModel.toJson();
    
    // Remove id from the map as it's used as the document ID
    communityMap.remove('id');
    
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
    final querySnapshot = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommunityMemberModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
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
      userAvatar: userData['avatar'] ?? '',
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
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('User is not a member of this community');
    }
    
    // Update the role
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(querySnapshot.docs.first.id)
        .update({'role': role.toString().split('.').last});
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
    // Need to find the community ID first
    final querySnapshot = await _firestore
        .collectionGroup('events')
        .where(FieldPath.documentId, isEqualTo: eventId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Event not found');
    }
    
    final eventPath = querySnapshot.docs.first.reference.path;
    final pathParts = eventPath.split('/');
    
    if (pathParts.length < 4) {
      throw Exception('Invalid event path');
    }
    
    final communityId = pathParts[pathParts.length - 3];
    
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    // Need to find the community ID first
    final querySnapshot = await _firestore
        .collectionGroup('events')
        .where(FieldPath.documentId, isEqualTo: eventId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Event not found');
    }
    
    final eventDoc = querySnapshot.docs.first;
    final eventPath = eventDoc.reference.path;
    final pathParts = eventPath.split('/');
    
    if (pathParts.length < 4) {
      throw Exception('Invalid event path');
    }
    
    final communityId = pathParts[pathParts.length - 3];
    
    // Get current attendees
    final event = CommunityEventModel.fromJson({
      'id': eventDoc.id,
      ...eventDoc.data(),
    });
    
    // Add user to attendees if not already in the list
    if (!event.attendees.contains(userId)) {
      List<String> updatedAttendees = List.from(event.attendees)..add(userId);
      
      await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('events')
          .doc(eventId)
          .update({'attendees': updatedAttendees});
    }
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    // Need to find the community ID first
    final querySnapshot = await _firestore
        .collectionGroup('events')
        .where(FieldPath.documentId, isEqualTo: eventId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Event not found');
    }
    
    final eventDoc = querySnapshot.docs.first;
    final eventPath = eventDoc.reference.path;
    final pathParts = eventPath.split('/');
    
    if (pathParts.length < 4) {
      throw Exception('Invalid event path');
    }
    
    final communityId = pathParts[pathParts.length - 3];
    
    // Get current attendees
    final event = CommunityEventModel.fromJson({
      'id': eventDoc.id,
      ...eventDoc.data(),
    });
    
    // Remove user from attendees if in the list
    if (event.attendees.contains(userId)) {
      List<String> updatedAttendees = List.from(event.attendees)..remove(userId);
      
      await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('events')
          .doc(eventId)
          .update({'attendees': updatedAttendees});
    }
  }
} 
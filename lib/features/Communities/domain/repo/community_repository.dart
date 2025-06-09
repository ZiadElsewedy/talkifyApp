import '../Entites/community.dart';
import '../Entites/community_message.dart';
import '../Entites/community_member.dart';
import '../Entites/community_event.dart';

abstract class CommunityRepository {
  // Community operations
  Future<List<Community>> getCommunities();
  Future<List<Community>> getTrendingCommunities();
  Future<List<Community>> searchCommunities(String query);
  Future<Community> getCommunityById(String id);
  Future<Community> createCommunity(Community community);
  Future<void> updateCommunity(Community community);
  Future<void> deleteCommunity(String id);
  
  // Member operations
  Future<List<CommunityMember>> getCommunityMembers(String communityId);
  Future<CommunityMember> joinCommunity(String communityId, String userId);
  Future<void> leaveCommunity(String communityId, String userId);
  Future<void> updateMemberRole(String communityId, String userId, MemberRole role);
  
  // Message operations
  Future<List<CommunityMessage>> getCommunityMessages(String communityId);
  Future<CommunityMessage> sendMessage(CommunityMessage message);
  Future<void> pinMessage(String messageId, bool isPinned);
  Future<List<CommunityMessage>> getPinnedMessages(String communityId);
  
  // Event operations
  Future<List<CommunityEvent>> getCommunityEvents(String communityId);
  Future<CommunityEvent> createEvent(CommunityEvent event);
  Future<void> updateEvent(CommunityEvent event);
  Future<void> deleteEvent(String eventId);
  Future<void> joinEvent(String eventId, String userId);
  Future<void> leaveEvent(String eventId, String userId);
} 
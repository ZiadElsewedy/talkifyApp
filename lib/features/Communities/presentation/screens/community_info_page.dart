import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community_member.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_state.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_member_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_member_state.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';

class CommunityInfoPage extends StatefulWidget {
  final ChatRoom chatRoom;
  final String communityId;
  final String? communityName;

  const CommunityInfoPage({
    Key? key,
    required this.chatRoom,
    required this.communityId,
    this.communityName,
  }) : super(key: key);

  @override
  State<CommunityInfoPage> createState() => _CommunityInfoPageState();
}

class _CommunityInfoPageState extends State<CommunityInfoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Message> _mediaMessages = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMediaMessages();
    _loadCommunityMembers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadMediaMessages() {
    // Get messages that are of type image or video
    context.read<ChatCubit>().loadMessages(widget.chatRoom.id);
  }
  
  void _loadCommunityMembers() {
    // Load members using the community member cubit
    context.read<CommunityMemberCubit>().getCommunityMembers(widget.communityId);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Info'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Members'),
            Tab(text: 'Media'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(),
          _buildMembersTab(),
          _buildMediaTab(),
        ],
      ),
    );
  }
  
  Widget _buildAboutTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<CommunityCubit, CommunityState>(
      builder: (context, state) {
        if (state is CommunityDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is CommunityDetailLoaded) {
          final community = state.community;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Community Image
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      image: community.iconUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(community.iconUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: community.iconUrl.isEmpty
                        ? Icon(
                            Icons.people,
                            size: 60,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Community Name
                Center(
                  child: Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Community Description
                Center(
                  child: Text(
                    community.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Community Info
                _infoItem('Created', _formatDate(community.createdAt), Icons.calendar_today),
                _infoItem('Members', '${community.memberCount}', Icons.people),
                _infoItem('Category', community.category, Icons.category),
                _infoItem(
                  'Privacy', 
                  community.isPrivate ? 'Private' : 'Public',
                  community.isPrivate ? Icons.lock : Icons.public,
                ),
                
                const SizedBox(height: 32),
                
                // Community Rules
                const Text(
                  'Community Rules',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _ruleItem('1. Be respectful to others'),
                _ruleItem('2. No spam or self-promotion'),
                _ruleItem('3. Stay on topic'),
                _ruleItem('4. No hate speech or harassment'),
                _ruleItem('5. Follow the community guidelines'),
              ],
            ),
          );
        }
        
        // Default loading state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
  
  Widget _buildMembersTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CommunityMemberCubit, CommunityMemberState>(
      builder: (context, state) {
        if (state is CommunityMembersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is CommunityMemberError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading members: ${state.message}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDarkMode ? Colors.red[300] : Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadCommunityMembers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (state is CommunityMembersLoaded) {
          final members = state.members;
          
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members found',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Sort members: admins first, then by name
          final sortedMembers = [...members];
          sortedMembers.sort((a, b) {
            // Sort by role first (admins before regular members)
            if (a.role == MemberRole.admin && b.role != MemberRole.admin) {
              return -1;
            }
            if (a.role != MemberRole.admin && b.role == MemberRole.admin) {
              return 1;
            }
            // Then sort by name
            return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
          });
          
          // Debug profile image URLs
          for (var member in sortedMembers) {
            print("Member ${member.userName} avatar URL: '${member.userAvatar}'");
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedMembers.length,
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              final bool isAdmin = member.role == MemberRole.admin;
              final bool isModerator = member.role == MemberRole.moderator;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 0.5,
                color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: GestureDetector(
                    onTap: () => _navigateToUserProfile(member.userId, member.userName),
                    child: _buildProfileAvatar(member, isDarkMode),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isModerator)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Mod',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      member.joinedAt != null 
                          ? 'Joined ${_formatDate(member.joinedAt)}'
                          : 'Member',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                  onTap: () => _navigateToUserProfile(member.userId, member.userName),
                ),
              );
            },
          );
        }
        
        // Default case - loading
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
  
  Widget _buildProfileAvatar(CommunityMember member, bool isDarkMode) {
    final hasAvatar = member.userAvatar.isNotEmpty;
    final firstLetter = member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?';
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      child: hasAvatar
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: member.userAvatar,
                placeholder: (context, url) => Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                errorWidget: (context, url, error) {
                  print("Error loading avatar for ${member.userName}: $error");
                  return Text(
                    firstLetter,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  );
                },
                fit: BoxFit.cover,
                width: 48,
                height: 48,
              ),
            )
          : Text(
              firstLetter,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
  
  void _navigateToUserProfile(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }
  
  Widget _buildMediaTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is MessagesLoaded) {
          // Filter for image and video messages
          final mediaMessages = state.messages.where((msg) => 
            msg.type == MessageType.image || msg.type == MessageType.video).toList();
          
          if (mediaMessages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No media shared yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mediaMessages.length,
            itemBuilder: (context, index) {
              final message = mediaMessages[index];
              
              if (message.type == MessageType.image) {
                return GestureDetector(
                  onTap: () {
                    // Open image preview
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: message.fileUrl ?? '',
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: message.fileUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              } else if (message.type == MessageType.video) {
                return GestureDetector(
                  onTap: () {
                    // Open video player
                    if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme: const IconThemeData(color: Colors.white),
                            ),
                            body: Center(
                              child: Text(
                                'Video player not implemented',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.video_library,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Container(); // Fallback
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      },
    );
  }
    
  Widget _infoItem(String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _ruleItem(String rule) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
} 
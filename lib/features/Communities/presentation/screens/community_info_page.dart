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
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_state.dart';

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
  late Future<List<AppUser>> _membersFuture;
  late List<Message> _mediaMessages = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _membersFuture = _fetchCommunityMembers();
    _loadMediaMessages();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<List<AppUser>> _fetchCommunityMembers() async {
    List<AppUser> members = [];
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('id', whereIn: widget.chatRoom.participants)
          .get();
          
      for (final doc in query.docs) {
        if (doc.data() != null) {
          members.add(AppUser.fromJson(doc.data()));
        }
      }
      
      return members;
    } catch (e) {
      print('Error fetching community members: $e');
      return [];
    }
  }
  
  void _loadMediaMessages() {
    // Get messages that are of type image or video
    context.read<ChatCubit>().loadMessages(widget.chatRoom.id);
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
        
        // Load community details if not already loaded
        context.read<CommunityCubit>().getCommunityById(widget.communityId);
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
  
  Widget _buildMembersTab() {
    return FutureBuilder<List<AppUser>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(child: Text('No members found'));
        }
        
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: member.profilePictureUrl.isNotEmpty
                    ? CachedNetworkImageProvider(member.profilePictureUrl)
                    : null,
                child: member.profilePictureUrl.isEmpty
                    ? Text(member.name[0].toUpperCase())
                    : null,
              ),
              title: Text(member.name),
              subtitle: Text(member.email),
            );
          },
        );
      },
    );
  }
  
  Widget _buildMediaTab() {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is MessagesLoaded) {
          // Filter for media messages (images and videos)
          final mediaMessages = state.messages.where((msg) => 
            msg.type == MessageType.image || msg.type == MessageType.video).toList();
          
          if (mediaMessages.isEmpty) {
            return const Center(child: Text('No media shared yet'));
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
              if (message.type == MessageType.image && message.fileUrl != null) {
                return GestureDetector(
                  onTap: () {
                    // Show full screen image
                    _showFullScreenImage(context, message);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: message.fileUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              } else if (message.type == MessageType.video && message.fileUrl != null) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to video player
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.videocam,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          );
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
  
  void _showFullScreenImage(BuildContext context, Message message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: message.fileUrl!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _infoItem(String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _ruleItem(String rule) {
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 
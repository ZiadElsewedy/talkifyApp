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
import 'package:talkifyapp/features/Communities/presentation/screens/community_events_page.dart';

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
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _membersFuture = _fetchCommunityMembers();
    _loadMediaMessages();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<List<AppUser>> _fetchCommunityMembers() async {
    setState(() {
      _isLoading = true;
    });
    
    List<AppUser> members = [];
    
    try {
      // Get the current user first to ensure they're included
      final currentUser = context.read<AuthCubit>().GetCurrentUser();
      
      // Get all users from community members collection first
      final communityMembersQuery = await FirebaseFirestore.instance
          .collection('communityMembers')
          .where('communityId', isEqualTo: widget.communityId)
          .get();
      
      // Extract all user IDs from community members
      final userIds = communityMembersQuery.docs.map((doc) => doc.data()['userId'] as String).toList();
      
      // If chat room participants are not in userIds, add them
      for (final participant in widget.chatRoom.participants) {
        if (!userIds.contains(participant)) {
          userIds.add(participant);
        }
      }
      
      // If still no users, add current user and chat room participants
      if (userIds.isEmpty) {
        // Add all chat room participants
        userIds.addAll(widget.chatRoom.participants);
        
        // Add current user if not already included
        if (currentUser != null && !userIds.contains(currentUser.id)) {
          userIds.add(currentUser.id);
        }
      }
      
      print("DEBUG: Found ${userIds.length} member IDs for community ${widget.communityId}");
      
      // Ensure unique user IDs
      final uniqueUserIds = userIds.toSet().toList();
      
      // If there are user IDs, fetch their details
      if (uniqueUserIds.isNotEmpty) {
        // Handle case where there might be more than 10 members (Firestore limit)
        for (int i = 0; i < uniqueUserIds.length; i += 10) {
          final batch = uniqueUserIds.skip(i).take(10).toList();
          
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('id', whereIn: batch)
              .get();
              
          for (final doc in query.docs) {
            if (doc.data() != null) {
              members.add(AppUser.fromJson(doc.data()));
            }
          }
        }
      }
      
      // If the current user isn't in the members list, add them
      if (currentUser != null && !members.any((member) => member.id == currentUser.id)) {
        members.add(currentUser);
      }
      
      // Sort members to show current user first
      if (currentUser != null) {
        members.sort((a, b) {
          if (a.id == currentUser.id) return -1;
          if (b.id == currentUser.id) return 1;
          return a.name.compareTo(b.name);
        });
      }
      
      setState(() {
        _isLoading = false;
      });
      
      return members;
    } catch (e) {
      print('Error fetching community members: $e');
      
      // As a fallback, add at least the current user
      final currentUser = context.read<AuthCubit>().GetCurrentUser();
      if (currentUser != null) {
        members.add(currentUser);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      return members;
    }
  }
  
  void _loadMediaMessages() {
    // Get messages that are of type image or video
    context.read<ChatCubit>().loadMessages(widget.chatRoom.id);
  }
  
  void _refreshMembers() {
    setState(() {
      _membersFuture = _fetchCommunityMembers();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Info'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMembers,
            tooltip: 'Refresh members',
          ),
          // Add prominent Events button in the app bar
          TextButton.icon(
            icon: const Icon(Icons.event),
            label: const Text('Events'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityEventsPage(
                    communityId: widget.communityId,
                    communityName: widget.communityName ?? 'Community',
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Members'),
            Tab(text: 'Media'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(),
          _buildMembersTab(),
          _buildMediaTab(),
          _buildEventsTab(),
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
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : FutureBuilder<List<AppUser>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshMembers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            final members = snapshot.data ?? [];
            if (members.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No members found'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshMembers,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        '${members.length} members', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        onPressed: _refreshMembers,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isCurrentUser = currentUser != null && member.id == currentUser.id;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.profilePictureUrl.isNotEmpty
                                ? CachedNetworkImageProvider(member.profilePictureUrl) as ImageProvider
                                : null,
                            backgroundColor: isCurrentUser 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                            child: member.profilePictureUrl.isEmpty
                                ? Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isCurrentUser)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            isCurrentUser ? '${member.email} (Online)' : member.email,
                            style: TextStyle(
                              color: isCurrentUser ? Colors.green : null,
                            ),
                          ),
                          trailing: isCurrentUser
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
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
  
  // Add a new tab for events
  Widget _buildEventsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Community Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan and join events with your community',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.event),
            label: const Text('View Community Events'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityEventsPage(
                    communityId: widget.communityId,
                    communityName: widget.communityName ?? 'Community',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 
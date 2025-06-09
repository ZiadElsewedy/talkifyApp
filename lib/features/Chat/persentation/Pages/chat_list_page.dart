import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/communities_tab.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/chat_room_tile.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/new_chat_page.dart';
import 'package:talkifyapp/features/Posts/presentation/HomePage.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/Utils/page_transitions.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/create_community_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with TickerProviderStateMixin {
  // Keep a local list of chat rooms
  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> _filteredChatRooms = [];
  late AnimationController _fadeInController;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // Tab controller for Chats and Communities
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeInController.forward();
    _tabController = TabController(length: 2, vsync: this);
    _loadChatRooms();
  }
  
  @override
  void dispose() {
    _fadeInController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadChatRooms();
  }

  void _loadChatRooms() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null) {
      print("ChatListPage: Loading chat rooms for user ${currentUser.id}");
      context.read<ChatCubit>().loadUserChatRooms(currentUser.id);
    }
  }

  // Filter out community chat rooms from the main chats list
  List<ChatRoom> _filterNonCommunityChatRooms(List<ChatRoom> chatRooms) {
    return chatRooms.where((chatRoom) {
      // Check if this is a community chat room
      // A community chat room will have a communityId field
      try {
        final Map<String, dynamic> chatRoomData = chatRoom.toJson();
        return !chatRoomData.containsKey('communityId') || chatRoomData['communityId'] == null;
      } catch (e) {
        // If there's an error, include the chat room by default
        return true;
      }
    }).toList();
  }

  void _filterChatRooms(String query) {
    setState(() {
      if (query.isEmpty) {
        // Apply the community filter here too
        _filteredChatRooms = _filterNonCommunityChatRooms(_chatRooms);
      } else {
        _filteredChatRooms = _filterNonCommunityChatRooms(_chatRooms).where((chatRoom) {
          // Search in chat name (group name or participant name)
          String chatName = '';
          if (chatRoom.isGroupChat) {
            // For group chats, use the first participant's name as a fallback
            // Since there's no explicit "groupName" field in the model
            chatName = chatRoom.participants.length > 2 
                ? "Group: ${chatRoom.participantNames.values.join(", ").substring(0, 
                    min(chatRoom.participantNames.values.join(", ").length, 20))}..."
                : "";
          } else {
            // For direct chats, find the other participant's name
            final currentUserName = context.read<AuthCubit>().GetCurrentUser()?.name ?? '';
            chatName = chatRoom.participantNames.entries
                .where((entry) => entry.value != currentUserName)
                .map((entry) => entry.value)
                .join(", ");
          }
          
          // Search in last message
          final String lastMessageContent = chatRoom.lastMessage ?? '';
          
          return chatName.toLowerCase().contains(query.toLowerCase()) ||
                 lastMessageContent.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      onChanged: _filterChatRooms,
                      autofocus: true,
                    )
                  : Text(
          'Conversations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
              ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterChatRooms('');
                }
              });
            },
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
          ),
                PopupMenuButton<String>(
                  icon: Icon(
                Icons.more_vert, 
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  onSelected: (value) {
                    if (value == 'new_chat') {
                      Navigator.push(
                        context,
                        PageTransitions.slideRightTransition(
                          page: const NewChatPage(),
            ),
                      ).then((_) {
                        // Reload chat rooms when returning from new chat
                        if (mounted) _loadChatRooms();
                      });
                    } else if (value == 'new_community') {
                      Navigator.push(
                        context,
                        PageTransitions.slideRightTransition(
                          page: const CreateCommunityPage(),
            ),
                      );
                    }
                  },
            itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'new_chat',
                child: Row(
                  children: [
                          Icon(Icons.chat_bubble_outline),
                          SizedBox(width: 8),
                          Text('New Chat'),
                  ],
                ),
              ),
                    const PopupMenuItem<String>(
                      value: 'new_community',
                child: Row(
                  children: [
                          Icon(Icons.group_add),
                          SizedBox(width: 8),
                          Text('New Community'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              floating: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
          controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.inversePrimary,
                  unselectedLabelColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                  indicatorColor: Theme.of(context).colorScheme.inversePrimary,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Communities'),
          ],
        ),
      ),
              pinned: true,
            ),
          ];
        },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chats Tab
            SafeArea(
              child: Column(
            children: [
              Expanded(
                  child: BlocConsumer<ChatCubit, ChatState>(
                    listener: (context, state) {
                      if (state is ChatRoomsLoaded) {
                        setState(() {
                            // Filter out community chat rooms from the main list
                            _chatRooms = _filterNonCommunityChatRooms(state.chatRooms);
                            _filteredChatRooms = _chatRooms;
                        });
                      }
                    },
                    builder: (context, state) {
                        if (state is ChatRoomsLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                        );
                        } else if (state is ChatRoomsLoaded && _filteredChatRooms.isEmpty) {
                          // No chats yet
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 70,
                                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No conversations yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start chatting with friends',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageTransitions.slideRightTransition(
                                        page: const NewChatPage(),
                                      ),
                                    ).then((_) {
                                      // Reload chat rooms when returning from new chat
                                      if (mounted) _loadChatRooms();
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Start a Chat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                                    foregroundColor: Theme.of(context).colorScheme.surface,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is ChatError) {
                          return Center(
                            child: Text(
                              'Error: ${state.message}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          );
                      }

                        // Display chat rooms
                      return FadeTransition(
                        opacity: _fadeInController,
                        child: ListView.builder(
                          itemCount: _filteredChatRooms.length,
                          itemBuilder: (context, index) {
                            final chatRoom = _filteredChatRooms[index];
                            return ChatRoomTile(
                              chatRoom: chatRoom,
                              currentUserId: currentUser?.id ?? '',
                              index: index,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageTransitions.slideRightTransition(
                                    page: ChatRoomPage(
                                      chatRoom: chatRoom,
                                    ),
                                  ),
                                ).then((_) {
                                  // Reload chat rooms when returning from chat
                                  if (mounted) _loadChatRooms();
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                ],
              ),
          ),
          
          // Communities Tab
          const CommunitiesTab(),
        ],
      ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              heroTag: 'newChatFAB',
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransitions.slideRightTransition(
                    page: const NewChatPage(),
                  ),
                ).then((_) {
                  // Reload chat rooms when returning from new chat
                  if (mounted) _loadChatRooms();
                });
              },
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              child: const Icon(Icons.chat),
            )
          : FloatingActionButton(
              heroTag: 'createCommunityFAB',
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransitions.slideRightTransition(
                    page: const CreateCommunityPage(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              child: const Icon(Icons.group_add),
            ),
    );
  }
}

// Implement the missing _SliverAppBarDelegate class
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
} 
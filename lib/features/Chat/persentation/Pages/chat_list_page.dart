import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  String _searchQuery = '';
  
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
      
      // Perform one-time cleanup of duplicates (runs silently in background)
      _performCleanupIfNeeded(currentUser.id);
    }
  }

  // Perform cleanup of duplicate chat rooms (one-time check)
  void _performCleanupIfNeeded(String userId) {
    // Use a simple flag to ensure this only runs once per session
    final prefs = context.read<AuthCubit>().GetCurrentUser()?.id;
    final cleanupKey = 'cleanup_performed_$prefs';
    
    // For now, we'll just run the cleanup every time to ensure no duplicates
    // In a production app, you might want to store this in SharedPreferences
    // to avoid running it every time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<ChatCubit>().cleanupDuplicateChatRooms(userId);
      }
    });
  }

  // Filter out community chat rooms from the main chats list and remove duplicates
  List<ChatRoom> _filterNonCommunityChatRooms(List<ChatRoom> chatRooms) {
    final filteredRooms = chatRooms.where((chatRoom) {
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
    
    // Additional client-side deduplication as a safety measure
    return _deduplicateChatRooms(filteredRooms);
  }

  // Deduplicate chat rooms based on participants (client-side safety measure)
  List<ChatRoom> _deduplicateChatRooms(List<ChatRoom> chatRooms) {
    final Map<String, ChatRoom> uniqueChats = {};
    
    for (final chatRoom in chatRooms) {
      // Create a unique key based on sorted participant IDs
      final sortedParticipants = List<String>.from(chatRoom.participants);
      sortedParticipants.sort();
      final uniqueKey = sortedParticipants.join('_');
      
      // Keep the chat room with the most recent activity
      if (!uniqueChats.containsKey(uniqueKey) ||
          chatRoom.updatedAt.isAfter(uniqueChats[uniqueKey]!.updatedAt)) {
        uniqueChats[uniqueKey] = chatRoom;
      }
    }
    
    return uniqueChats.values.toList();
  }

  // Filter chat rooms based on search query
  List<ChatRoom> _searchChatRooms(List<ChatRoom> rooms, String query) {
    if (query.isEmpty) {
      return rooms;
    }
    
    return rooms.where((chatRoom) {
      // Search in chat name (group name or participant name)
      String chatName = '';
      if (chatRoom.isGroupChat) {
        // For group chats, use the group name if available
        chatName = chatRoom.participantNames['groupName'] ?? '';
        if (chatName.isEmpty) {
          // Fallback to participant names
          chatName = chatRoom.participantNames.values.join(", ");
        }
      } else {
        // For direct chats, find the other participant's name
        final currentUserId = context.read<AuthCubit>().GetCurrentUser()?.id ?? '';
        chatName = chatRoom.participantNames.entries
            .where((entry) => entry.key != currentUserId)
            .map((entry) => entry.value)
            .join(", ");
      }
      
      // Search in last message
      final String lastMessageContent = chatRoom.lastMessage ?? '';
      
      return chatName.toLowerCase().contains(query.toLowerCase()) ||
             lastMessageContent.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void _filterChatRooms(String query) {
    // Fix: Store the query first, then schedule the setState for next frame
    _searchQuery = query;
    
    // Use post-frame callback to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_searchQuery.isEmpty) {
            // Apply the community filter here too
            _filteredChatRooms = _filterNonCommunityChatRooms(_chatRooms);
          } else {
            _filteredChatRooms = _searchChatRooms(_filterNonCommunityChatRooms(_chatRooms), _searchQuery);
          }
        });
      }
    });
  }

  void _toggleSearch() {
    // Use post-frame callback to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchController.clear();
            _filterChatRooms('');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              elevation: 0,
              backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
              title: _isSearching
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _filterChatRooms('');
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    size: 18,
                                  ),
                                )
                              : null,
                      ),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                      ),
                      onChanged: _filterChatRooms,
                      autofocus: true,
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 28,
                            letterSpacing: -0.5,
              ),
                        ),
                      ],
        ),
        actions: [
                if (!_isSearching)
          IconButton(
                    onPressed: _toggleSearch,
                  icon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 24,
                    ),
                    splashRadius: 20,
                  ),
                if (_isSearching)
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 24,
                  ),
                    splashRadius: 20,
          ),
                if (!_isSearching)
                PopupMenuButton<String>(
                  icon: Icon(
                Icons.more_vert, 
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 24,
                    ),
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      PopupMenuItem<String>(
                      value: 'new_chat',
                child: Row(
                  children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'New Chat',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                  ],
                ),
              ),
                      PopupMenuItem<String>(
                      value: 'new_community',
                child: Row(
                  children: [
                            Icon(
                              Icons.group_add,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'New Community',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              floating: true,
              snap: true,
              pinned: false,
                  ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                Container(
                  color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
          controller: _tabController,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                      unselectedLabelColor: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      indicatorColor: isDarkMode ? Colors.white : Colors.black,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      isScrollable: true,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                      tabs: [
                        Container(
                          width: screenWidth * 0.3,
                          alignment: Alignment.center,
                          child: const Tab(text: 'Chats'),
                        ),
                        Container(
                          width: screenWidth * 0.5,
                          alignment: Alignment.center,
                          child: const Tab(text: 'Communities'),
                        ),
          ],
                    ),
                  ),
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
                          // Use post-frame callback to avoid setState during build
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                // Filter out community chat rooms from the main list
                                _chatRooms = _filterNonCommunityChatRooms(state.chatRooms);
                                _filteredChatRooms = _chatRooms;
                              });
                            }
                          });
                      } else if (state is ChatRoomDeleted) {
                        // When a chat is deleted, remove it from the local list immediately
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              // Remove the deleted chat from both lists
                              _chatRooms.removeWhere((room) => room.id == state.chatRoomId);
                              _filteredChatRooms = _searchChatRooms(_chatRooms, _searchQuery);
                            });
                            
                            // Hide any existing snackbars first
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Chat deleted successfully'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      } else if (state is ChatHiddenForUser) {
                        // When a chat is hidden, remove it from the local list immediately
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              // Remove the hidden chat from both lists
                              _chatRooms.removeWhere((room) => room.id == state.chatRoomId);
                              _filteredChatRooms = _searchChatRooms(_chatRooms, _searchQuery);
                            });
                            
                            // Hide any existing snackbars first
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Chat hidden successfully'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      } else if (state is GroupChatLeft || 
                                state is ChatHistoryDeletedForUser || 
                                state is ChatRoomUpdated) {
                        // When a chat is left/updated, reload the chat rooms
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            final currentUser = context.read<AuthCubit>().GetCurrentUser();
                            if (currentUser != null) {
                              context.read<ChatCubit>().loadUserChatRooms(currentUser.id);
                            }
                          }
                        });
                      } else if (state is DeletingChatRoom) {
                        // Show deleting progress
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            // Dismiss any existing snackbars first
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Deleting chat...'),
                                  ],
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 10), // Longer duration for deletion
                              ),
                            );
                          }
                        });
                      } else if (state is ChatError) {
                        // Show error message
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            // Dismiss any existing snackbars first
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        });
                      }
                    },
                    builder: (context, state) {
                        // Check for any loading states
                        if ((state is ChatRoomsLoading || state is ChatLoading) && _chatRooms.isEmpty) {
                          // Only show loading indicator if we don't have any cached data
                          return Center(
                            child: CircularProgressIndicator(
                              color: isDarkMode ? Colors.white : Colors.black,
                              strokeWidth: 2,
                            ),
                        );
                        } else if ((state is ChatRoomsLoaded || _chatRooms.isNotEmpty) && _filteredChatRooms.isEmpty) {
                          // No chats match the filter or no chats yet
                          if (_isSearching && _searchQuery.isNotEmpty) {
                            // No results for search
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No matches found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                          // No chats yet
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                    size: 64,
                                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                ),
                                  const SizedBox(height: 24),
                                Text(
                                  'No conversations yet',
                                  style: TextStyle(
                                      fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                Text(
                                  'Start chatting with friends',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
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
                                      backgroundColor: isDarkMode ? Colors.white : Colors.black,
                                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                      elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          );
                          }
                        } else if (state is ChatError) {
                          return Center(
                            child: Text(
                              'Error: ${state.message}',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                      }

                        // Display chat rooms
                      return FadeTransition(
                        opacity: _fadeInController,
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _loadChatRooms();
                            },
                            color: isDarkMode ? Colors.white : Colors.black,
                            backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        child: ListView.builder(
                          itemCount: _filteredChatRooms.length,
                              padding: const EdgeInsets.only(top: 4, bottom: 80),
                              physics: const AlwaysScrollableScrollPhysics(),
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
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: _tabController.index == 0
          ? FloatingActionButton(
              key: const ValueKey('chatFab'),
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
              backgroundColor: isDarkMode ? Colors.white : Colors.black,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.chat),
            )
          : FloatingActionButton(
              key: const ValueKey('communityFab'),
              heroTag: 'createCommunityFAB',
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransitions.slideRightTransition(
                    page: const CreateCommunityPage(),
                  ),
                );
              },
              backgroundColor: isDarkMode ? Colors.white : Colors.black,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.group_add),
            ),
            ),
    );
  }
}

// Implement the SliverAppBarDelegate class
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 42;

  @override
  double get minExtent => 42;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
} 
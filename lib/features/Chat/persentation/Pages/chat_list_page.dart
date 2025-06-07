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

  void _filterChatRooms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChatRooms = List.from(_chatRooms);
      } else {
        _filteredChatRooms = _chatRooms.where((chatRoom) {
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

  Widget _buildSearchBar() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
        boxShadow: _isSearching ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ] : [],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterChatRooms,
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _filterChatRooms('');
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        title: Text(
          'Conversations',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back, 
              size: 20, 
              color: isDarkMode ? Colors.white : Colors.black
            ),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context, 
              PageTransitions.fadeTransition(
                page: HomePage(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.black
              ),
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterChatRooms('');
                }
              });
            },
          ),
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_vert, 
                size: 20, 
                color: isDarkMode ? Colors.white : Colors.black
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings, 
                      color: isDarkMode ? Colors.white : Colors.black
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chat settings',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(
                      Icons.archive, 
                      color: isDarkMode ? Colors.white : Colors.black
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Archived chats',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings feature coming soon!'),
                    backgroundColor: Colors.black,
                  ),
                );
              } else if (value == 'archived') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Archived chats feature coming soon!'),
                    backgroundColor: Colors.black,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDarkMode ? Colors.white : Colors.black,
          indicatorWeight: 3,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Communities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chats Tab
          Column(
            children: [
              if (_isSearching) _buildSearchBar(),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.black,
                  onRefresh: () async {
                    _loadChatRooms();
                  },
                  child: BlocConsumer<ChatCubit, ChatState>(
                    listener: (context, state) {
                      if (state is ChatRoomsLoaded) {
                        print("ChatListPage: Received ${state.chatRooms.length} chat rooms");
                        setState(() {
                          _chatRooms = state.chatRooms;
                          _filteredChatRooms = state.chatRooms;
                        });
                      } else if (state is ChatRoomsError) {
                        print("ChatListPage: Error loading chat rooms: ${state.message}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading chats: ${state.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (state is ChatRoomDeleted) {
                        // Just show a success message - don't modify the list directly
                        // We'll reload the list instead
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat deleted successfully'),
                            backgroundColor: Colors.black,
                          ),
                        );
                        // Delay the reload to avoid race conditions
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) _loadChatRooms();
                        });
                      } else if (state is ChatHiddenForUser) {
                        // Just show a success message - don't modify the list directly
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat removed from your list'),
                            backgroundColor: Colors.black,
                          ),
                        );
                        // Delay the reload to avoid race conditions
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) _loadChatRooms();
                        });
                      } else if (state is GroupChatLeft) {
                        // Just show a success message - don't modify the list directly
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You have left the group'),
                            backgroundColor: Colors.black,
                          ),
                        );
                        // Delay the reload to avoid race conditions
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) _loadChatRooms();
                        });
                      }
                    },
                    builder: (context, state) {
                      // Show loading indicator if initial loading or deleting operations are in progress
                      if ((state is ChatRoomsLoading && _chatRooms.isEmpty) || 
                           state is ChatLoading) {
                        return const Center(
                          child: PercentCircleIndicator(),
                        );
                      }

                      // Always use the filtered list to render
                      if (_filteredChatRooms.isEmpty) {
                        // Check if empty because of filter or because no chats exist
                        if (_chatRooms.isEmpty) {
                          return _buildEmptyState();
                        } else {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No matches found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }

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
              ),
            ],
          ),
          
          // Communities Tab
          const CommunitiesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Chat tab
            Navigator.push(
              context,
              PageTransitions.zoomTransition(
                page: const NewChatPage(),
              ),
            );
          } else {
            // Communities tab
            Navigator.push(
              context,
              PageTransitions.zoomTransition(
                page: const CreateCommunityPage(),
              ),
            );
          }
        },
        backgroundColor: isDarkMode ? Colors.blue.shade700 : Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          _tabController.index == 0 ? Icons.chat : Icons.group_add,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start a conversation to connect with friends',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                PageTransitions.zoomTransition(
                  page: const NewChatPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Start a new chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade700 : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
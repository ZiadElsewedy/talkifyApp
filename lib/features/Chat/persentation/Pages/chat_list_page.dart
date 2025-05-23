import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/chat_room_tile.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/new_chat_page.dart';
import 'package:talkifyapp/features/Posts/presentation/HomePage.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // Keep a local list of chat rooms
  List<ChatRoom> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          },
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          

          
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // TODO: Implement chat search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search feature coming soon!'),
                  backgroundColor: Colors.black,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: RefreshIndicator(
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
              });
            } else if (state is ChatRoomsError) {
              print("ChatListPage: Error loading chat rooms: ${state.message}");
            } else if (state is ChatRoomDeleted) {
              // Remove the deleted chat room from the local list
              setState(() {
                _chatRooms.removeWhere((room) => room.id == state.chatRoomId);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat deleted successfully'),
                  backgroundColor: Colors.black,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ChatRoomsLoading && _chatRooms.isEmpty) {
              return const Center(
                child: PercentCircleIndicator(),
              );
            }

            // Always use the local list to render
            if (_chatRooms.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              itemCount: _chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = _chatRooms[index];
                return ChatRoomTile(
                  chatRoom: chatRoom,
                  currentUserId: currentUser?.id ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatRoom: chatRoom,
                        ),
                      ),
                    ).then((_) {
                      // Reload chat rooms when returning from chat
                      _loadChatRooms();
                    });
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewChatPage(),
            ),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewChatPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Start New Chat', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadChatRooms,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Try Again', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Search_cubit.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Searchstates.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  List<ProfileUser> _selectedUsers = [];
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    // Load all users initially
    _searchUsers('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) {
    context.read<SearchCubit>().searchUsers(query);
  }

  void _toggleUserSelection(ProfileUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
      
      // Set group creation mode if more than 1 user is selected
      _isCreatingGroup = _selectedUsers.length > 1;
    });
  }

  void _startChat() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;

    // Check if this is a group chat
    if (_selectedUsers.length > 1) {
      _showGroupNameDialog();
      return;
    }

    // Create participant lists including current user for 1-on-1 chat
    final participantIds = [currentUser.id, ..._selectedUsers.map((u) => u.id)];
    final participantNames = {
      currentUser.id: currentUser.name,
      for (var user in _selectedUsers) user.id: user.name,
    };
    final participantAvatars = {
      currentUser.id: currentUser.profilePictureUrl,
      for (var user in _selectedUsers) user.id: user.profilePictureUrl,
    };

    // Find or create chat room
    final chatRoom = await context.read<ChatCubit>().findOrCreateChatRoom(
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: participantAvatars,
    );

    if (chatRoom != null && mounted) {
      // Navigate to chat room
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(chatRoom: chatRoom),
        ),
      );
    }
  }

  void _showGroupNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter a name for this group',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createGroupChat(null);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              final groupName = _groupNameController.text.trim();
              if (groupName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name'))
                );
                return;
              }
              Navigator.of(context).pop();
              _createGroupChat(groupName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createGroupChat(String? groupName) async {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;

    // Create participant lists including current user
    final participantIds = [currentUser.id, ..._selectedUsers.map((u) => u.id)];
    final participantNames = {
      currentUser.id: currentUser.name,
      for (var user in _selectedUsers) user.id: user.name,
    };
    
    // Add group name if provided
    if (groupName != null && groupName.isNotEmpty) {
      participantNames['groupName'] = groupName;
    }
    
    final participantAvatars = {
      currentUser.id: currentUser.profilePictureUrl,
      for (var user in _selectedUsers) user.id: user.profilePictureUrl,
    };

    // Create the chat room
    final chatRoom = await context.read<ChatCubit>().findOrCreateChatRoom(
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: participantAvatars,
    );

    // Clear controllers
    _groupNameController.clear();

    if (chatRoom != null && mounted) {
      // Navigate to chat room
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(chatRoom: chatRoom),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isCreatingGroup ? 'New Group' : 'New Chat',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          if (_selectedUsers.isNotEmpty)
            TextButton(
              onPressed: _startChat,
              child: Text(
                _isCreatingGroup ? 'Next' : 'Start',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Selected users (if any)
          if (_selectedUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCreatingGroup
                        ? 'Group members (${_selectedUsers.length}):'
                        : 'Selected (${_selectedUsers.length}):',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _selectedUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user.profilePictureUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(user.profilePictureUrl)
                                  : null,
                              child: user.profilePictureUrl.isEmpty
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0] : 'U',
                                      style: const TextStyle(color: Colors.black),
                                    )
                                  : null,
                            ),
                            label: Text(user.name),
                            onDeleted: () => _toggleUserSelection(user),
                            deleteIcon: const Icon(Icons.close, size: 18),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Users list
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                } else if (state is SearchLoaded) {
                  final currentUser = context.read<AuthCubit>().GetCurrentUser();
                  
                  // Filter out current user from search results
                  final users = state.users.where((user) => 
                      currentUser == null || user.id != currentUser.id).toList();

                  if (users.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = _selectedUsers.contains(user);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user.profilePictureUrl.isNotEmpty
                              ? CachedNetworkImageProvider(user.profilePictureUrl)
                              : null,
                          child: user.profilePictureUrl.isEmpty
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.black,
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              ),
                        onTap: () => _toggleUserSelection(user),
                      );
                    },
                  );
                } else if (state is SearchError) {
                  return _buildErrorState(state.message);
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedUsers.isNotEmpty
          ? FloatingActionButton(
              onPressed: _startChat,
              backgroundColor: Colors.black,
              child: Icon(
                _isCreatingGroup ? Icons.group_add : Icons.arrow_forward,
                color: Colors.white
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for someone to start a chat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
            'Failed to load users',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _searchUsers(''),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupInfoPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const GroupInfoPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late Future<List<AppUser>> _participantsFuture;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthCubit>().GetCurrentUser()?.id ?? '';
    _participantsFuture = _fetchParticipantsDetails();
  }

  Future<List<AppUser>> _fetchParticipantsDetails() async {
    List<AppUser> participants = [];
    
    for (String participantId in widget.chatRoom.participants) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(participantId)
            .get();

        if (doc.exists && doc.data() != null) {
          final userData = doc.data()!;
          participants.add(AppUser.fromJson(userData));
        } else {
          // Create a basic user if we can't find them in database
          participants.add(AppUser(
            id: participantId,
            name: widget.chatRoom.participantNames[participantId] ?? 'Unknown User',
            email: '',
            phoneNumber: '',
            profilePictureUrl: widget.chatRoom.participantAvatars[participantId] ?? '',
          ));
        }
      } catch (e) {
        print('Error fetching participant details for $participantId: $e');
      }
    }
    
    // Sort participants: current user first, then online users, then others
    participants.sort((a, b) {
      if (a.id == _currentUserId) return -1;
      if (b.id == _currentUserId) return 1;
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      return a.name.compareTo(b.name);
    });
    
    return participants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Group Info'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No participants found'));
          }

          final participants = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Group Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    _getGroupNameAbbreviation(),
                    style: const TextStyle(fontSize: 40, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Group Name
                Text(
                  _getGroupName(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                Text(
                  '${participants.length} participants',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                // Edit group name button
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Group Name'),
                  onPressed: _showEditGroupNameDialog,
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                // Participants list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...participants.map((user) => _buildParticipantTile(user)),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                // Leave group button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app, color: Colors.white),
                    label: const Text('Leave Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _confirmLeaveGroup,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditGroupNameDialog() {
    final TextEditingController controller = TextEditingController();
    controller.text = _getGroupName();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter group name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _updateGroupName(newName);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGroupName(String newName) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .update({
        'participantNames.groupName': newName,
      });
      
      // Refresh the page to show the updated name
      setState(() {
        _participantsFuture = _fetchParticipantsDetails();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group name updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group name: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group? You will no longer receive messages from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _leaveGroup();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId.isEmpty) return;
      
      // Get the updated list of participants
      List<String> updatedParticipants = 
          List.from(widget.chatRoom.participants)
            ..remove(currentUserId);
      
      // Remove user from participants
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .update({
        'participants': updatedParticipants,
      });
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildParticipantTile(AppUser user) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: () => _openUserProfile(user),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.profilePictureUrl.isNotEmpty
                  ? CachedNetworkImageProvider(user.profilePictureUrl)
                  : null,
              child: user.profilePictureUrl.isEmpty
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        user.id == _currentUserId ? '${user.name} (You)' : user.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        user.isOnline 
            ? 'Online'
            : user.lastSeen != null 
                ? 'Last seen ${timeago.format(user.lastSeen!)}'
                : 'Offline',
        style: TextStyle(
          color: user.isOnline ? Colors.green : Colors.grey,
        ),
      ),
      onTap: () => _openUserProfile(user),
    );
  }

  void _openUserProfile(AppUser user) {
    if (user.id == _currentUserId) return; // Don't open profile for current user
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: user.id,
          userName: user.name,
          initialAvatarUrl: user.profilePictureUrl,
        ),
      ),
    );
  }

  String _getGroupName() {
    // Check if a custom group name is set
    if (widget.chatRoom.participantNames.containsKey('groupName') && 
        widget.chatRoom.participantNames['groupName']!.isNotEmpty) {
      return widget.chatRoom.participantNames['groupName']!;
    }
    
    // Fallback to participant names
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    final names = widget.chatRoom.participantNames.entries
        .where((entry) => 
            entry.key != 'groupName' && 
            entry.key != (currentUser?.id ?? '') && 
            entry.value.isNotEmpty)
        .map((entry) => entry.value)
        .take(3)
        .join(', ');
    
    return names.isNotEmpty 
        ? names + (widget.chatRoom.participants.length > 4 ? ' +${widget.chatRoom.participants.length - 4}' : '')
        : 'Group Chat';
  }

  String _getGroupNameAbbreviation() {
    final groupName = _getGroupName();
    if (groupName.isEmpty) return 'GC';
    
    // If it's a list of names, get initials of first 2-3 names
    if (groupName.contains(',')) {
      return groupName
          .split(',')
          .take(3)
          .map((name) => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '')
          .join('');
    }
    
    // Otherwise use the first 2 letters of the group name
    return groupName.length > 1 
        ? groupName.substring(0, 2).toUpperCase()
        : '${groupName[0].toUpperCase()}G';
  }
} 
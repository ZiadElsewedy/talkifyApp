import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';
import 'package:talkifyapp/features/Chat/Utils/page_transitions.dart';

class GroupInfoPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const GroupInfoPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> with TickerProviderStateMixin {
  late Future<List<AppUser>> _participantsFuture;
  late String _currentUserId;
  late AnimationController _fadeInController;
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthCubit>().GetCurrentUser()?.id ?? '';
    _participantsFuture = _fetchParticipantsDetails();
    
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInController.forward();
    _listAnimationController.forward();
  }
  
  @override
  void dispose() {
    _fadeInController.dispose();
    _listAnimationController.dispose();
    super.dispose();
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
        title: const Text(
          'Group Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeInController,
        child: FutureBuilder<List<AppUser>>(
          future: _participantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No participants found'));
            }

            final participants = snapshot.data!;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Group Avatar with animated shadow
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 15),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: value,
                              spreadRadius: value / 8,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Hero(
                      tag: 'group_${widget.chatRoom.id}',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          _getGroupNameAbbreviation(),
                          style: const TextStyle(fontSize: 40, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Group Name with edit animation
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _showEditGroupNameDialog,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _getGroupName(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    '${participants.length} participants',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Participants section header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group, size: 18, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Participants',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  
                  // Participants list with staggered animations
                  ...List.generate(participants.length, (index) {
                    final user = participants[index];
                    final animation = Tween<Offset>(
                      begin: const Offset(0.5, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _listAnimationController,
                        curve: Interval(
                          index * 0.05,
                          0.5 + index * 0.05,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );
                    
                    return SlideTransition(
                      position: animation,
                      child: FadeTransition(
                        opacity: _listAnimationController,
                        child: _buildParticipantTile(user),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  
                  // Options section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        _buildOptionTile(
                          icon: Icons.notifications_off_outlined,
                          title: 'Mute notifications',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mute notifications feature coming soon!'),
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.photo_library_outlined,
                          title: 'Shared media',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Shared media feature coming soon!'),
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.search,
                          title: 'Search in conversation',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Search feature coming soon!'),
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _buildOptionTile(
                          icon: Icons.exit_to_app,
                          title: 'Leave group',
                          textColor: ChatStyles.errorColor,
                          iconColor: ChatStyles.errorColor,
                          onTap: _confirmLeaveGroup,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
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
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group name: $e'),
          backgroundColor: ChatStyles.errorColor,
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
            style: TextButton.styleFrom(foregroundColor: ChatStyles.errorColor),
            child: const Text('Leave'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
      
      // Run leave animation
      _fadeInController.reverse().then((_) async {
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
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group: $e'),
          backgroundColor: ChatStyles.errorColor,
        ),
      );
    }
  }

  Widget _buildParticipantTile(AppUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () => _openUserProfile(user),
          child: Hero(
            tag: 'profile_${user.id}',
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
                      decoration: ChatStyles.statusIndicatorDecoration(isOnline: true),
                    ),
                  ),
              ],
            ),
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
            color: user.isOnline ? ChatStyles.onlineColor : Colors.grey,
          ),
        ),
        trailing: user.id != _currentUserId 
            ? IconButton(
                icon: const Icon(Icons.message, size: 20),
                onPressed: () => _openUserProfile(user),
              )
            : null,
        onTap: () => _openUserProfile(user),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor ?? Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  void _openUserProfile(AppUser user) {
    if (user.id == _currentUserId) return; // Don't open profile for current user
    
    Navigator.push(
      context,
      PageTransitions.heroDetailTransition(
        page: UserProfilePage(
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
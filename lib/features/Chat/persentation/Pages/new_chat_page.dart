import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_list_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Search_cubit.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Searchstates.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  List<ProfileUser> _selectedUsers = [];
  bool _isCreatingGroup = false;
  
  // Group photo variables
  File? _groupPhotoFile;
  Uint8List? _groupPhotoBytes;
  String? _groupPhotoUrl;
  
  // Animation controllers
  late AnimationController _searchBarController;
  late AnimationController _selectionController;
  late Animation<Offset> _searchBarSlideAnimation;
  late Animation<double> _searchBarFadeAnimation;

  @override
  void initState() {
    super.initState();
    // Load all users initially
    _searchUsers('');
    
    // Initialize animations
    _searchBarController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _searchBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _searchBarController,
      curve: Curves.easeOutQuart,
    ));
    
    _searchBarFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchBarController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _searchBarController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _searchBarController.dispose();
    _selectionController.dispose();
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
        // Play selection animation
        _selectionController.reset();
        _selectionController.forward();
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

    try {
      // Find or create chat room
      final chatRoom = await context.read<ChatCubit>().findOrCreateChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
      );

      if (mounted) {
        // Navigate to chat list page instead of chat room
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatListPage(),
          ),
        );
      }
    } catch (e) {
      print('Error creating chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: ${e.toString()}')),
        );
      }
    }
  }

  void _showGroupNameDialog() {
    if (!mounted) return;
    
    // Reset group photo variables
    _groupPhotoFile = null;
    _groupPhotoBytes = null;
    _groupPhotoUrl = null;
    
    // Store a local reference to avoid context being captured in closures
    final BuildContext localContext = context;
    final bool isDarkMode = Theme.of(localContext).brightness == Brightness.dark;
    
    showDialog(
      context: localContext,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Group',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Give your group a name and start chatting',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Group photo selector
                Center(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final pickedImage = await _pickImage();
                              if (pickedImage != null) {
                                setState(() {
                                  if (kIsWeb) {
                                    _groupPhotoBytes = pickedImage['bytes'];
                                  } else {
                                    _groupPhotoFile = File(pickedImage['path']);
                                  }
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: _groupPhotoBytes != null || _groupPhotoFile != null
                                ? ClipOval(
                                    child: _groupPhotoBytes != null
                                      ? Image.memory(
                                          _groupPhotoBytes!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        )
                                      : Image.file(
                                          _groupPhotoFile!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                  )
                                : Icon(
                                    Icons.add_a_photo,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    size: 40,
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Group members preview with animation
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedUsers.length > 5 ? 5 : _selectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _selectedUsers[index];
                      final bool isLast = index == 4 && _selectedUsers.length > 5;
                      
                      // Add staggered animation effect
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Align(
                          widthFactor: 0.7,
                          child: CircleAvatar(
                            backgroundColor: isLast ? Colors.grey[800] : Colors.grey[200],
                            backgroundImage: !isLast && user.profilePictureUrl.isNotEmpty
                                ? CachedNetworkImageProvider(user.profilePictureUrl)
                                : null,
                            radius: 22,
                            child: isLast
                                ? Text(
                                    '+${_selectedUsers.length - 4}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : (user.profilePictureUrl.isEmpty
                                    ? Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      )
                                    : null),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Unique group name hint with animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Each group with a unique name creates a separate chat',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Group name input with animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      hintText: 'Enter a name for this group',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1.5),
                      ),
                      prefixIcon: Icon(Icons.group, color: isDarkMode ? Colors.grey[400] : Colors.black),
                      floatingLabelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
                      filled: true,
                    ),
                    maxLength: 30,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Buttons with animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _createGroupChat(null);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.grey[300] : Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Skip'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final groupName = _groupNameController.text.trim();
                          if (groupName.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Please enter a group name'))
                            );
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          _createGroupChat(groupName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.white : Colors.black,
                          foregroundColor: isDarkMode ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Create',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createGroupChat(String? groupName) async {
    if (!mounted) return;
    
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;

    // Store context locally to avoid issues
    final BuildContext localContext = context;

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
    
    // Show loading indicator if uploading photo
    if (_groupPhotoBytes != null || _groupPhotoFile != null) {
      showDialog(
        context: localContext,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    try {
      // Upload group photo if selected
      if (_groupPhotoBytes != null || _groupPhotoFile != null) {
        final String groupId = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child('group_avatars').child('$groupId.jpg');
        
        if (kIsWeb && _groupPhotoBytes != null) {
          // Web upload
          await ref.putData(
            _groupPhotoBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else if (_groupPhotoFile != null) {
          // Mobile upload
          await ref.putFile(_groupPhotoFile!);
        }
        
        // Get download URL
        _groupPhotoUrl = await ref.getDownloadURL();
        
        // Add group photo URL to participant avatars
        if (_groupPhotoUrl != null) {
          participantAvatars['groupAvatar'] = _groupPhotoUrl!;
        }
        
        // Close loading dialog
        if (localContext.mounted && Navigator.canPop(localContext)) {
          Navigator.pop(localContext);
        }
      }

      // Create the chat room
      final chatRoom = await localContext.read<ChatCubit>().findOrCreateChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
      );

      // Clear controllers and photo variables
      _groupNameController.clear();
      _groupPhotoFile = null;
      _groupPhotoBytes = null;
      _groupPhotoUrl = null;

      if (mounted) {
        // Navigate to chat list page instead of the chat room
        Navigator.pushReplacement(
          localContext,
          MaterialPageRoute(
            builder: (context) => const ChatListPage(),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (localContext.mounted && Navigator.canPop(localContext)) {
        Navigator.pop(localContext);
      }
      
      print('Error creating group chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(content: Text('Failed to create group chat: ${e.toString()}')),
        );
      }
    }
  }

  // Helper method to pick image from device
  Future<Map<String, dynamic>?> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return {
          'path': result.files.first.path,
          'bytes': kIsWeb ? result.files.first.bytes : null,
        };
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _isCreatingGroup ? 'New Group' : 'New Chat',
            key: ValueKey<bool>(_isCreatingGroup),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 1,
        shadowColor: isDarkMode ? Colors.black45 : Colors.black12,
        actions: [
          if (_selectedUsers.isNotEmpty)
            AnimatedBuilder(
              animation: _selectionController,
              builder: (context, child) {
                return Transform.scale(
                  scale: Tween<double>(begin: 0.8, end: 1.0)
                      .animate(CurvedAnimation(
                        parent: _selectionController,
                        curve: Curves.elasticOut,
                      ))
                      .value,
                  child: TextButton(
                    onPressed: _startChat,
                    child: Text(
                      _isCreatingGroup ? 'Next' : 'Start',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with animation
          SlideTransition(
            position: _searchBarSlideAnimation,
            child: FadeTransition(
              opacity: _searchBarFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1.5),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onChanged: _searchUsers,
                  ),
                ),
              ),
            ),
          ),

          // Selected users (if any) with animations
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _selectedUsers.isEmpty ? 0 : 100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              border: Border(
                top: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200),
                bottom: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200),
              ),
            ),
            child: _selectedUsers.isEmpty 
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _isCreatingGroup ? Icons.group : Icons.person,
                                key: ValueKey<bool>(_isCreatingGroup),
                                                              size: 18,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.2, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _isCreatingGroup
                                  ? 'Group members (${_selectedUsers.length})'
                                  : 'Selected (${_selectedUsers.length})',
                              key: ValueKey<String>(_isCreatingGroup ? 'group' : 'selected'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12, bottom: 8),
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 300),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Chip(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                  avatar: CircleAvatar(
                                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                    backgroundImage: user.profilePictureUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(user.profilePictureUrl)
                                        : null,
                                    child: user.profilePictureUrl.isEmpty
                                        ? Text(
                                            user.name.isNotEmpty ? user.name[0] : 'U',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  label: Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  deleteIcon: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.black),
                                  ),
                                  onDeleted: () => _toggleUserSelection(user),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    side: BorderSide.none,
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),

          // Users list with animations
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.white : Colors.black));
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
                      
                      // Calculate staggered animation delay
                      final delay = index * 0.05;
                      
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600 + (index * 50)),
                        curve: Curves.easeOutQuint,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Material(
                          color: isDarkMode 
                              ? (isSelected ? Colors.grey[800] : Colors.black) 
                              : (isSelected ? Colors.grey[50] : Colors.white),
                          child: InkWell(
                            onTap: () => _toggleUserSelection(user),
                            splashColor: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                            highlightColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                leading: Hero(
                                  tag: 'avatar_${user.id}',
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                      backgroundImage: user.profilePictureUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(user.profilePictureUrl)
                                          : null,
                                      child: user.profilePictureUrl.isEmpty
                                          ? Text(
                                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode ? Colors.white : Colors.black,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  user.email,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected 
                                        ? (isDarkMode ? Colors.white : Colors.black) 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected 
                                          ? (isDarkMode ? Colors.white : Colors.black) 
                                          : (isDarkMode ? Colors.grey[400]! : Colors.grey),
                                      width: isSelected ? 0 : 1.5,
                                    ),
                                  ),
                                  child: isSelected 
                                      ? Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 16,
                                            color: isDarkMode ? Colors.black : Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
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
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: FloatingActionButton.extended(
                heroTag: 'startChatFAB',
                onPressed: _startChat,
                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isCreatingGroup ? Icons.group_add : Icons.chat,
                    key: ValueKey<bool>(_isCreatingGroup),
                    color: isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.5, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _isCreatingGroup ? 'Create Group' : 'Start Chat',
                    key: ValueKey<String>(_isCreatingGroup ? 'group' : 'chat'),
                    style: TextStyle(
                      color: isDarkMode ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                elevation: 4,
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community_member.dart';
import 'package:talkifyapp/features/Communities/data/models/community_model.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_member_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_member_state.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_state.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:talkifyapp/features/Storage/Data/Filebase_Storage_repo.dart'; // Contains FirebaseStorageRepo class
import 'community_chat_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityDetailsPage extends StatefulWidget {
  final String communityId;

  const CommunityDetailsPage({
    Key? key,
    required this.communityId,
  }) : super(key: key);

  @override
  State<CommunityDetailsPage> createState() => _CommunityDetailsPageState();
}

class _CommunityDetailsPageState extends State<CommunityDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUserAdmin = false;
  bool _isUserMember = false;
  String? _currentUserId;
  bool _isLoading = false;
  bool _isImageLoading = false;
  
  // Stream subscriptions
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunityDetails();
    
    // Get current user ID
    _currentUserId = context.read<AuthCubit>().GetCurrentUser()?.id;
    
    // Set up subscriptions for cubits
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    final memberCubit = context.read<CommunityMemberCubit>();
    
    // Subscription for community member cubit
    final memberSub = memberCubit.stream.listen((state) {
      if (!mounted) return;
      
      if (state is CommunityMembersLoaded) {
        _updateMemberStatus(state.members);
      } else if (state is JoinedCommunitySuccessfully) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _isUserMember = true;
            });
          });
        }
      } else if (state is LeftCommunitySuccessfully) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _isUserMember = false;
              _isUserAdmin = false;
              _isLoading = false;
            });
          });
        }
      }
    });
    
    _subscriptions.add(memberSub);
  }

  @override
  void dispose() {
    _tabController.dispose();
    
    // Cancel all subscriptions
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    
    super.dispose();
  }

  void _loadCommunityDetails() {
    context.read<CommunityCubit>().getCommunityById(widget.communityId);
    context.read<CommunityMemberCubit>().getCommunityMembers(widget.communityId);
  }
  
  // This method is only called from initState or event handlers, not during build
  void _updateMemberStatus(List<CommunityMember> members) {
    if (_currentUserId == null) return;
    
    final userMember = members.firstWhereOrNull((member) => member.userId == _currentUserId);
    
    if (mounted) {
      // Use post-frame callback to avoid setState during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isUserMember = userMember != null;
          _isUserAdmin = userMember?.role == MemberRole.admin;
        });
      });
    }
  }
  
  Future<void> _joinCommunity() async {
    if (_currentUserId == null || !mounted) return;
    
    final memberCubit = context.read<CommunityMemberCubit>();
    await memberCubit.joinCommunity(widget.communityId, _currentUserId!);
    
    // Navigate to chat after successfully joining
    if (mounted) {
      // Use post-frame callback to avoid build during frame errors
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Check mounted again after callback
        _navigateToChat();
      });
    }
  }
  
  void _navigateToChat() {
    if (!mounted || context.read<CommunityCubit>().state is! CommunityDetailLoaded) return;
    
    final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
    final chatCubit = context.read<ChatCubit>();
    
    print("DEBUG: _navigateToChat - Starting navigation to chat for community: ${community.id}, name: ${community.name}");
    print("DEBUG: Current user ID: ${_currentUserId}");
    print("DEBUG: Is user member? $_isUserMember");
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Opening ${community.name} chat...'),
          ],
        ),
      ),
    );
    
    // Ensure we have the latest member data 
    final memberCubit = context.read<CommunityMemberCubit>();
    memberCubit.getCommunityMembers(community.id);
    
    print("DEBUG: About to call getChatRoomForCommunity with ID: ${community.id}");
    
    // Get the chat room for this community
    chatCubit.getChatRoomForCommunity(community.id);
    
    // Create a subscription variable before using it
    late StreamSubscription subscription;
    
    // Listen for the result in a separate listener
    subscription = chatCubit.stream.listen((state) async {
      if (!mounted) {
        subscription.cancel();
        return;
      }
      
      if (state is ChatRoomForCommunityLoaded) {
        print("DEBUG: ChatRoomForCommunityLoaded state received with chat room ID: ${state.chatRoom.id}");
        
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Navigate to the chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityChatPage(
              communityId: community.id,
              communityName: community.name,
            ),
          ),
        );
        
        // Now we can cancel the subscription
        subscription.cancel();
      } else if (state is ChatRoomForCommunityNotFound || state is ChatRoomForCommunityError) {
        print("DEBUG: Error/NotFound state received: ${state.runtimeType}");
        if (state is ChatRoomForCommunityError) {
          print("DEBUG: Error message: ${state.message}");
        } else if (state is ChatRoomForCommunityNotFound) {
          print("DEBUG: Community ID not found: ${state.communityId}");
          
          // Try to create a new community chat room directly from here
          print("DEBUG: Attempting to create community chat room directly");
          
          final currentUser = context.read<AuthCubit>().GetCurrentUser();
          if (currentUser != null) {
            // Get community member list
            try {
              final communityRepo = CommunityRepositoryImpl();
              final members = await communityRepo.getCommunityMembers(community.id);
              
              print("DEBUG: Found ${members.length} members for community ${community.id}");
              
              // Extract member IDs
              final List<String> memberIds = members.map((m) => m.userId).toList();
              
              // Make sure current user is included
              if (!memberIds.contains(currentUser.id)) {
                memberIds.add(currentUser.id);
              }
              
              // Create maps for participant names and avatars
              final Map<String, String> participantNames = {};
              final Map<String, String> participantAvatars = {};
              final Map<String, int> unreadCounts = {};
              
              // Add current user
              participantNames[currentUser.id] = currentUser.name;
              participantAvatars[currentUser.id] = currentUser.profilePictureUrl;
              unreadCounts[currentUser.id] = 0;
              
              // Add other members
              for (final member in members) {
                if (member.userId != currentUser.id) {
                  participantNames[member.userId] = member.userName;
                  participantAvatars[member.userId] = member.userAvatar;
                  unreadCounts[member.userId] = 0;
                }
              }
              
              // Create new chat room
              context.read<ChatCubit>().createGroupChatRoom(
                participants: memberIds,
                participantNames: participantNames,
                participantAvatars: participantAvatars,
                unreadCount: unreadCounts,
                groupName: community.name,
                communityId: community.id,
              );
              
              // Don't cancel subscription yet, wait for ChatRoomCreated state
              return;
            } catch (e) {
              print("DEBUG: Error creating community chat room: $e");
            }
          }
        }
        
        // Close the loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open community chat. Please try again.')),
        );
        
        // Cancel subscription after error
        subscription.cancel();
      } else if (state is ChatRoomCreating) {
        print("DEBUG: ChatRoomCreating state received");
      } else if (state is ChatRoomCreated) {
        print("DEBUG: ChatRoomCreated state received. New chat room ID: ${state.chatRoom.id}");
        
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Navigate directly to chat page with the new chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityChatPage(
              communityId: community.id,
              communityName: community.name,
            ),
          ),
        );
        
        // Cancel subscription after navigation
        subscription.cancel();
      }
    });
  }
  
  // Handle leaving a community
  Future<void> _leaveCommunity() async {
    if (_currentUserId == null || !mounted) return;
    
    final memberCubit = context.read<CommunityMemberCubit>();
    
    // Update UI to show loading state
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
    });
    
    try {
      await memberCubit.leaveCommunity(widget.communityId, _currentUserId!);
      
      if (mounted) {
        // Update UI to reflect the changes
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Check mounted again
          
          setState(() {
            _isUserMember = false;
            _isUserAdmin = false;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have left the community')),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        // Update UI to reflect error state
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Check mounted again
          
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave community: $e')),
          );
        });
      }
    }
  }
  
  // Handle closing/deleting a community
  Future<void> _deleteCommunity() async {
    if (!mounted) return;
    
    final communityCubit = context.read<CommunityCubit>();
    
    // Update UI to show loading state
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
    });
    
    try {
      await communityCubit.deleteCommunity(widget.communityId);
      
      if (mounted) {
        // Update UI to reflect the changes
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Check mounted again
          
          setState(() {
            _isLoading = false;
          });
          
          // Pop back to communities list
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Community has been deleted')),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        // Update UI to reflect error state
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Check mounted again
          
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete community: $e')),
          );
        });
      }
    }
  }
  
  // Show confirmation dialog for leaving a community
  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Community'),
          content: const Text('Are you sure you want to leave this community? You can join again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _leaveCommunity();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
  
  // Show confirmation dialog for deleting a community
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Community'),
          content: const Text(
            'Are you sure you want to delete this community? '
            'This action is permanent and cannot be undone. '
            'All messages and member data will be lost.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCommunity();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _changeCommunityPhoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final File imageFile = File(pickedFile.path);
      final storage = FirebaseStorageRepo();
      final path = 'communities/${widget.communityId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final url = await storage.uploadFile(imageFile.path, path) ?? '';
      
      if (url.isNotEmpty && context.read<CommunityCubit>().state is CommunityDetailLoaded) {
        final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
        final updatedCommunity = Community(
          id: community.id,
          name: community.name,
          description: community.description,
          category: community.category,
          iconUrl: url,
          memberCount: community.memberCount,
          createdBy: community.createdBy,
          isPrivate: community.isPrivate,
          createdAt: community.createdAt,
        );
        
        context.read<CommunityCubit>().updateCommunity(updatedCommunity);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community photo updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showEditCommunityDialog() {
    if (context.read<CommunityCubit>().state is! CommunityDetailLoaded) return;
    
    final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
    
    // Controllers
    final nameController = TextEditingController(text: community.name);
    final descriptionController = TextEditingController(text: community.description);
    String selectedCategory = community.category;
    bool isPrivate = community.isPrivate;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Community'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCategory,
                  items: [
                    'General',
                    'Technology',
                    'Gaming',
                    'Sports',
                    'Art',
                    'Music',
                    'Food',
                    'Travel',
                    'Fashion',
                    'Education',
                    'Business',
                    'Politics',
                    'Science',
                    'Health',
                    'Other',
                  ].map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    selectedCategory = newValue!;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Private Community'),
                  value: isPrivate,
                  onChanged: (value) {
                    setState(() {
                      isPrivate = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateCommunity(
                  nameController.text,
                  descriptionController.text,
                  selectedCategory,
                  isPrivate,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  void _showManageMemberOptions(CommunityMember member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(member.userName),
            subtitle: Text(_getRoleText(member.role)),
            leading: CircleAvatar(
              backgroundImage: member.userAvatar.isNotEmpty ? NetworkImage(member.userAvatar) : null,
              child: member.userAvatar.isEmpty ? Text(member.userName[0].toUpperCase()) : null,
            ),
          ),
          const Divider(),
          if (member.role != MemberRole.admin)
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Make Admin'),
              onTap: () {
                Navigator.pop(context);
                context.read<CommunityMemberCubit>().updateMemberRole(
                  widget.communityId, member.userId, MemberRole.admin);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.userName} is now an admin')),
                );
              },
            ),
          if (member.role != MemberRole.moderator)
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text('Make Moderator'),
              onTap: () {
                Navigator.pop(context);
                context.read<CommunityMemberCubit>().updateMemberRole(
                  widget.communityId, member.userId, MemberRole.moderator);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.userName} is now a moderator')),
                );
              },
            ),
          if (member.role != MemberRole.member)
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Make Member'),
              onTap: () {
                Navigator.pop(context);
                context.read<CommunityMemberCubit>().updateMemberRole(
                  widget.communityId, member.userId, MemberRole.member);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.userName} is now a regular member')),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.remove_circle, color: Colors.red),
            title: const Text('Remove from Community', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              context.read<CommunityMemberCubit>().leaveCommunity(widget.communityId, member.userId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.userName} has been removed')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) {
          if (state is CommunityDetailLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            );
          } else if (state is CommunityDetailLoaded) {
            final community = state.community;
            return _buildCommunityDetail(context, community);
          } else if (state is CommunityError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            );
          }
          return Center(
            child: Text(
              'Loading community details...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityDetail(BuildContext context, Community community) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: Stack(
              children: [
                Positioned.fill(
                  child: FlexibleSpaceBar(
              title: Text(
                community.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                      decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                        image: community.iconUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(community.iconUrl),
                        fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: community.iconUrl.isEmpty
                          ? Center(
                            child: Icon(
                              Icons.people,
                              color: Theme.of(context).colorScheme.surface,
                              size: 60,
                            ),
                      )
                          : null,
                        ),
                      ),
              ),
                // Edit photo button for admin
                if (_isUserAdmin)
                  Positioned(
                    right: 8,
                    bottom: 40,
                    child: FloatingActionButton.small(
                      onPressed: _changeCommunityPhoto,
                      backgroundColor: Colors.black54,
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.camera_alt),
                    ),
                  ),
              ],
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              if (_isUserAdmin)
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: _showEditCommunityDialog,
                ),
              IconButton(
                icon: Icon(
                  Icons.chat,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                onPressed: _isUserMember ? _navigateToChat : null,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    community.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Info rows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.calendar_today,
                        'Created',
                        'on ${_formatDate(community.createdAt)}',
                      ),
                      _buildInfoItem(
                        context,
                        Icons.category,
                        'Category',
                        community.category,
                      ),
                      _buildInfoItem(
                        context,
                        Icons.visibility,
                        'Visibility',
                        community.isPrivate ? 'Private community' : 'Public community',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Join/Chat button - Optimized to avoid setState during build
                  _buildJoinChatButton(community),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.inversePrimary,
                labelColor: Theme.of(context).colorScheme.inversePrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Members'),
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
          // About tab
          _buildAboutTab(context),
          
          // Members tab
          _buildMembersTab(),
        ],
      ),
    );
  }
  
  // Separate widget for the Join/Chat button to handle state properly
  Widget _buildJoinChatButton(Community community) {
    return BlocConsumer<CommunityMemberCubit, CommunityMemberState>(
      listener: (context, memberState) {
        if (memberState is CommunityMembersLoaded) {
          // Update state in the listener not during build
          _updateMemberStatus(memberState.members);
        } else if (memberState is JoinedCommunitySuccessfully) {
          if (mounted) {
            // Use post-frame callback to avoid setState during build
            SchedulerBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _isUserMember = true;
              });
            });
          }
        }
      },
      builder: (context, memberState) {
        // Determine button state based on current member status
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUserMember 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.inversePrimary,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: memberState is JoiningCommunity 
                    ? null  // Disable while joining
                    : (_isUserMember ? _navigateToChat : _joinCommunity),
                child: memberState is JoiningCommunity
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(_isUserMember ? 'Chat Now' : 'Join Community'),
              ),
            ),
            
            // Show leave button if user is a member but not an admin
            if (_isUserMember && !_isUserAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _showLeaveConfirmationDialog,
                  child: const Text('Leave'),
                ),
              ),
            
            // Show delete button if user is admin
            if (_isUserAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _showDeleteConfirmationDialog,
                  child: const Text('Delete'),
                ),
              ),
          ],
        );
      },
    );
  }
  
  // Separate widget for About tab
  Widget _buildAboutTab(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (context.read<CommunityCubit>().state is! CommunityDetailLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
    
    return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
        // About Section
              Card(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About this Community',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                _buildInfoItem(
                        context,
                        Icons.calendar_today,
                        'Created',
                        'on ${_formatDate(community.createdAt)}',
                      ),
                _buildInfoItem(
                        context,
                        Icons.category,
                        'Category',
                        community.category,
                      ),
                _buildInfoItem(
                        context,
                  Icons.visibility,
                        'Visibility',
                        community.isPrivate ? 'Private community' : 'Public community',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
        
              // Rules Section - Using the new method
              _buildRulesContent(context, community),
            ],
    );
  }
  
  // Add this method to show edit rules dialog
  void _showEditRulesDialog(BuildContext context, Community community) {
    final List<TextEditingController> controllers = community.rules.map((rule) => 
      TextEditingController(text: rule)
    ).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Community Rules'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controllers[index],
                        decoration: InputDecoration(
                          labelText: 'Rule ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        if (controllers.length > 1) {
                          setState(() {
                            controllers.removeAt(index);
                          });
                          Navigator.of(context).pop();
                          _showEditRulesDialog(context, community);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controllers.add(TextEditingController(text: 'New rule'));
              Navigator.of(context).pop();
              _showEditRulesDialog(context, community);
            },
            child: const Text('Add Rule'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final List<String> newRules = controllers.map((c) => c.text.trim()).toList();
              
              // Update community with new rules
              if (context.read<CommunityCubit>().state is CommunityDetailLoaded) {
                final currentCommunity = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
                
                // Create updated community model
                final CommunityModel updatedCommunity = CommunityModel(
                  id: currentCommunity.id,
                  name: currentCommunity.name,
                  description: currentCommunity.description,
                  category: currentCommunity.category,
                  iconUrl: currentCommunity.iconUrl,
                  rulesPictureUrl: currentCommunity.rulesPictureUrl,
                  memberCount: currentCommunity.memberCount,
                  createdBy: currentCommunity.createdBy,
                  isPrivate: currentCommunity.isPrivate,
                  createdAt: currentCommunity.createdAt,
                  rules: newRules,
                );
                
                try {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Updating community rules...'),
                        ],
                      ),
                    ),
                  );
                  
                  // Update community
                  await context.read<CommunityCubit>().updateCommunity(updatedCommunity);
                  
                  // Close loading dialog
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Close edit dialog
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Community rules updated successfully')),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update rules: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Separate widget for Members tab
  Widget _buildMembersTab() {
    final Map<String, CommunityMember> uniqueMembers = {};
    
    return BlocConsumer<CommunityMemberCubit, CommunityMemberState>(
      listener: (context, state) {
        if (state is CommunityMembersLoaded) {
          _updateMemberStatus(state.members);
        }
      },
      builder: (context, state) {
        if (state is CommunityMembersLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          );
        } else if (state is CommunityMembersLoaded) {
          final members = state.members;
          
          // Debug: print members
          print("Found ${members.length} members");
          for (var member in members) {
            print("Member: ${member.userName} (${member.userId}), Avatar: ${member.userAvatar}");
            uniqueMembers[member.userId] = member;
          }
          
          final uniqueMembersList = uniqueMembers.values.toList();
          
          if (uniqueMembersList.isEmpty) {
            return Center(
              child: Text(
                'No members found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            );
          }
          
          // Sort members: admins first, then moderators, then regular members
          uniqueMembersList.sort((a, b) {
            if (a.role == MemberRole.admin && b.role != MemberRole.admin) {
              return -1;
            }
            if (a.role != MemberRole.admin && b.role == MemberRole.admin) {
              return 1;
            }
            if (a.role == MemberRole.moderator && b.role == MemberRole.member) {
              return -1;
            }
            if (a.role == MemberRole.member && b.role == MemberRole.moderator) {
              return 1;
            }
            return a.userName.compareTo(b.userName);
          });
          
          // Ensure all members are displayed
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CommunityMemberCubit>().getCommunityMembers(widget.communityId);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: uniqueMembersList.length,
              itemBuilder: (context, index) {
                final member = uniqueMembersList[index];
                return GestureDetector(
                  onTap: _isUserAdmin ? () => _showManageMemberOptions(member) : null,
                  child: _buildMemberItem(context, member),
                );
              },
            ),
          );
        } else if (state is CommunityMemberError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          );
        }
        
        // Ensure members are loaded when the tab is shown
        if (mounted) {
          Future.microtask(() => 
            context.read<CommunityMemberCubit>().getCommunityMembers(widget.communityId)
          );
        }
        
        return Center(
          child: Text(
            'Loading members...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
        ),
        const SizedBox(width: 16.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, CommunityMember member) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          backgroundImage: member.userAvatar.isNotEmpty 
              ? NetworkImage(member.userAvatar) 
              : null,
          child: member.userAvatar.isEmpty
              ? Text(
                  member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
      ),
      title: Text(
        member.userName,
        style: TextStyle(
            fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
        _getRoleText(member.role),
        style: TextStyle(
                  fontSize: 12,
                  color: _getRoleColor(member.role),
        ),
      ),
            ),
            const SizedBox(width: 8),
            Text(
        'Joined ${_formatDate(member.joinedAt)}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
        ),
            ),
          ],
        ),
        trailing: _isUserAdmin && member.userId != _currentUserId
            ? const Icon(Icons.more_vert)
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting, can be enhanced with intl package
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getRoleText(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.moderator:
        return 'Moderator';
      case MemberRole.member:
      default:
        return 'Member';
    }
  }
  
  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return Colors.red;
      case MemberRole.moderator:
        return Colors.blue;
      case MemberRole.member:
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (context.read<CommunityCubit>().state is! CommunityDetailLoaded) {
      return Container(
        height: 200,
        color: Theme.of(context).colorScheme.primary,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    
    final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Background image
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            image: _isImageLoading ? null : DecorationImage(
              image: CachedNetworkImageProvider(community.iconUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
          ),
          // Show loading indicator while image loads
          child: _isImageLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : null,
        ),
        
        // Community name and edit button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUserAdmin)
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: _showEditCommunityDialog,
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> _updateCommunityImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    setState(() {
      _isImageLoading = true;
    });
    
    if (context.read<CommunityCubit>().state is! CommunityDetailLoaded) return;
    
    try {
      final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
      
      // Upload image to storage
      final storage = FirebaseStorageRepo();
      final imagePath = 'communities/${community.id}/profile.jpg';
      final File imageFile = File(image.path);
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              StreamBuilder<double>(
                stream: storage.uploadProgressStream,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? 0.0;
                  return Column(
                    children: [
                      Text('Uploading image: ${(progress * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
      
      // Upload the image
      final imageUrl = await storage.uploadFile(imageFile.path, imagePath);
      
      // Create updated community model
      final updatedCommunity = CommunityModel(
        id: community.id,
        name: community.name,
        description: community.description,
        category: community.category,
        iconUrl: imageUrl ?? community.iconUrl, // Use existing URL if upload failed
        rulesPictureUrl: community.rulesPictureUrl,
        memberCount: community.memberCount,
        createdBy: community.createdBy,
        isPrivate: community.isPrivate,
        createdAt: community.createdAt,
        rules: community.rules,
      );
      
      // Update community in database
      await context.read<CommunityCubit>().updateCommunity(updatedCommunity);
      
      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community image updated successfully')),
        );
      }
      
      // Reload community
      if (mounted) {
        context.read<CommunityCubit>().getCommunityById(community.id);
      }
    } catch (e) {
      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update community image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  // Add a new method to change the rules picture
  Future<void> _changeRulesPicture() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final File imageFile = File(pickedFile.path);
      final storage = FirebaseStorageRepo();
      final path = 'communities/${widget.communityId}_rules_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final url = await storage.uploadFile(imageFile.path, path) ?? '';
      
      if (url.isNotEmpty && context.read<CommunityCubit>().state is CommunityDetailLoaded) {
        final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
        final updatedCommunity = CommunityModel(
          id: community.id,
          name: community.name,
          description: community.description,
          category: community.category,
          iconUrl: community.iconUrl,
          rulesPictureUrl: url,
          memberCount: community.memberCount,
          createdBy: community.createdBy,
          isPrivate: community.isPrivate,
          createdAt: community.createdAt,
          rules: community.rules,
        );
        
        context.read<CommunityCubit>().updateCommunity(updatedCommunity);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rules picture updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update rules picture: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the _buildRulesContent method to include rules picture
  Widget _buildRulesContent(BuildContext context, Community community) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                if (_isUserAdmin)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _showEditRulesDialog(context, community),
                    tooltip: 'Edit Rules',
                  ),
              ],
            ),
            
            // Add Rules Picture if it exists
            if (community.rulesPictureUrl.isNotEmpty)
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        community.rulesPictureUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey.withOpacity(0.3),
                            child: const Center(
                              child: Text('Image not available'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Add edit button for admin to change rules picture
                  if (_isUserAdmin)
                    Positioned(
                      right: 8,
                      bottom: 20,
                      child: FloatingActionButton.small(
                        onPressed: _changeRulesPicture,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.camera_alt),
                      ),
                    ),
                ],
              )
            else if (_isUserAdmin)
              // Show add rules picture button for admin
              InkWell(
                onTap: _changeRulesPicture,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Rules Picture',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16.0),
            ...community.rules.map((rule) => _buildRuleItem(context, rule)).toList(),
          ],
        ),
      ),
    );
  }

  // Update the _updateCommunity method to include rulesPictureUrl
  void _updateCommunity(
    String name,
    String description,
    String category,
    bool isPrivate,
  ) async {
    if (context.read<CommunityCubit>().state is CommunityDetailLoaded) {
      final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
      
      final updatedCommunity = CommunityModel(
        id: community.id,
        name: name.trim(),
        description: description.trim(),
        category: category,
        iconUrl: community.iconUrl,
        rulesPictureUrl: community.rulesPictureUrl,
        memberCount: community.memberCount,
        createdBy: community.createdBy,
        isPrivate: isPrivate,
        createdAt: community.createdAt,
        rules: community.rules,
      );
      
      context.read<CommunityCubit>().updateCommunity(updatedCommunity);
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 
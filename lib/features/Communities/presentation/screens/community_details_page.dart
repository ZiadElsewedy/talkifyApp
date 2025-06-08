import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community.dart';
import '../../domain/Entites/community_member.dart';
import '../cubit/community_cubit.dart';
import '../cubit/community_member_cubit.dart';
import '../cubit/community_state.dart';
import '../cubit/community_member_state.dart';
import 'community_chat_page.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:talkifyapp/features/Storage/Data/Filebase_Storage_repo.dart';
import 'package:collection/collection.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'dart:async';

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
    
    // Get the chat room for this community
    chatCubit.getChatRoomForCommunity(community.id);
    
    // Create a subscription variable before using it
    late StreamSubscription subscription;
    
    // Listen for the result in a separate listener
    subscription = chatCubit.stream.listen((state) {
      // Check if still mounted before using context
      if (!mounted) {
        subscription.cancel();
        return;
      }
      
      if (state is ChatRoomForCommunityLoaded) {
        // Close the loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Navigate to chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoom: state.chatRoom,
            ),
          ),
        );
        
        // Cancel subscription after navigation
        subscription.cancel();
      } else if (state is ChatRoomForCommunityNotFound || state is ChatRoomForCommunityError) {
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
      }
    }, onError: (error) {
      // Check if still mounted before using context
      if (!mounted) {
        subscription.cancel();
        return;
      }
      
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      
      // Cancel subscription after error
      subscription.cancel();
    });
    
    // Add to subscriptions list for proper disposal
    _subscriptions.add(subscription);
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
    if (!(context.read<CommunityCubit>().state is CommunityDetailLoaded)) return;
    
    final community = (context.read<CommunityCubit>().state as CommunityDetailLoaded).community;
    final nameController = TextEditingController(text: community.name);
    final descriptionController = TextEditingController(text: community.description);
    bool isPrivate = community.isPrivate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Community'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Community Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Private Community'),
                      const Spacer(),
                      Switch(
                        value: isPrivate,
                        onChanged: (value) {
                          setState(() {
                            isPrivate = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedCommunity = Community(
                    id: community.id,
                    name: nameController.text,
                    description: descriptionController.text,
                    category: community.category,
                    iconUrl: community.iconUrl,
                    memberCount: community.memberCount,
                    createdBy: community.createdBy,
                    isPrivate: isPrivate,
                    createdAt: community.createdAt,
                  );
                  
                  context.read<CommunityCubit>().updateCommunity(updatedCommunity);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Community updated')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
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
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.inversePrimary,
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
                        Icons.category,
                        community.category,
                      ),
                      _buildInfoItem(
                        context,
                        Icons.people,
                        '${community.memberCount} members',
                      ),
                      _buildInfoItem(
                        context,
                        community.isPrivate ? Icons.lock : Icons.public,
                        community.isPrivate ? 'Private' : 'Public',
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
          _buildAboutTab(community),
          
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
  Widget _buildAboutTab(Community community) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
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
                _buildAboutItem(
                  context,
                  Icons.calendar_today,
                  'Created',
                  'on ${_formatDate(community.createdAt)}',
                ),
                const SizedBox(height: 12.0),
                _buildAboutItem(
                  context,
                  Icons.category,
                  'Category',
                  community.category,
                ),
                const SizedBox(height: 12.0),
                _buildAboutItem(
                  context,
                  community.isPrivate ? Icons.lock : Icons.public,
                  'Visibility',
                  community.isPrivate ? 'Private community' : 'Public community',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
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
                  'Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 16.0),
                _buildRuleItem(context, '1. Be respectful to others'),
                _buildRuleItem(context, '2. No spam or self-promotion'),
                _buildRuleItem(context, '3. Stay on topic'),
                _buildRuleItem(context, '4. No hate speech or harassment'),
                _buildRuleItem(context, '5. Follow the community guidelines'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Separate widget for Members tab
  Widget _buildMembersTab() {
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
          
          // Remove duplicate members by userId
          final uniqueMembers = <String, CommunityMember>{};
          for (final member in members) {
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
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: uniqueMembersList.length,
            itemBuilder: (context, index) {
              final member = uniqueMembersList[index];
              return GestureDetector(
                onTap: _isUserAdmin ? () => _showManageMemberOptions(member) : null,
                child: _buildMemberItem(context, member),
              );
            },
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

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
        ),
        const SizedBox(width: 4.0),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
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
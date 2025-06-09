import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community_member.dart';
import 'package:talkifyapp/features/Communities/domain/repo/community_repository.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_member_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_state.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_member_state.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/community_details_page.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/create_community_page.dart';
import 'package:talkifyapp/features/Chat/Utils/page_transitions.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'dart:async';

class CommunitiesTab extends StatelessWidget {
  const CommunitiesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MultiBlocProvider to provide both CommunityMemberCubit and CommunityCubit
    return MultiBlocProvider(
      providers: [
        BlocProvider(
      create: (context) => CommunityCubit(
        repository: CommunityRepositoryImpl(),
      )..getAllCommunities(),
        ),
        BlocProvider(
          create: (context) => CommunityMemberCubit(
            repository: CommunityRepositoryImpl(),
          ),
        ),
      ],
      child: const _CommunitiesTabContent(),
    );
  }
}

class _CommunitiesTabContent extends StatefulWidget {
  const _CommunitiesTabContent({Key? key}) : super(key: key);

  @override
  State<_CommunitiesTabContent> createState() => _CommunitiesTabContentState();
}

class _CommunitiesTabContentState extends State<_CommunitiesTabContent> {
  String? _currentUserId;
  // Map to track which communities the current user is a member of
  Map<String, MemberRole> _membershipStatus = {};
  bool _isLoadingMembership = false;
  
  // Stream subscriptions to manage lifecycle
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthCubit>().GetCurrentUser()?.id;
    
    // Store local references to cubits to prevent context usage after unmount
    final memberCubit = context.read<CommunityMemberCubit>();
    final communityCubit = context.read<CommunityCubit>();
    
    // Add listener to the community member cubit to handle leave operations
    final memberSubscription = memberCubit.stream.listen((state) {
      // Always check mounted before using context or calling setState
      if (!mounted) return;
      
      if (state is LeftCommunitySuccessfully) {
        // Reload communities list
        communityCubit.getAllCommunities();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left the community'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (state is CommunityMemberError) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${state.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    _subscriptions.add(memberSubscription);
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions when disposing
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CommunityCubit, CommunityState>(
      listener: (context, state) {
        if (state is CommunitiesLoaded && _currentUserId != null) {
          // Check membership status for communities when they're loaded
          _checkMembershipStatusAsync(state.communities);
        }
      },
      builder: (context, state) {
        if (state is CommunitiesLoading) {
          return const Center(
            child: PercentCircleIndicator(),
          );
        } else if (state is CommunitiesLoaded) {
          final communities = state.communities;
          
          if (communities.isEmpty) {
            return _buildEmptyCommunities(context, isDarkMode);
          }
          
          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () async {
              context.read<CommunityCubit>().getAllCommunities();
              // Clear membership cache
              SchedulerBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _membershipStatus.clear();
                });
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return _buildCommunityCard(context, community, isDarkMode);
              },
            ),
          );
        } else if (state is CommunityError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading communities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<CommunityCubit>().getAllCommunities();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
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
        
        // Initial state
        return const Center(
          child: PercentCircleIndicator(),
        );
      },
    );
  }
  
  // Check membership status for all communities asynchronously
  // This is called from the BlocListener, not during build
  Future<void> _checkMembershipStatusAsync(List<Community> communities) async {
    if (_currentUserId == null || _isLoadingMembership) return;
    
    // Set loading flag using post-frame callback to avoid build during frame
    _isLoadingMembership = true;
    
    // Process communities in batches to avoid excessive API calls
    final batch = <Future<void>>[];
    for (final community in communities) {
      if (!_membershipStatus.containsKey(community.id)) {
        batch.add(_checkSingleCommunityMembership(community.id));
      }
    }
    
    // Wait for all checks to complete
    await Future.wait(batch);
    
    // Reset loading flag using post-frame callback
    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isLoadingMembership = false;
        });
      });
    }
  }
  
  // Check membership for a single community
  Future<void> _checkSingleCommunityMembership(String communityId) async {
    if (_currentUserId == null || !mounted) return;
    
    try {
      // Store local reference to cubit
      final memberCubit = context.read<CommunityMemberCubit>();
      
      final role = await memberCubit.getUserRole(communityId, _currentUserId!);
      if (mounted && role != null) {
        // Update state in post frame callback
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Double check mounted before setState
            setState(() {
              _membershipStatus[communityId] = role;
            });
          }
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  Widget _buildCommunityCard(BuildContext context, Community community, bool isDarkMode) {
    final bool isMember = _membershipStatus.containsKey(community.id);
    final bool isAdmin = _membershipStatus[community.id] == MemberRole.admin;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.slideRightTransition(
              page: CommunityDetailsPage(communityId: community.id),
            ),
          ).then((_) {
            // Reload communities and clear membership cache when returning
            context.read<CommunityCubit>().getAllCommunities();
            setState(() {
              _membershipStatus.remove(community.id);
            });
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: community.iconUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              community.iconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.people,
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.people,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              size: 30,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          community.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show chat icon for joined communities
                  if (isMember)
                    IconButton(
                      icon: Icon(
                        Icons.chat,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _navigateToCommunityChat(community),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        community.category,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${community.memberCount} members',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        community.isPrivate ? Icons.lock : Icons.public,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        community.isPrivate ? 'Private' : 'Public',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Show action buttons for members/admins
              if (isMember) 
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Leave group button for members
                      if (!isAdmin)
                        TextButton.icon(
                          icon: const Icon(Icons.exit_to_app, size: 16),
                          label: const Text('Leave'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => _showLeaveGroupDialog(community),
                        ),
                      
                      // Admin actions
                      if (isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.admin_panel_settings,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            onSelected: (value) {
                              if (value == 'close') {
                                _showCloseGroupDialog(community);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'close',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Close Group',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Navigate to community chat
  void _navigateToCommunityChat(Community community) {
    if (!mounted) return;
    
    // Store local reference to cubit
    final chatCubit = context.read<ChatCubit>();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening community chat...'),
          ],
        ),
      ),
    );
    
    // Get the chat room for this community
    chatCubit.getChatRoomForCommunity(community.id);
    
    // Create the subscription variable before using it
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
        
        // Navigate to chat
        Navigator.push(
          context, 
          PageTransitions.slideRightTransition(
            page: ChatRoomPage(
              chatRoom: state.chatRoom,
            ),
          ),
        );
        
        // Cancel subscription after navigation
        subscription.cancel();
      } else if (state is ChatRoomForCommunityError || state is ChatRoomForCommunityNotFound) {
        // Close the loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open community chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
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
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Cancel subscription after error
      subscription.cancel();
    });
    
    // Add to subscriptions list for proper disposal
    _subscriptions.add(subscription);
  }
  
  // Show confirmation dialog for leaving a group
  void _showLeaveGroupDialog(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${community.name}?'),
        content: Text('Are you sure you want to leave this community? You can always join again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup(community.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }
  
  // Show confirmation dialog for closing a group
  void _showCloseGroupDialog(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close ${community.name}?'),
        content: Text(
          'Are you sure you want to close this community? '
          'This action will permanently delete the community and cannot be undone. '
          'All messages and member data will be lost.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _closeGroup(community.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Close Group'),
          ),
        ],
      ),
    );
  }
  
  // Leave a group implementation
  void _leaveGroup(String communityId) {
    if (_currentUserId == null || !mounted) return;
    
    // Store local reference to cubit
    final memberCubit = context.read<CommunityMemberCubit>();
    
    // Update UI after the current frame is complete
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Check if still mounted
      
      setState(() {
        _membershipStatus.remove(communityId);
      });
      
      // Show a temporary snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Leaving community...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    });
    
    // Call the leave community method
    memberCubit.leaveCommunity(communityId, _currentUserId!);
  }
  
  // Close a group implementation
  void _closeGroup(String communityId) {
    // Delete the community
    context.read<CommunityCubit>().deleteCommunity(communityId);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocListener<CommunityCubit, CommunityState>(
        listener: (context, state) {
          if (state is CommunityDeletedSuccessfully) {
            // Update membership status
            setState(() {
              _membershipStatus.remove(communityId);
            });
            
            // Reload communities list
            context.read<CommunityCubit>().getAllCommunities();
            
            // Close dialog and show success message
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Community has been closed'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CommunityError) {
            // Close dialog and show error message
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to close the community: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Closing community...'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyCommunities(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 70,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No communities found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or join a community to get started',
              style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                PageTransitions.slideRightTransition(
                  page: const CreateCommunityPage(),
                ),
              ).then((_) {
                // Reload communities when returning
                context.read<CommunityCubit>().getAllCommunities();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a Community'),
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
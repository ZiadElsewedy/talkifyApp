import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community.dart';
import '../../domain/Entites/community_member.dart';
import '../cubit/community_cubit.dart';
import '../cubit/community_member_cubit.dart';
import '../cubit/community_state.dart';
import '../cubit/community_member_state.dart';
import 'community_chat_page.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunityDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCommunityDetails() {
    context.read<CommunityCubit>().getCommunityById(widget.communityId);
    context.read<CommunityMemberCubit>().getCommunityMembers(widget.communityId);
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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                community.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                color: Theme.of(context).colorScheme.primary,
                child: community.iconUrl.isNotEmpty
                    ? Image.network(
                        community.iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.people,
                              color: Theme.of(context).colorScheme.surface,
                              size: 60,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.people,
                          color: Theme.of(context).colorScheme.surface,
                          size: 60,
                        ),
                      ),
              ),
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
              IconButton(
                icon: Icon(
                  Icons.chat,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityChatPage(
                        communityId: community.id,
                        communityName: community.name,
                      ),
                    ),
                  );
                },
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
                  
                  // Join button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        // Mock user ID, replace with actual auth implementation
                        const userId = 'current_user_id';
                        context
                            .read<CommunityMemberCubit>()
                            .joinCommunity(community.id, userId);
                      },
                      child: BlocBuilder<CommunityMemberCubit, CommunityMemberState>(
                        builder: (context, state) {
                          if (state is JoiningCommunity) {
                            return SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.surface,
                                strokeWidth: 2.0,
                              ),
                            );
                          }
                          return const Text('Join Community');
                        },
                      ),
                    ),
                  ),
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
          ListView(
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
          ),
          
          // Members tab
          BlocBuilder<CommunityMemberCubit, CommunityMemberState>(
            builder: (context, state) {
              if (state is CommunityMembersLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                );
              } else if (state is CommunityMembersLoaded) {
                final members = state.members;
                if (members.isEmpty) {
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
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _buildMemberItem(context, member);
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
          ),
        ],
      ),
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
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: member.userAvatar.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.network(
                  member.userAvatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.surface,
                        size: 20,
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.surface,
                  size: 20,
                ),
              ),
      ),
      title: Text(
        member.userName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      subtitle: Text(
        _getRoleText(member.role),
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
        ),
      ),
      trailing: Text(
        'Joined ${_formatDate(member.joinedAt)}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
        ),
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community.dart';
import 'package:talkifyapp/features/Communities/domain/repo/community_repository.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_state.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/community_details_page.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/create_community_page.dart';
import 'package:talkifyapp/features/Chat/Utils/page_transitions.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';

class CommunitiesTab extends StatelessWidget {
  const CommunitiesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunityCubit(
        repository: CommunityRepositoryImpl(),
      )..getAllCommunities(),
      child: const _CommunitiesTabContent(),
    );
  }
}

class _CommunitiesTabContent extends StatelessWidget {
  const _CommunitiesTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CommunityCubit, CommunityState>(
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
  
  Widget _buildCommunityCard(BuildContext context, Community community, bool isDarkMode) {
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
            // Reload communities when returning
            context.read<CommunityCubit>().getAllCommunities();
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 60,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No communities yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create or join a community to connect with people sharing similar interests',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                PageTransitions.zoomTransition(
                  page: const CreateCommunityPage(),
                ),
              ).then((_) {
                // Reload communities when returning
                context.read<CommunityCubit>().getAllCommunities();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a community'),
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community.dart';
import '../cubit/community_cubit.dart';
import '../cubit/community_state.dart';
import 'community_details_page.dart';
import 'create_community_page.dart';

class CommunityHomePage extends StatefulWidget {
  const CommunityHomePage({Key? key}) : super(key: key);

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadCommunities() {
    context.read<CommunityCubit>().getAllCommunities();
  }

  void _searchCommunities(String query) {
    if (query.isEmpty) {
      _loadCommunities();
    } else {
      context.read<CommunityCubit>().searchCommunities(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
              decoration: InputDecoration(
                hintText: 'Search communities...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6)),
                border: InputBorder.none,
              ),
              onChanged: _searchCommunities,
            )
          : Text(
              'Communities',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadCommunities();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityPage(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.inversePrimary,
          labelColor: Theme.of(context).colorScheme.inversePrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Trending'),
          ],
          onTap: (index) {
            if (index == 0) {
              context.read<CommunityCubit>().getAllCommunities();
            } else {
              context.read<CommunityCubit>().getTrendingCommunities();
            }
          },
        ),
      ),
      body: BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) {
          if (state is CommunitiesLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            );
          } else if (state is CommunitiesLoaded) {
            final communities = state.communities;
            if (communities.isEmpty) {
              return Center(
                child: Text(
                  'No communities found',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return _buildCommunityCard(context, community);
              },
            );
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
              'Start by exploring or creating a community',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailsPage(communityId: community.id),
            ),
          );
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
                      color: Theme.of(context).colorScheme.primary,
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
                                    color: Theme.of(context).colorScheme.surface,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.people,
                              color: Theme.of(context).colorScheme.surface,
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
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          community.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
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
                        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        community.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${community.memberCount} members',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        community.isPrivate ? Icons.lock : Icons.public,
                        size: 16,
                        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        community.isPrivate ? 'Private' : 'Public',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
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
} 
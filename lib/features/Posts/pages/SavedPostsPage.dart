import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({Key? key}) : super(key: key);

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.GetCurrentUser();
    if (user != null) {
      context.read<PostCubit>().fetchSavedPosts(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50;
    final Color appBarColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final Color titleColor = isDarkMode ? Colors.white : Colors.black87;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.black87;
    final Color emptyTextColor = isDarkMode ? Colors.grey[300]! : Colors.grey.shade800;
    final Color emptySubTextColor = isDarkMode ? Colors.grey[500]! : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: Text(
          'Saved Posts',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: iconColor),
      ),
      backgroundColor: backgroundColor,
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PostsError) {
            return Center(child: Text('Error: ${state.message}', style: TextStyle(color: titleColor)));
          }
          if (state is PostsLoaded) {
            if (state.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 48, color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No saved posts yet',
                      style: TextStyle(
                        color: emptyTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save posts to see them here.',
                      style: TextStyle(
                        color: emptySubTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                final user = context.read<AuthCubit>().GetCurrentUser();
                if (user != null) {
                  await context.read<PostCubit>().fetchSavedPosts(user.id);
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: state.posts.length,
                itemBuilder: (context, index) {
                  final post = state.posts[index];
                  return PostTile(post: post);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
} 
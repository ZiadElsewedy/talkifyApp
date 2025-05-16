import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/pages/upload_post_page.dart' show UploadPostPage;
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mydrawer.dart';

class HomePage extends StatefulWidget {
   HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  late final postCubit = context.read<PostCubit>();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    await postCubit.fetechAllPosts();
  }

  Future<void> deletePost(String postId) async {
    try {
      await postCubit.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the posts list after deletion
        await fetchPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          // upload new post button
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UploadPostPage(),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          if (state is PostsUploading || state is PostsLoading) {
            return const Center(child: PercentCircleIndicator());
          } else if (state is PostsLoaded) {
            final allPosts = state.posts;

            if (allPosts.isEmpty) {
              return const Center(child: Text('No posts yet'));
            } else {
              return RefreshIndicator(
                color: Colors.black,
                onRefresh: fetchPosts,
                child: ListView.builder(
                  itemCount: allPosts.length,
                  itemBuilder: (context, index) {
                    final post = allPosts[index];
                    return PostTile(
                      post: post,
                      onDelete: () => deletePost(post.id),
                    );
                  },
                ),
              );
            }
          } else if (state is PostsError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text('No posts available'));
        },
      ),
    );
  }
}


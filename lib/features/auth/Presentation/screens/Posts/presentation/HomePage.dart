import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    postCubit.fetechAllPosts();
    super.initState();
  }

  void FetchPosts(){
    postCubit.fetechAllPosts();
    // 
  }
  void deletePost(String postId){
    postCubit.deletePost(postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
        // upload new post button
        IconButton(
          onPressed: () => Navigator.push(
            context,
             MaterialPageRoute(
              builder: (context) => const UploadPostPage())),
           icon: const Icon(Icons.add))
        ],
      ),
      drawer: MyDrawer(),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          if (state is PostsUploading || state is PostsLoading) {
            return const Center(child: CircularProgressIndicator());
          } 
          else if (state is PostsLoaded) {
            final allPosts = state.posts;
            
            if(allPosts.isEmpty){
              return const Center(child: Text('No posts yet'));
            }
            else{
              return ListView.builder(
                itemCount: allPosts.length,
                itemBuilder: (context, index) {
                  final post = allPosts[index];
                  return PostTile(post: post);
                },
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


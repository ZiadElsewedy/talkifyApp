import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  // mobile image picker
  PlatformFile? imagepickedfile;

  // web image picker
  Uint8List? webImage;

  // text controller -> caption
  final TextController = TextEditingController();

  // current user
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  // get current user
  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.GetCurrentUser();
  }


  // Pick image
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    
    if (result != null ) {
      setState(() {
        imagepickedfile = result.files.first;
      

      if (kIsWeb) {
        webImage = imagepickedfile!.bytes;
      }
      });
    }
  }


  // create & upload post
  void uploadPost() {
    if (imagepickedfile == null || TextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both image and caption are required'))
      );
      return;
    }

    // create a new post
    final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        UserId: currentUser!.id,
        UserName: currentUser!.name,
        Text: TextController.text,
        imageUrl: '',
        timestamp: DateTime.now(),
    );


    // post cubit 
    final postCubit = context.read<PostCubit>(); 

    // web upload 
    if (kIsWeb) {
      postCubit.createPost(newPost, imageBytes: imagepickedfile?.bytes);
    }


    // mobile upload 
    else {
      postCubit.createPost(newPost, imagePath: imagepickedfile?.path);
    }
  }

  @override
  void dispose() {
    TextController.dispose();
    super.dispose();
  }

  // Build UI
  @override
  Widget build(BuildContext context) {

    // Block consumer -> builder + listener
    return BlocConsumer<PostCubit, PostState>(
      builder: (context, state) {
        // Loading or uploading 
        if (state is PostsLoading || state is PostsUploading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // build upload page 
        return buildUploadPage();
        
      },
      // go to previous page when the upload is done & the posts are loaded
      listener: (context, state) {
        if (state is PostsLoaded) {
          Navigator.pop(context);
        } 
      }
    );
  }

  Widget buildUploadPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Post'),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          // upload button 
          IconButton(
            onPressed: uploadPost,
            icon: const Icon(Icons.upload),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            // image perview for web 
            if (kIsWeb)
              Image.memory(webImage!),

            // image picker for mobile 
            if (!kIsWeb && webImage != null)
              Image.file(File(imagepickedfile!.path!)),

            // pick image button 
            MaterialButton(
              onPressed: pickImage,
              color: Colors.blue,
              child: const Text('Pick Image'),
            ),

            // caption text box 
            MyTextField(
              controller: TextController,
              hintText: "Caption",
              obsecureText: false,
            ),
            
            
          ],
        ),
      ),
    );
  }
}
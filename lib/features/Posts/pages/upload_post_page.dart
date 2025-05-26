import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';
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
  File? croppedImageFile;

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
    
    if (result != null) {
      setState(() {
        imagepickedfile = result.files.first;
        if (kIsWeb) {
          webImage = imagepickedfile!.bytes;
        }
      });
      
      // Open image editor if not on web
      if (!kIsWeb && imagepickedfile != null) {
        await _cropImage();
      }
    }
  }
  
  // Crop and edit image
  Future<void> _cropImage() async {
    if (imagepickedfile == null) return;
    
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagepickedfile!.path!,
      compressQuality: 90,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: Colors.black,
        ),
        IOSUiSettings(
          title: 'Edit Photo',
          aspectRatioLockEnabled: false,
          minimumAspectRatio: 1.0,
          aspectRatioPickerButtonHidden: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        croppedImageFile = File(croppedFile.path);
      });
    }
  }

  // Edit current image
  void editCurrentImage() async {
    if (imagepickedfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first'))
      );
      return;
    }
    
    await _cropImage();
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
        UserProfilePic: currentUser!.profilePictureUrl,
        Text: TextController.text,
        imageUrl: '',
        timestamp: DateTime.now(),
        likes: [],
        comments: [],
    );


    // post cubit 
    final postCubit = context.read<PostCubit>(); 

    // web upload 
    if (kIsWeb) {
      postCubit.createPost(newPost, imageBytes: imagepickedfile?.bytes);
    }
    // mobile upload - use cropped image if available
    else {
      final String? imagePath = croppedImageFile?.path ?? imagepickedfile?.path;
      postCubit.createPost(newPost, imagePath: imagePath);
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
              child: PercentCircleIndicator(),
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
        title: const Text('Create Post'),
        foregroundColor: Colors.black,
        actions: [
          // upload button 
          IconButton(
            onPressed: uploadPost,
            icon: const Icon(Icons.upload),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Image preview section
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imagepickedfile != null
                      ? kIsWeb
                          ? Image.memory(
                              webImage!,
                              fit: BoxFit.cover,
                            )
                          : croppedImageFile != null
                              ? Image.file(
                                  croppedImageFile!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(imagepickedfile!.path!),
                                  fit: BoxFit.cover,
                                )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No image selected',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Image buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pick image button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                      label: const Text('Select Photo', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit image button (only shown when image is selected)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: imagepickedfile != null && !kIsWeb ? editCurrentImage : null,
                      icon: const Icon(Icons.crop, color: Colors.white),
                      label: const Text('Edit Photo', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: imagepickedfile != null && !kIsWeb ? Colors.black : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Caption text box
              MyTextField(
                controller: TextController,
                hintText: "Write a caption...",
                obsecureText: false,
              ),
              
              const SizedBox(height: 20),
              
              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: uploadPost,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text('Share Post', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
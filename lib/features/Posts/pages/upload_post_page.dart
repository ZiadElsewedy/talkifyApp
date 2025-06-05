import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:talkifyapp/features/Posts/PostComponents/VideoUploadIndicator.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:video_player/video_player.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  // mobile file picker
  PlatformFile? pickedFile;
  File? croppedImageFile;
  
  // video player controller
  VideoPlayerController? _videoController;
  bool isVideo = false;

  // web image/video picker
  Uint8List? webFile;

  // text controller -> caption
  final TextController = TextEditingController();

  // current user
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    TextController.dispose();
    super.dispose();
  }

  // get current user
  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.GetCurrentUser();
  }

  // Pick media (image or video)
  Future<void> pickMedia(FileType fileType) async {
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      withData: kIsWeb,
    );
    
    if (result != null) {
      // Check if we're dealing with a video
      isVideo = fileType == FileType.video;

      setState(() {
        pickedFile = result.files.first;
        if (kIsWeb) {
          webFile = pickedFile!.bytes;
        }
      });
      
      // Setup video controller if it's a video
      if (isVideo) {
        if (_videoController != null) {
          _videoController!.dispose();
        }
        
        if (kIsWeb) {
          // Handle web video preview
          // Note: Web video playback from memory is complex
          // This is just a placeholder
        } else {
          // Handle mobile video preview
          _videoController = VideoPlayerController.file(
            File(pickedFile!.path!),
          )
          ..initialize().then((_) {
            setState(() {});
          });
        }
      }
      // Open image editor if it's an image and not on web
      else if (!kIsWeb && pickedFile != null) {
        await _cropImage();
      }
    }
  }
  
  // Pick image specifically
  Future<void> pickImage() async {
    await pickMedia(FileType.image);
  }
  
  // Pick video specifically
  Future<void> pickVideo() async {
    await pickMedia(FileType.video);
  }
  
  // Crop and edit image
  Future<void> _cropImage() async {
    if (pickedFile == null || isVideo) return;
    
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile!.path!,
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
    if (pickedFile == null || isVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first'))
      );
      return;
    }
    
    await _cropImage();
  }

  // create & upload post
  void uploadPost() {
    if (pickedFile == null || TextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both media and caption are required'))
      );
      return;
    }

    // Get the local file path for images or videos
    final String? localFilePath = isVideo || !kIsWeb ? pickedFile?.path : null;

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
        savedBy: [],
        isVideo: isVideo,
        localFilePath: localFilePath,
    );


    // post cubit 
    final postCubit = context.read<PostCubit>(); 

    // web upload 
    if (kIsWeb) {
      postCubit.createPost(newPost, imageBytes: pickedFile?.bytes);
    }
    // mobile upload - use cropped image if available
    else {
      final String? filePath = isVideo ? pickedFile?.path : (croppedImageFile?.path ?? pickedFile?.path);
      postCubit.createPost(newPost, imagePath: filePath);
    }
  }

  // Build UI
  @override
  Widget build(BuildContext context) {

    // Block consumer -> builder + listener
    return BlocConsumer<PostCubit, PostState>(
      builder: (context, state) {
        // Handle loading state
        if (state is PostsLoading) {
          return const Scaffold(
            body: Center(
              child: PercentCircleIndicator(),
            ),
          );
        }
        
        // Handle uploading with progress state
        if (state is PostsUploadingProgress) {
          // For video uploads, show preview with progress indicator
          if (state.post.isVideo && _videoController != null && _videoController!.value.isInitialized) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Uploading Video...'),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              body: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoUploadPreview(
                            progress: state.progress,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Your video is uploading... ${(state.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Please wait until upload completes',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: state.progress,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          // For image uploads or web
          return Scaffold(
            appBar: AppBar(
              title: const Text('Uploading Media...'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VideoUploadIndicator(progress: state.progress),
                    const SizedBox(height: 32),
                    Text(
                      'Uploading: ${(state.progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your post is being uploaded',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Handle generic uploading state
        if (state is PostsUploading) {
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
              // Media preview section
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pickedFile != null
                      ? isVideo
                          ? _buildVideoPreview()
                          : kIsWeb
                              ? Image.memory(
                                  webFile!,
                                  fit: BoxFit.cover,
                                )
                              : croppedImageFile != null
                                  ? Image.file(
                                      croppedImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(pickedFile!.path!),
                                      fit: BoxFit.cover,
                                    )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No media selected',
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

              // Media selection buttons row
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
                  // Pick video button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickVideo,
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      label: const Text('Select Video', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Edit image button (only shown when image is selected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !isVideo && pickedFile != null && !kIsWeb ? editCurrentImage : null,
                  icon: const Icon(Icons.crop, color: Colors.white),
                  label: const Text('Edit Photo', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isVideo && pickedFile != null && !kIsWeb ? Colors.black : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
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
                  label: const Text('Share Post', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build video preview widget
  Widget _buildVideoPreview() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
            ),
            child: IconButton(
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
                size: 40,
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
            ),
          ),
        ],
      );
    } else if (kIsWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('Video preview not available on web'),
            const SizedBox(height: 5),
            Text('Selected: ${pickedFile?.name ?? "Unknown"}',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    } else {
      return const Center(
        child: PercentCircleIndicator(
          color: Colors.black,
        ),
      );
    }
  }
}
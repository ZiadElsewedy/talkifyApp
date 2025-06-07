import 'dart:io';
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Posts/PostComponents/VideoUploadIndicator.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:video_player/video_player.dart';

/// A post tile that shows a post that is currently being uploaded
/// Designed to look similar to regular posts with upload indicators
class UploadingPostTile extends StatefulWidget {
  /// The post being uploaded
  final Post post;
  
  /// The upload progress (0.0 to 1.0)
  final double progress;
  
  const UploadingPostTile({
    Key? key,
    required this.post,
    required this.progress,
  }) : super(key: key);

  @override
  State<UploadingPostTile> createState() => _UploadingPostTileState();
}

class _UploadingPostTileState extends State<UploadingPostTile> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize video controller if it's a video with a local path
    if (widget.post.isVideo && widget.post.localFilePath != null) {
      _initializeLocalVideoController();
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeLocalVideoController() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.post.localFilePath!));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing local video: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.UserProfilePic.isNotEmpty
                  ? NetworkImage(widget.post.UserProfilePic)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: widget.post.UserProfilePic.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            title: Text(
              widget.post.UserName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          value: widget.progress,
                          strokeWidth: 1.5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(widget.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Uploading...', style: TextStyle(fontSize: 12)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              color: Colors.grey,
            ),
          ),
          
          // Media content
          if (widget.post.isVideo && _isVideoInitialized)
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoUploadPreview(
                    progress: widget.progress,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                // Linear progress indicator at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
                  ),
                ),
              ],
            )
          else if (widget.post.isVideo)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 250,
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        VideoUploadIndicator(progress: widget.progress),
                        const SizedBox(height: 16),
                        const Text(
                          'Video uploading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // Linear progress indicator at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
                  ),
                ),
              ],
            )
          else if (widget.post.localFilePath != null)
            Stack(
              alignment: Alignment.center,
              children: [
                // Apply grayscale filter
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
                  child: Image.file(
                    File(widget.post.localFilePath!),
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                VideoUploadIndicator(progress: widget.progress),
                // Linear progress indicator at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
                  ),
                ),
              ],
            )
          else
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        VideoUploadIndicator(progress: widget.progress),
                        const SizedBox(height: 16),
                        const Text('Uploading...'),
                      ],
                    ),
                  ),
                ),
                // Linear progress indicator at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: Colors.black.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          
          // Caption
          if (widget.post.Text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.post.Text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          
          // Bottom action bar (disabled while uploading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('0', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.comment_outlined, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('0', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Icon(Icons.share_outlined, color: Colors.grey),
                Icon(Icons.bookmark_border, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
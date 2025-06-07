import 'dart:io';
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/video_upload_indicator.dart';
import 'package:video_player/video_player.dart';

class UploadingVideoBubble extends StatefulWidget {
  final String localFilePath;
  final double progress;
  final String? caption;
  final bool isFromCurrentUser;
  final bool isError;
  final VoidCallback? onRetry;

  const UploadingVideoBubble({
    Key? key,
    required this.localFilePath,
    required this.progress,
    required this.isFromCurrentUser,
    this.caption,
    this.isError = false,
    this.onRetry,
  }) : super(key: key);

  @override
  State<UploadingVideoBubble> createState() => _UploadingVideoBubbleState();
}

class _UploadingVideoBubbleState extends State<UploadingVideoBubble> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize video controller if it's a local file
    if (widget.localFilePath.isNotEmpty) {
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
      _videoController = VideoPlayerController.file(File(widget.localFilePath));
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
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 280,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: widget.isFromCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.isFromCurrentUser 
                  ? Colors.blue.withOpacity(0.8)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isVideoInitialized && widget.progress < 1.0)
                        SizedBox(
                          width: 280,
                          height: 190,
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      else
                        Container(
                          width: 280,
                          height: 190,
                          color: Colors.black,
                        ),
                      
                      // Show upload indicator overlay
                      Container(
                        width: 280,
                        height: 190,
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: VideoUploadIndicator(
                            progress: widget.progress,
                            isError: widget.isError,
                            onRetry: widget.onRetry,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Caption below video if provided
                  if (widget.caption != null && widget.caption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.caption!,
                        style: TextStyle(
                          color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Upload status indicator below bubble
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload,
                  size: 12,
                  color: widget.isError ? Colors.red : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isError
                      ? 'Upload failed'
                      : widget.progress < 1.0
                          ? 'Uploading ${(widget.progress * 100).toInt()}%'
                          : 'Processing...',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isError ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';

/// A specialized indicator for video upload progress with modern design
class VideoUploadIndicator extends StatelessWidget {
  /// The upload progress (0.0 to 1.0)
  final double progress;
  
  /// The size of the indicator
  final double size;
  
  const VideoUploadIndicator({
    Key? key,
    required this.progress,
    this.size = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background progress indicator (static)
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 3.0,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.1)),
          ),
          
          // Actual progress indicator
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.0,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          
          // Percentage text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'UPLOADING',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A video preview widget with upload progress overlay
class VideoUploadPreview extends StatelessWidget {
  /// The upload progress (0.0 to 1.0)
  final double progress;
  
  /// The child widget (video player or preview)
  final Widget child;
  
  const VideoUploadPreview({
    Key? key,
    required this.progress,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Apply a grayscale filter while uploading
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: child,
        ),
        
        // Overlay with subtle gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        
        // Overlay status text
        Positioned(
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'UPLOADING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Progress indicator
        VideoUploadIndicator(progress: progress),
      ],
    );
  }
} 
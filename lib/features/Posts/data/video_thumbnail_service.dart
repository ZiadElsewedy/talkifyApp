import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class VideoThumbnailService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final Uuid _uuid = Uuid();

  /// Generates a thumbnail from a video URL and returns the thumbnail URL
  static Future<String?> generateThumbnail(String videoUrl) async {
    try {
      print('Generating thumbnail for video URL: $videoUrl');
      
      // Generate the thumbnail locally
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );
      
      if (thumbnailPath == null) {
        print('Failed to generate thumbnail');
        return null;
      }
      
      print('Generated local thumbnail at: $thumbnailPath');
      
      // Upload the thumbnail to Firebase Storage
      final file = File(thumbnailPath);
      final fileName = 'video_thumbnails/${_uuid.v4()}${path.extension(thumbnailPath)}';
      
      final uploadTask = _storage.ref(fileName).putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Uploaded thumbnail to Firebase Storage: $downloadUrl');
      
      // Clean up the local file
      await file.delete();
      
      return downloadUrl;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }
  
  /// Attempts to generate a thumbnail from a Firebase video URL
  /// Returns null if the video URL is invalid or if thumbnail generation fails
  static Future<String?> generateThumbnailForFirebaseVideo(String videoUrl) async {
    try {
      // Ensure we have a valid Firebase Storage URL
      if (!videoUrl.contains('firebasestorage.googleapis.com')) {
        print('URL is not a Firebase Storage URL: $videoUrl');
        return await generateThumbnail(videoUrl);
      }
      
      return await generateThumbnail(videoUrl);
    } catch (e) {
      print('Error generating thumbnail for Firebase video: $e');
      return null;
    }
  }
  
  /// Generate a thumbnail for a post by ID
  static Future<String?> generateThumbnailForPost(String postId, String videoUrl) async {
    try {
      final thumbnailUrl = await generateThumbnail(videoUrl);
      
      // If we successfully generated a thumbnail, return it
      if (thumbnailUrl != null) {
        return thumbnailUrl;
      }
      
      // Otherwise, return a default video thumbnail
      return 'https://firebasestorage.googleapis.com/v0/b/talkify-12.appspot.com/o/default_video_thumbnail.png?alt=media';
    } catch (e) {
      print('Error generating thumbnail for post $postId: $e');
      return 'https://firebasestorage.googleapis.com/v0/b/talkify-12.appspot.com/o/default_video_thumbnail.png?alt=media';
    }
  }
} 
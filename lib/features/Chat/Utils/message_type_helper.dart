import 'package:talkifyapp/features/Chat/domain/entite/message.dart';

// Helper to determine file types based on extension
class MessageTypeHelper {
  static MessageType getTypeFromFileExtension(String? extension) {
    if (extension == null) return MessageType.file;
    
    final ext = extension.toLowerCase();
    
    // Images
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'].contains(ext)) {
      return MessageType.image;
    }
    // Videos
    else if (['mp4', 'mov', 'avi', 'mkv', 'flv', 'webm', '3gp'].contains(ext)) {
      return MessageType.video;
    }
    // Audio
    else if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].contains(ext)) {
      return MessageType.audio;
    }
    // Document formats that can be viewed in-app
    else if (['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'csv'].contains(ext)) {
      return MessageType.document;
    }
    // Default to generic file
    else {
      return MessageType.file;
    }
  }
  
  static String getFileIconName(MessageType type, String? extension) {
    if (type == MessageType.document && extension != null) {
      final ext = extension.toLowerCase();
      if (['pdf'].contains(ext)) {
        return 'pdf';
      } else if (['doc', 'docx'].contains(ext)) {
        return 'word';
      } else if (['xls', 'xlsx'].contains(ext)) {
        return 'excel';
      } else if (['ppt', 'pptx'].contains(ext)) {
        return 'powerpoint';
      } else if (['txt'].contains(ext)) {
        return 'text';
      }
    }
    return 'generic';
  }
} 
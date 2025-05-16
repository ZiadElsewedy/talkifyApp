import 'dart:typed_data';

abstract class StorageRepo {
  // upload profile image on mobile 
  Future<String?> uploadProfileImageMobile(String imagePath , String fileName);
  // upload profile image on web
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes  , String fileName);
  // upload post image on mobile 
  Future<String?> uploadPostImageMobile(String imagePath , String fileName);
  // upload post image on web 
  Future<String?> uploadPostImageWeb(Uint8List fileBytes  , String fileName);
  // uplaod image on web 
}
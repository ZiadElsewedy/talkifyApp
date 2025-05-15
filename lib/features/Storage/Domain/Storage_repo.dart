import 'dart:typed_data';

abstract class StorageRepo {
  // upload profile image on mobile 
  Future<String?> uploadProfileImageMobile(String imagePath , String fileName);
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes  , String fileName);
  //
  // uplaod image on web 
}
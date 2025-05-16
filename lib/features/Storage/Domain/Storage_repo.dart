import 'dart:typed_data';

abstract class StorageRepo {
  Future<String?> uploadProfileImageMobile(String imagePath , String fileName);
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes  , String fileName);
  Future<String?> uploadPostImageMobile(String imagePath , String fileName);
  Future<String?> uploadPostImageWeb(Uint8List fileBytes  , String fileName);

}
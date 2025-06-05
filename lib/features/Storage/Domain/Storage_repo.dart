import 'dart:typed_data';

abstract class StorageRepo {
  Future<String?> uploadProfileImageMobile(String imagePath , String fileName);
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes  , String fileName);
  Future<String?> uploadPostImageMobile(String imagePath , String fileName);
  Future<String?> uploadPostImageWeb(Uint8List fileBytes  , String fileName);
  
  // Generic upload methods for any file type
  Future<String?> uploadFile(String filePath, String storagePath);
  Future<String?> uploadBytes(Uint8List bytes, String storagePath);
  
  // Stream for upload progress (0.0 to 1.0)
  Stream<double> get uploadProgressStream;
  
  // Method to clean up resources
  void dispose();
}
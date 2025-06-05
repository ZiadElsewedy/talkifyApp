import 'dart:io'; // Needed for File operations on mobile

import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage SDK
import 'package:flutter/services.dart'; // For Uint8List (used in web image upload)
import 'package:talkifyapp/features/Storage/Domain/Storage_repo.dart'; // Your interface

// Implements the abstract StorageRepo class you defined earlier
class FirebaseStorageRepo implements StorageRepo {
  // Create a singleton instance of FirebaseStorage
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Upload profile image from mobile device using file path
  @override
  Future<String?> uploadProfileImageMobile(String imagePath, String fileName) {
    // Calls the generic upload function for mobile
    return uploadfile(imagePath, fileName, "ProfileImages");
  }

  // Upload profile image from web using file bytes
  @override
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes, String fileName) {
    // Calls the generic upload function for web
    return uploadfileWeb(fileBytes, fileName, "ProfileImages");
  }

  // Upload post image from mobile device using file path
  @override
  Future<String?> uploadPostImageMobile(String imagePath, String fileName) {
    print('Uploading post media from mobile: $imagePath');
    
    // Check if it's a video based on file extension
    final isVideo = imagePath.toLowerCase().endsWith('.mp4') || 
                   imagePath.toLowerCase().endsWith('.mov') || 
                   imagePath.toLowerCase().endsWith('.avi');
    
    final folder = isVideo ? "PostVideos" : "PostImages";
    print('Detected media type: ${isVideo ? "Video" : "Image"}, using folder: $folder');
    
    // Calls the generic upload function for mobile
    return uploadfile(imagePath, fileName, folder);
  }

  // Upload post image from web using file bytes
  @override
  Future<String?> uploadPostImageWeb(Uint8List fileBytes, String fileName) {
    print('Uploading post media from web, fileName: $fileName');
    return uploadfileWeb(fileBytes, fileName, "PostImages");
  }
  
  // Generic file upload method that works with any file type
  @override
  Future<String?> uploadFile(String filePath, String storagePath) async {
    print('Generic file upload: filePath=$filePath, storagePath=$storagePath');
    try {
      final file = File(filePath);
      final storageRef = storage.ref().child(storagePath);
      
      print('Starting upload to Firebase Storage: $storagePath');
      final uploadTask = await storageRef.putFile(file);
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  // Generic bytes upload method
  @override
  Future<String?> uploadBytes(Uint8List bytes, String storagePath) async {
    print('Generic bytes upload: bytes.length=${bytes.length}, storagePath=$storagePath');
    try {
      final storageRef = storage.ref().child(storagePath);
      
      print('Starting upload to Firebase Storage: $storagePath');
      final uploadTask = await storageRef.putData(bytes);
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading bytes: $e');
      return null;
    }
  }
    
  // Uploads a file from mobile device to Firebase Storage
  Future<String?> uploadfile(String path, String fileName, String folder) async {
    try {
      print('Uploading file: path=$path, fileName=$fileName, folder=$folder');
      // Convert the file path string into a File object
      final file = File(path);

      // Define a reference in Firebase Storage at folder/fileName/fileName
      final storageRef = storage.ref().child("$folder/$fileName");

      // Upload the file
      print('Starting upload to Firebase Storage');
      final uploadTask = await storageRef.putFile(file);

      // Get the download URL of the uploaded file
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');

      // Return the download URL
      return downloadUrl;
    } catch (e) {
      // Return null if there's any error during upload
      print('Error uploading file: $e');
      return null;
    }
  }

  // Uploads a file from web (or memory) using bytes to Firebase Storage
  Future<String?> uploadfileWeb(Uint8List fileBytes, String fileName, String folder) async {
    try {
      print('Uploading file from web: bytes.length=${fileBytes.length}, fileName=$fileName, folder=$folder');
      // Define a reference in Firebase Storage at folder/fileName/fileName
      final storageRef = storage.ref().child("$folder/$fileName");

      // Upload the data as bytes
      print('Starting upload to Firebase Storage');
      final uploadTask = await storageRef.putData(fileBytes);

      // Get the download URL of the uploaded file
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');

      // Return the download URL
      return downloadUrl;
    } catch (e) {
      // Return null if there's any error during upload
      print('Error uploading file from web: $e');
      return null;
    }
  }
}

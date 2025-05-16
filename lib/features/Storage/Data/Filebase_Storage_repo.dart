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

  // Uploads a file from mobile device to Firebase Storage
  Future<String?> uploadfile(String path, String fileName, String folder) async {
    try {
      // Convert the file path string into a File object
      final file = File(path);

      // Define a reference in Firebase Storage at folder/fileName/fileName
      final storageRef = storage.ref().child("$folder/$fileName");

      // Upload the file
      final uploadTask = await storageRef.putFile(file);

      // Get the download URL of the uploaded file
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Return the download URL
      return downloadUrl;
    } catch (e) {
      // Return null if there's any error during upload
      return null;
    }
  }

  // Uploads a file from web (or memory) using bytes to Firebase Storage
  Future<String?> uploadfileWeb(Uint8List fileBytes, String fileName, String folder) async {
    try {
      // Define a reference in Firebase Storage at folder/fileName/fileName
      final storageRef = storage.ref().child("$folder/$fileName");

      // Upload the data as bytes
      final uploadTask = await storageRef.putData(fileBytes);

      // Get the download URL of the uploaded file
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Return the download URL
      return downloadUrl;
    } catch (e) {
      // Return null if there's any error during upload
      return null;
    }
  }
}

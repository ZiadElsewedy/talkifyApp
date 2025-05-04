abstract class StorageRepo {
  // upload profile image on mobile 
  Future<String> uploadProfileImageMobile(String imagePath , String fileName);
  Future<String> uploadProfileImageWeb(String imagePath , String fileName);
  // uplaod image on web 
}
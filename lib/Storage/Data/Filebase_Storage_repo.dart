import 'dart:typed_data';

import 'package:talkifyapp/Storage/Domain/Storage_repo.dart';

class FilebaseStorageRepo implements  StorageRepo  {
    @override
  Future<String?> uploadProfileImageMobile(String imagePath, String fileName) {
    // TODO: implement uploadProfileImageMobile
    throw UnimplementedError();
  }
  @override
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes, String fileName) {
    // TODO: implement uploadProfileImageWeb
    throw UnimplementedError();
  }
}
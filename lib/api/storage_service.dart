import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadPropertyImage(String propertyId, XFile imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('properties/$propertyId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(File(imageFile.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }

  Future<String?> uploadMaintenanceImage(String maintenanceId, XFile imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('maintenance/$maintenanceId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(File(imageFile.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }

  Future<List<XFile>> pickImages({bool multiple = false}) async {
    if (multiple) {
      return await _picker.pickMultiImage();
    } else {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      return image != null ? [image] : [];
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Error deleting image: $e';
    }
  }
}

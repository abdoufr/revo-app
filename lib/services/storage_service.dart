import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  /// Uploads a base64 string to Firebase Storage and returns the download URL.
  /// If the string is already a URL, it simply returns it.
  static Future<String> uploadBase64Image(String base64Str, String folder) async {
    // If it's already a URL, no need to upload
    if (base64Str.startsWith('http')) return base64Str;
    
    // Extract base64 part
    String base64Data = base64Str;
    if (base64Str.contains(',')) {
      base64Data = base64Str.split(',').last;
    }

    try {
      final bytes = base64Decode(base64Data);
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child(folder).child(fileName);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Storage: $e');
      // If upload fails, fallback to storing the base64 directly
      // Not ideal for size limits, but prevents data loss
      return base64Str;
    }
  }

  /// Uploads a list of base64 images
  static Future<List<String>> uploadMultipleImages(List<String> images, String folder) async {
    List<String> uploadedUrls = [];
    for (var img in images) {
      final url = await uploadBase64Image(img, folder);
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }
}

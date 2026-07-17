import 'dart:convert';

class StorageService {
  /// On web, Firebase Storage has CORS issues.
  /// We store images directly as base64 in Firestore.
  /// Images are compressed before calling this method so they stay small.
  static Future<String> uploadBase64Image(String base64Str, String folder) async {
    // If it's already a URL, return as-is
    if (base64Str.startsWith('http')) return base64Str;
    // Return base64 directly (already compressed at pick time)
    return base64Str;
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

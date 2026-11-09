import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/app_config.dart';

/// Shop image uploads via Cloudinary (unsigned upload preset).
///
/// The barber picks a photo from the gallery; it is uploaded straight to
/// Cloudinary and the returned `secure_url` is stored in
/// `barber_shops.logo_url` / `cover_image_url`. No API key or secret is
/// used — or needed — in the app: the preset `douri_unsigned` must exist
/// in the Cloudinary dashboard as an **Unsigned** preset (see
/// CLOUDINARY_SETUP.md). If the preset does not exist yet, Cloudinary
/// answers 400 "Upload preset not found" and this throws a readable
/// message telling the user to create it.
class CloudinaryService {
  const CloudinaryService._();

  static String get _cloudName => AppConfig.cloudinaryCloudName;
  static String get _preset => AppConfig.cloudinaryUploadPreset;

  /// Uploads [image] to Cloudinary and returns the HTTPS URL.
  /// [folder] groups uploads in the Cloudinary media library.
  static Future<String> uploadImage(XFile image, {String folder = 'douri'}) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _preset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(_readableError(body));
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary returned no URL');
    }
    return url;
  }

  static String _readableError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = (json['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (message != null && message.contains('Upload preset not found')) {
        return 'Cloudinary preset "$_preset" not found — create the unsigned upload preset (see CLOUDINARY_SETUP.md).';
      }
      if (message != null) return 'Cloudinary: $message';
    } catch (_) {}
    return 'Cloudinary upload failed (${body.isEmpty ? 'no details' : body})';
  }
}

/// Picks one image from the gallery, or null when the user cancels.
Future<XFile?> pickGalleryImage() async {
  return ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
}

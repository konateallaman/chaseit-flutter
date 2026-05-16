import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Cloudinary — free tier: 25GB storage, 25GB bandwidth/month
/// Sign up at cloudinary.com → Dashboard → copy Cloud Name, API Key, API Secret
class ImageService {
  static const String _cloudName = 'YOUR_CLOUD_NAME'; // from cloudinary.com
  static const String _uploadPreset = 'chaseit_avatars'; // create unsigned preset in Cloudinary

  /// Upload image bytes to Cloudinary — returns public URL or null on failure
  static Future<String?> uploadAvatar({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final base64Image = base64Encode(imageBytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';

      final res = await http.post(uri, body: {
        'file': dataUri,
        'upload_preset': _uploadPreset,
        'public_id': 'avatars/$userId',
        'overwrite': 'true',
        'folder': 'chaseit',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Return optimized URL with face crop
        final publicId = data['public_id'];
        return 'https://res.cloudinary.com/$_cloudName/image/upload/w_200,h_200,c_fill,g_face,r_max/$publicId.jpg';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

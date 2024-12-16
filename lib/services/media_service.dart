import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  MediaService();

  Future<File?> getImageFromGallery() async {
    try {
      final XFile? _file = await _picker.pickImage(source: ImageSource.gallery);
      if (_file != null) {
        return File(_file.path);
      } else {
        print("User did not select any image.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
    return null;
  }
}

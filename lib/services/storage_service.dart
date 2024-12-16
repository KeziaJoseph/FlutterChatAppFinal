import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService();

  /// Fungsi umum untuk mengunggah file ke Firebase Storage
  Future<String> _uploadFile({
    required String path,
    required File file,
  }) async {
    try {
      final ref = _firebaseStorage.ref(path); // Referensi file
      final uploadTask = await ref.putFile(file); // Unggah file
      return await uploadTask.ref.getDownloadURL(); // Dapatkan URL download
    } catch (e) {
      throw Exception("Failed to upload file: $e");
    }
  }

  /// Unggah foto profil pengguna (mendukung semua ekstensi file)
  Future<String> uploadUserPfp({
    required File file,
    required String uid,
  }) async {
    final extension = p.extension(file.path).toLowerCase(); // Ekstensi file (misalnya .jpg, .png)
    final path = 'users/pfps/$uid$extension';
    return await _uploadFile(path: path, file: file);
  }

  /// Unggah gambar ke obrolan (mendukung semua ekstensi file)
  Future<String> uploadImageToChat({
    required File file,
    required String chatID,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final extension = p.extension(file.path).toLowerCase();
    final path = 'chats/$chatID/$timestamp$extension';
    return await _uploadFile(path: path, file: file);
  }

  /// Unggah foto profil dengan nama file unik (mendukung semua ekstensi file)
  Future<String> uploadUserProfileImage({
    required String uid,
    required File file,
  }) async {
    final extension = p.extension(file.path).toLowerCase();
    final path = 'profile_pictures/$uid$extension';
    return await _uploadFile(path: path, file: file);
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mid_app/services/auth_service.dart';
import 'package:mid_app/services/database_service.dart';
import 'package:mid_app/services/alert_service.dart';
import 'package:mid_app/services/storage_service.dart';
import 'package:mid_app/models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late DatabaseService _databaseService;
  late AlertService _alertService;
  late StorageService _storageService;

  late UserProfile _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _storageService = _getIt.get<StorageService>();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _authService.user?.uid;
      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        setState(() {
          _userProfile = userProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      _alertService.showToast(
        text: "Failed to load profile",
        icon: Icons.error,
      );
    }
  }

  Future<void> _updateProfile({String? name, File? image}) async {
    try {
      String? updatedPfpURL = _userProfile.pfpURL;

      // Jika ada gambar baru, unggah ke Storage
      if (image != null) {
        updatedPfpURL = await _storageService.uploadUserProfileImage(
          uid: _userProfile.uid!,
          file: image,
        );
      }

      // Perbarui nama atau URL foto di database
      await _databaseService.updateUserProfile(
        uid: _userProfile.uid!,
        updatedData: {
          if (name != null) 'name': name,
          if (updatedPfpURL != null) 'pfpURL': updatedPfpURL,
        },
      );

      // Perbarui state lokal
      setState(() {
        if (name != null) _userProfile.name = name;
        if (updatedPfpURL != null) _userProfile.pfpURL = updatedPfpURL;
      });

      _alertService.showToast(
        text: "Profile updated successfully!",
        icon: Icons.check,
      );
    } catch (e) {
      _alertService.showToast(
        text: "Failed to update profile",
        icon: Icons.error,
      );
    }
  }

  Future<void> _editProfile() async {
    TextEditingController nameController =
    TextEditingController(text: _userProfile.name);
    final ImagePicker picker = ImagePicker();
    File? selectedImage; // Gambar yang dipilih disimpan sementara

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Untuk memperbarui dialog saat gambar dipilih
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 16),
                  if (selectedImage != null)
                    Column(
                      children: [
                        Image.file(
                          selectedImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          selectedImage = File(image.path); // Simpan sementara gambar
                        });
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text("Change Profile Picture"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Perbarui profil hanya jika ada perubahan
                    await _updateProfile(
                      name: nameController.text.trim(),
                      image: selectedImage,
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _buildProfileUI(),
    );
  }

  Widget _buildProfileUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _userProfile.pfpURL != null
                    ? NetworkImage(_userProfile.pfpURL!)
                    : null,
                child: _userProfile.pfpURL == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userProfile.name ?? "No Name",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            label: const Text("Edit Profile"),
          ),
        ],
      ),
    );
  }
}

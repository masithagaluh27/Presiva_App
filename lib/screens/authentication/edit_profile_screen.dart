// lib/screens/profile/edit_profile_screen.dart
import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File operations

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart'; // Your dynamic AppColors
import 'package:presiva/models/app_models.dart';

import '../../widgets/custom_input_field.dart'; // Your CustomInputField
import '../../widgets/primary_button.dart'; // Your PrimaryButton

class EditProfileScreen extends StatefulWidget {
  final User currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  File? _pickedImage;
  String? _profilePhotoBase64;
  String? _initialProfilePhotoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);

    _initialProfilePhotoUrl = widget.currentUser.profile_photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      List<int> imageBytes = await _pickedImage!.readAsBytes();
      _profilePhotoBase64 = base64Encode(imageBytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      final String newName = _nameController.text.trim();
      bool profileDetailsChanged = false;
      bool profilePhotoChanged = false;

      final bool nameChanged = newName != widget.currentUser.name;

      if (nameChanged) {
        try {
          final ApiResponse<User> response = await _apiService.updateProfile(
            name: newName,
          );

          if (response.statusCode == 200 && response.data != null) {
            profileDetailsChanged = true;
          } else {
            String errorMessage = response.message;
            if (response.errors != null) {
              response.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Gagal memperbarui detail profil: $errorMessage',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Terjadi kesalahan saat memperbarui detail: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (_pickedImage != null && _profilePhotoBase64 != null) {
        try {
          final ApiResponse<User> photoResponse = await _apiService
              .updateProfilePhoto(profilePhoto: _profilePhotoBase64!);

          if (photoResponse.statusCode == 200 && photoResponse.data != null) {
            profilePhotoChanged = true;
            if (photoResponse.data!.profile_photo != null) {
              _initialProfilePhotoUrl = photoResponse.data!.profile_photo;
            }
            _pickedImage = null;
            _profilePhotoBase64 = null;
          } else {
            String errorMessage = photoResponse.message;
            if (photoResponse.errors != null) {
              photoResponse.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal memperbarui foto profil: $errorMessage'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Terjadi kesalahan saat memperbarui foto: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      if (profileDetailsChanged || profilePhotoChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profil berhasil diperbarui!"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Tidak ada perubahan untuk disimpan."),
            backgroundColor: AppColors.info,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? currentImageProvider;
    if (_pickedImage != null) {
      currentImageProvider = FileImage(_pickedImage!);
    } else if (_initialProfilePhotoUrl != null &&
        _initialProfilePhotoUrl!.isNotEmpty) {
      final String fullImageUrl =
          _initialProfilePhotoUrl!.startsWith('http')
              ? _initialProfilePhotoUrl!
              : 'https://appabsensi.mobileprojp.com/public/${_initialProfilePhotoUrl!}';
      currentImageProvider = NetworkImage(fullImageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Profil', style: TextStyle(color: AppColors.textDark)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.cardBackground,
                        backgroundImage: currentImageProvider,
                        child:
                            currentImageProvider == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.textLight,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text(
                        _pickedImage != null ||
                                (_initialProfilePhotoUrl != null &&
                                    _initialProfilePhotoUrl!.isNotEmpty)
                            ? 'Ganti Foto'
                            : 'Unggah Foto',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomInputField(
                controller: _nameController,
                hintText: 'Nama',
                labelText: 'Nama',
                icon: Icons.person,
                fillColor: AppColors.inputFill,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : PrimaryButton(
                    label: 'Simpan Profil',
                    onPressed: _saveProfile,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

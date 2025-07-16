import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/models/app_models.dart';

import '../../widgets/custom_input_field.dart';
import '../../widgets/primary_button.dart';

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
                    'Failed to update profile details: $errorMessage',
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
                content: Text('An error occurred while updating details: $e'),
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
                  content: Text(
                    'Failed to update profile photo: $errorMessage',
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
                content: Text('An error occurred while updating the photo: $e'),
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
            content: const Text("Profile updated successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("There are no changes to save."),
            backgroundColor: AppColors.info,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // untuk profile
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
                            ? 'Change Photo'
                            : 'Upload Photo',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomInputField(
                controller: _nameController,
                hintText: 'Name',
                labelText: 'Name',
                icon: Icons.person,
                fillColor: AppColors.inputFill,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
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
                    label: 'Save Profile',
                    onPressed: _saveProfile,
                  ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '© ${DateTime.now().year} Presiva. All rights reserved.',
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

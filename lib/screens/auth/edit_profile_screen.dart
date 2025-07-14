// lib/screens/profile/edit_profile_screen.dart
import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File operations

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking
import 'package:presiva/constant/app_colors.dart'; // Your dynamic AppColors
import 'package:presiva/models/app_models.dart';
import 'package:presiva/services/api_Services.dart';

import '../../widgets/custom_input_field.dart'; // Your CustomInputField
import '../../widgets/primary_button.dart'; // Your PrimaryButton

class EditProfileScreen extends StatefulWidget {
  final User currentUser; // Changed type to User

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  File? _pickedImage; // State for newly picked profile photo file
  String? _profilePhotoBase64; // Base64 for the newly picked photo to upload
  String? _initialProfilePhotoUrl; // To store the original URL from currentUser

  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // Initialize controller with current user's name
    _nameController = TextEditingController(
      text: widget.currentUser.name, // Use .name property
    );

    // Store the initial profile photo URL from the current user
    _initialProfilePhotoUrl = widget.currentUser.profile_photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      // Convert image to base64 for upload
      List<int> imageBytes = await _pickedImage!.readAsBytes();
      _profilePhotoBase64 = base64Encode(imageBytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String newName = _nameController.text.trim();
      bool profileDetailsChanged = false;
      bool profilePhotoChanged = false;

      // 1. Check if name has changed and update
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
                    'Gagal memperbarui detail profil: $errorMessage', // Pesan error bahasa Indonesia
                  ),
                  backgroundColor: AppColors.error(
                    context,
                  ), // <--- UBAH DI SINI
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if detail update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Terjadi kesalahan saat memperbarui detail: $e',
                ), // Pesan error bahasa Indonesia
                backgroundColor: AppColors.error(context), // <--- UBAH DI SINI
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Check if a new profile photo has been selected and upload
      if (_pickedImage != null && _profilePhotoBase64 != null) {
        try {
          final ApiResponse<User> photoResponse = await _apiService
              .updateProfilePhoto(profilePhoto: _profilePhotoBase64!);

          if (photoResponse.statusCode == 200 && photoResponse.data != null) {
            profilePhotoChanged = true;
            // IMPORTANT: Update the initialProfilePhotoUrl with the new URL from the API response
            if (photoResponse.data!.profile_photo != null) {
              _initialProfilePhotoUrl = photoResponse.data!.profile_photo;
            }
            // Clear picked image and base64 as it's now saved and reflected by URL
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
                    'Gagal memperbarui foto profil: $errorMessage', // Pesan error bahasa Indonesia
                  ),
                  backgroundColor: AppColors.error(
                    context,
                  ), // <--- UBAH DI SINI
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if photo update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Terjadi kesalahan saat memperbarui foto: $e',
                ), // Pesan error bahasa Indonesia
                backgroundColor: AppColors.error(context), // <--- UBAH DI SINI
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
            // SnackBar tidak bisa const lagi karena backgroundColor dinamis
            content: const Text(
              "Profil berhasil diperbarui!",
            ), // Pesan sukses bahasa Indonesia
            backgroundColor: AppColors.success(context), // <--- UBAH DI SINI
          ),
        );
        Navigator.pop(context, true); // Pop with true to signal refresh
      } else {
        // If no changes were made to either name/gender or photo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // SnackBar tidak bisa const lagi karena backgroundColor dinamis
            content: const Text(
              "Tidak ada perubahan untuk disimpan.",
            ), // Pesan info bahasa Indonesia
            backgroundColor: AppColors.info(context), // <--- UBAH DI SINI
          ),
        );
      }

      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construct full URL for existing profile photo
    ImageProvider<Object>? currentImageProvider;
    if (_pickedImage != null) {
      // If a new image is picked, use it
      currentImageProvider = FileImage(_pickedImage!);
    } else if (_initialProfilePhotoUrl != null &&
        _initialProfilePhotoUrl!.isNotEmpty) {
      // If no new image, but there's an initial URL, use NetworkImage
      // Check if the URL is already a full URL or a relative path
      final String fullImageUrl =
          _initialProfilePhotoUrl!.startsWith('http')
              ? _initialProfilePhotoUrl!
              : 'https://appabsensi.mobileprojp.com/public/' +
                  _initialProfilePhotoUrl!; // Adjust base path as needed
      currentImageProvider = NetworkImage(fullImageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background(context), // <--- UBAH DI SINI
      appBar: AppBar(
        title: Text(
          // Hapus 'const' karena Text memerlukan nilai dinamis jika stylenya dinamis
          'Edit Profil', // Judul AppBar bahasa Indonesia
          style: TextStyle(
            color: AppColors.textDark(context), // <--- UBAH DI SINI
          ), // Warna teks judul AppBar
        ),
        backgroundColor: AppColors.background(context), // <--- UBAH DI SINI
        foregroundColor: AppColors.textDark(
          context,
        ), // <--- UBAH DI SINI (Warna ikon dan teks di AppBar)
        elevation: 0, // Tanpa bayangan
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
                        backgroundColor: AppColors.cardBackground(
                          context,
                        ), // <--- UBAH DI SINI (Background avatar saat tidak ada gambar)
                        backgroundImage:
                            currentImageProvider, // Use the determined image provider
                        child:
                            currentImageProvider == null
                                ? Icon(
                                  // Hapus 'const' karena Icon memerlukan nilai dinamis jika warnanya dinamis
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.textLight(
                                    context,
                                  ), // <--- UBAH DI SINI (Warna ikon default)
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
                            ? 'Ganti Foto' // Teks tombol bahasa Indonesia
                            : 'Unggah Foto', // Teks tombol bahasa Indonesia
                        style: TextStyle(
                          // Hapus 'const' karena TextStyle memerlukan nilai dinamis jika warnanya dinamis
                          color: AppColors.primary(
                            context,
                          ), // <--- UBAH DI SINI
                        ), // Warna teks tombol
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ), // Space between image section and first input
              // Username (editable) using CustomInputField
              CustomInputField(
                controller: _nameController,
                hintText: 'Nama', // Hint text bahasa Indonesia
                labelText: 'Nama', // Label text bahasa Indonesia
                icon: Icons.person,
                // Pastikan CustomInputField Anda juga bisa menerima fillColor yang dinamis
                fillColor: AppColors.inputFill(
                  context,
                ), // <--- TAMBAH / UBAH DI SINI
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong'; // Validasi bahasa Indonesia
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Save Button using PrimaryButton
              _isLoading
                  ? Center(
                    // Hapus 'const' karena CircularProgressIndicator memerlukan nilai dinamis jika warnanya dinamis
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context), // <--- UBAH DI SINI
                    ), // Warna loading indicator
                  )
                  : PrimaryButton(
                    label: 'Simpan Profil', // Label tombol bahasa Indonesia
                    onPressed: _saveProfile,
                    // Asumsi PrimaryButton sudah menggunakan AppColors.primary untuk warnanya secara internal
                    // Jika tidak, Anda perlu meneruskan warna primary ke PrimaryButton
                    // Contoh: buttonColor: AppColors.primary(context), jika PrimaryButton punya properti itu.
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

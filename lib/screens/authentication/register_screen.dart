import 'package:flutter/material.dart';
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/endpoint/app_routes.dart';
import 'package:presiva/models/app_models.dart';
import 'package:presiva/widgets/custom_dropdown_input_field.dart';
import 'package:presiva/widgets/custom_input_field.dart';
import 'package:presiva/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  List<Batch> _batches = [];
  List<Training> _trainings = [];
  int? _selectedBatchId;
  String _selectedBatchName = 'Memuat Angkatan...';
  int? _selectedTrainingId;
  String? _selectedGender; // Menggunakan  'L' atau 'P'

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();

    _selectedGender = 'L'; // Default ke Laki-laki
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final batchResponse = await _apiService.getBatches();
      if (batchResponse.statusCode == 200 && batchResponse.data != null) {
        setState(() {
          _batches = batchResponse.data!;

          final batch2 = _batches.firstWhere(
            (batch) => batch.batch_ke == '2',
            orElse:
                () =>
                    _batches.isNotEmpty
                        ? _batches.first
                        : Batch(
                          id: -1,
                          batch_ke: 'N/A',
                          startDate: '',
                          endDate: '',
                        ),
          );
          _selectedBatchId = batch2.id;
          _selectedBatchName =
              'Angkatan ${batch2.batch_ke}'; // Display as "Batch 2"
        });
      } else {
        if (mounted) {
          final String message = batchResponse.message;
          _showSnackBar('Failed to load batches: $message', isError: true);
        }
        setState(() {
          _selectedBatchName = 'Error Loading Batch';
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'An error occurred while fetching batches: $e',
          isError: true,
        );
      }
      setState(() {
        _selectedBatchName = 'Error Loading Batch';
      });
    }

    try {
      final trainingResponse = await _apiService.getTrainings();
      if (trainingResponse.statusCode == 200 && trainingResponse.data != null) {
        setState(() {
          _trainings = trainingResponse.data!;
        });
      } else {
        if (mounted) {
          final String message = trainingResponse.message;
          _showSnackBar('Failed to load trainings: $message', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'An error occurred while fetching trainings: $e',
          isError: true,
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatchId == null || _selectedBatchId == -1) {
        _showSnackBar('Batch not selected or invalid.', isError: true);
        return;
      }
      if (_selectedTrainingId == null) {
        _showSnackBar('Please select a training', isError: true);
        return;
      }

      if (_selectedGender == null || _selectedGender!.isEmpty) {
        _showSnackBar('Please select your gender', isError: true);
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match', isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final ApiResponse<AuthData> response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        batchId: _selectedBatchId!,
        trainingId: _selectedTrainingId!,
        jenisKelamin: _selectedGender!,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          _showSnackBar(response.message, isError: false);
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showSnackBar(errorMessage, isError: true);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Buat Akun Baru",
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Bergabunglah dengan kami untuk melacak kehadiran Anda dengan mudah.",
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Username
                    CustomInputField(
                      controller: _nameController,
                      hintText: "Name",
                      icon: Icons.person_outline,
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomInputField(
                      controller: _emailController,
                      hintText: "Email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    CustomInputField(
                      controller: _passwordController,
                      hintText: "Sandi",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      toggleVisibility:
                          () => setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          }),
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi harus minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    CustomInputField(
                      controller: _confirmPasswordController,
                      hintText: "Konfirmasi Sandi",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isConfirmPasswordVisible,
                      toggleVisibility:
                          () => setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          }),
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi kata sandi tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bagian Jenis Kelamin Dengan Radio Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        "Jenis kelamin",
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Laki-laki',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                            value: 'L',
                            groupValue: _selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Perempuan',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                            value: 'P',
                            groupValue: _selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedGender == null &&
                        _formKey.currentState?.validate() == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          'Silakan pilih jenis kelamin Anda',
                          style: AppTextStyles.body3(color: AppColors.error),
                        ),
                      ),
                    const SizedBox(height: 16),

                    _isLoading
                        ? Center()
                        : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.group_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedBatchName,
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const SizedBox.shrink()
                        : CustomDropdownInputField<int>(
                          labelText: 'Pilih pelatihan',
                          hintText: 'Pilih pelatihan',
                          icon: Icons.school_outlined,
                          value: _selectedTrainingId,
                          items:
                              _trainings.map((training) {
                                return DropdownMenuItem<int>(
                                  value: training.id,
                                  child: Text(training.title),
                                );
                              }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedTrainingId = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Silakan pilih pelatihan';
                            }
                            return null;
                          },
                          menuMaxHeight: 300.0,
                        ),
                    const SizedBox(height: 32),

                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                        : PrimaryButton(
                          label: "Daftar",
                          onPressed: _register,
                        ),
                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Sudah punya akun? ",
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                            child: Text(
                              "Masuk",
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
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
          ),
        ),
      ),
    );
  }
}

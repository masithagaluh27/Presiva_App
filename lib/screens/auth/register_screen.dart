import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/models/app_models.dart';
import 'package:presiva/routes/app_routes.dart';
import 'package:presiva/services/api_Services.dart';
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
  final ApiService _apiService = ApiService(); // Instantiate your ApiService

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // Add loading state

  List<Batch> _batches = []; // Keep this to fetch batches and find "Batch 2"
  List<Training> _trainings = [];
  int? _selectedBatchId;
  String _selectedBatchName =
      'Loading Batch...'; // To display the selected batch
  int? _selectedTrainingId;
  String? _selectedGender; // Menggunakan String untuk 'L' atau 'P'

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    // Inisialisasi _selectedGender ke nilai default, misalnya 'L'
    _selectedGender = 'L'; // Default ke Laki-laki
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch Batches
    try {
      final batchResponse = await _apiService.getBatches();
      if (batchResponse.statusCode == 200 && batchResponse.data != null) {
        setState(() {
          _batches = batchResponse.data!;
          // Automatically select "Batch 2" if found, otherwise select the first available batch
          final batch2 = _batches.firstWhere(
            (batch) => batch.batch_ke == '2', // Correctly using batch.batch_ke
            orElse:
                () =>
                    _batches.isNotEmpty
                        ? _batches.first
                        : Batch(
                          id: -1,
                          batch_ke: 'N/A',
                          startDate: '',
                          endDate: '',
                        ), // Corrected Batch constructor
          );
          _selectedBatchId = batch2.id;
          _selectedBatchName =
              'Batch ${batch2.batch_ke}'; // Display as "Batch 2"
        });
      } else {
        if (mounted) {
          final String message = batchResponse.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load batches: $message')),
          );
        }
        setState(() {
          _selectedBatchName = 'Error Loading Batch';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while fetching batches: $e'),
          ),
        );
      }
      setState(() {
        _selectedBatchName = 'Error Loading Batch';
      });
    }

    // Fetch Trainings
    try {
      final trainingResponse = await _apiService.getTrainings();
      if (trainingResponse.statusCode == 200 && trainingResponse.data != null) {
        setState(() {
          _trainings = trainingResponse.data!;
        });
      } else {
        if (mounted) {
          final String message = trainingResponse.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load trainings: $message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while fetching trainings: $e'),
          ),
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
        // Check for valid batch ID
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch not selected or invalid.')),
        );
        return;
      }
      if (_selectedTrainingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a training')),
        );
        return;
      }
      // Tambahkan validasi untuk _selectedGender
      if (_selectedGender == null || _selectedGender!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Call the register method from ApiService
      final ApiResponse<AuthData> response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        batchId: _selectedBatchId!,
        trainingId: _selectedTrainingId!,
        jenisKelamin: _selectedGender!,
      );

      setState(() {
        _isLoading = false; // Set loading to false
      });

      if (response.statusCode == 200 && response.data != null) {
        // Registration successful
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // Registration failed, show error message
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
      backgroundColor: AppColors.background, // Menggunakan AppColors.background
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
                      "Create Account",
                      style: AppTextStyles.heading2(
                        // Menggunakan heading2() sebagai fungsi
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join us to track your attendance effortlessly.",
                      style: AppTextStyles.body2(
                        // Menggunakan body2() sebagai fungsi
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
                          return 'Name cannot be empty';
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
                          return 'Email cannot be empty';
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
                      hintText: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      toggleVisibility:
                          () => setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          }),
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    CustomInputField(
                      controller: _confirmPasswordController,
                      hintText: "Confirm Password",
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
                          return 'Confirm password cannot be empty';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bagian Jenis Kelamin (Diganti dengan Radio Buttons)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        "Select Gender",
                        style: AppTextStyles.body2(color: AppColors.textDark),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Laki-laki',
                              style: AppTextStyles.body2(
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
                            activeColor:
                                AppColors.primary, // Warna saat terpilih
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Perempuan',
                              style: AppTextStyles.body2(
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
                            activeColor:
                                AppColors.primary, // Warna saat terpilih
                          ),
                        ),
                      ],
                    ),
                    // Jika Anda ingin menampilkan pesan validasi di bawah Radio Buttons, Anda bisa menambahkannya di sini.
                    // Namun, dengan RadioListTile, pengguna dipaksa memilih salah satu.
                    if (_selectedGender == null &&
                        _formKey.currentState?.validate() ==
                            true) // Contoh validasi jika perlu
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          'Please select your gender',
                          style: AppTextStyles.caption(color: AppColors.error),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Display Batch Name (not a dropdown)
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
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
                              const Icon(
                                Icons.group_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedBatchName,
                                  style: AppTextStyles.body2(
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 16),

                    // Training Dropdown using CustomDropdownInputField
                    _isLoading
                        ? const SizedBox.shrink()
                        : CustomDropdownInputField<int>(
                          labelText: 'Select Training',
                          hintText: 'Select Training',
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
                              return 'Please select a training';
                            }
                            return null;
                          },
                          menuMaxHeight: 300.0, // Apply menuMaxHeight here
                        ),
                    const SizedBox(height: 32),

                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                        : PrimaryButton(
                          label: "Register",
                          onPressed: _register,
                        ),
                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppTextStyles.body2(
                              color: AppColors.textDark,
                            ), // Menggunakan AppTextStyles
                          ),
                          GestureDetector(
                            onTap:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                            child: Text(
                              "Login",
                              style: AppTextStyles.body2(
                                fontWeight: FontWeight.bold,
                                color:
                                    AppColors.primary, // Menggunakan AppColors
                              ),
                            ),
                          ),
                        ],
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

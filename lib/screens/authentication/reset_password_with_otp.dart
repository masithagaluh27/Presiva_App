import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/endpoint/app_routes.dart';
import 'package:presiva/widgets/custom_input_field.dart';
import 'package:presiva/widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // --- Variabel untuk Timer ---
  Timer? _timer;
  final int _startMinutes = 10; // Durasi OTP dalam menit
  int _currentSeconds = 0;
  bool _otpExpired = false; // Status OTP kadaluarsa

  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  // --- Fungsi Timer ---
  void _startTimer() {
    _otpExpired = false;
    _currentSeconds = _startMinutes * 60; // Set total detik
    _timer?.cancel(); // Pastikan timer sebelumnya dibatalkan jika ada
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds <= 0) {
        timer.cancel();
        setState(() {
          _otpExpired = true; // Set OTP kadaluarsa
        });
      } else {
        setState(() {
          _currentSeconds--; // Kurangi detik setiap 1 detik
        });
      }
    });
  }

  // Mengubah detik menjadi format MM:SS
  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // untuk tombol reset password
  Future<void> _resetPasswordProcess() async {
    if (_formKey.currentState!.validate()) {
      if (_otpExpired) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP telah kedaluwarsa. Silakan minta OTP baru.'),
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String email = widget.email;
      final String otp = _otpController.text.trim();
      final String newPassword = _newPasswordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();

      //memanggil Api reset password
      final resetResponse = await _apiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      setState(() {
        _isLoading = false;
      });

      if (resetResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resetResponse.message ?? 'Reset kata sandi berhasil!',
              ),
            ),
          );
          Navigator.popUntil(context, ModalRoute.withName(AppRoutes.login));
        }
      } else {
        // Handle error dari resetPassword API
        String errorMessage =
            resetResponse.message ?? 'Gagal mengatur ulang kata sandi.';
        if (resetResponse.errors != null) {
          resetResponse.errors!.forEach((key, value) {
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

  // untuk mengirim ulang otp
  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.forgotPassword(email: widget.email);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'OTP resent successfully!'),
          ),
        );
        _startTimer(); // Untuk Mulai ulang timer setelah OTP baru dikirim
      }
    } else {
      String errorMessage = response.message ?? 'Failed to resend OTP.';
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

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reset Kata Sandi",
          style: AppTextStyles.heading1.copyWith(
           
            color: AppColors.textDark, 
          ),
        ),
        backgroundColor: AppColors.background, 
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.textDark, 
        ),
      ),
      backgroundColor: AppColors.background, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kode verifikasi telah dikirim ke **${widget.email}**. Masukkan kode dan kata sandi baru Anda.",
                style: AppTextStyles.body2.copyWith(
                
                  color: AppColors.textDark, 
                ),
              ),
              const SizedBox(height: 10),

              // Tampilan Timer
              Center(
                child:
                    _otpExpired
                        ? Text(
                          'OTP Expired. Please request again.',
                          style: AppTextStyles.body2.copyWith(
                            
                            color: AppColors.error, 
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : Text(
                          'OTP is valid in: ${_formatDuration(_currentSeconds)}',
                          style: AppTextStyles.body2.copyWith(
                            
                            fontSize:
                                16, 
                            fontWeight: FontWeight.bold,
                            color:
                                _currentSeconds < 60
                                    ? AppColors
                                        .error 
                                    : AppColors.primary, 
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // Urutan Input Field Baru
              CustomInputField(
                controller: _otpController,
                hintText: 'Kode Verifikasi (OTP)',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'OTP tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'OTP minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomInputField(
                controller: _newPasswordController,
                hintText: 'Kata Sandi Baru',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata sandi baru tidak boleh kosong.';
                  }
                  if (value.length < 8) {
                    return 'Kata sandi harus minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomInputField(
                controller: _confirmPasswordController,
                hintText: 'Konfirmasi Kata Sandi Baru',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi kata sandi tidak boleh kosong.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Kata sandi tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: _isLoading || !_otpExpired ? null : _resendOtp,
                  child: Text(
                    "Tidak menerima kode? Kirim ulang OTP",
                    style: AppTextStyles.body2.copyWith(
                      
                      color:
                          _isLoading || !_otpExpired
                              ? AppColors
                                  .textLight 
                              : AppColors
                                  .primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary, 
                    ),
                  )
                  : PrimaryButton(
                    label: 'Reset Sandi',
                    onPressed: _resetPasswordProcess,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

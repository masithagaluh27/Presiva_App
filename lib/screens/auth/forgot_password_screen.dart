import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart'; // Pastikan ini juga menggunakan AppColors baru jika ada style spesifik
import 'package:presiva/routes/app_routes.dart';
import 'package:presiva/services/api_Services.dart';
import 'package:presiva/widgets/custom_input_field.dart'; // Pastikan widget ini juga konsisten
import 'package:presiva/widgets/primary_button.dart'; // Pastikan widget ini juga konsisten

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(); // Instansiasi ApiService

  bool _isLoading = false;

  Future<void> _requestOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String email = _emailController.text.trim();
      // MEMANGGIL forgotPassword DENGAN EMAIL SESUAI PERMINTAAN ANDA
      final response = await _apiService.forgotPassword(email: email);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // Hapus 'const'
              content: Text(response.message ?? 'OTP berhasil dikirim.'),
              backgroundColor: AppColors.success(context), // <--- UBAH DI SINI
            ),
          );
          // Navigasi ke layar Reset Password dengan email yang diinput
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.resetPassword,
            arguments: email, // Kirim email ke ResetPasswordScreen
          );
        }
      } else {
        String errorMessage = response.message ?? 'Gagal meminta OTP.';
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // Hapus 'const'
              content: Text(errorMessage),
              backgroundColor: AppColors.error(context), // <--- UBAH DI SINI
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          // Hapus 'const'
          "Lupa Password",
          style: TextStyle(
            // Hapus 'const'
            color: AppColors.textDark(context), // <--- UBAH DI SINI
          ), // Menggunakan textDark untuk judul AppBar
        ),
        backgroundColor: AppColors.background(context), // <--- UBAH DI SINI
        elevation: 0, // Tanpa bayangan
        iconTheme: IconThemeData(
          // Hapus 'const'
          color: AppColors.textDark(context), // <--- UBAH DI SINI
        ), // Warna ikon kembali
      ),
      backgroundColor: AppColors.background(context), // <--- UBAH DI SINI
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Hapus 'const'
                "Masukkan email Anda untuk menerima kode verifikasi (OTP) untuk reset password.",
                style: TextStyle(
                  // Hapus 'const'
                  fontSize: 16,
                  color: AppColors.textLight(context), // <--- UBAH DI SINI
                ), // Menggunakan textLight untuk teks instruksi
              ),
              const SizedBox(height: 30),
              CustomInputField(
                controller: _emailController,
                hintText: 'Email',
                icon: Icons.email_outlined,
                // Tambahkan fillColor untuk konsistensi dengan AppColors Anda
                fillColor: AppColors.inputFill(context), // <--- TAMBAH DI SINI
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? Center(
                    // Hapus 'const'
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context), // <--- UBAH DI SINI
                    ), // Menggunakan AppColors.primary
                  )
                  : PrimaryButton(
                    label: 'Kirim Kode Verifikasi',
                    onPressed: _requestOtp,
                    // Jika PrimaryButton tidak secara otomatis mengambil tema,
                    // Anda mungkin perlu menambahkan properti seperti:
                    // buttonColor: AppColors.primary(context),
                    // textColor: AppColors.textLight(context),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

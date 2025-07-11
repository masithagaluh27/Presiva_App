import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/models/app_models.dart'; // Pastikan model ini ada
import 'package:presiva/routes/app_routes.dart';
import 'package:presiva/services/api_Services.dart';
import 'package:presiva/widgets/custom_input_field.dart';
import 'package:presiva/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // Inisialisasi ApiService Anda

  bool _isPasswordVisible = false;
  bool _isLoading = false; // Tambahkan status loading

  @override
  void initState() {
    super.initState();
    // Tunda pengecekan sesi dan navigasi hingga setelah frame pertama dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    // Periksa apakah token ada di ApiService (yang berarti pengguna sudah login)
    final isLoggedIn =
        ApiService.getToken() !=
        null; // Asumsi ApiService memiliki getter untuk token
    if (isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Atur loading menjadi true
      });

      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Panggil metode login dari ApiService
      final ApiResponse<AuthData> response = await _apiService.login(
        email: email,
        password: password,
      );

      setState(() {
        _isLoading = false; // Atur loading menjadi false
      });

      if (response.statusCode == 200 && response.data != null) {
        // Login berhasil
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        }
      } else {
        // Login gagal, tampilkan pesan error
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Latar belakang putih
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Pusatkan semua elemen di kolom
              children: [
                // Gambar Shaun the Sheep sebagai logo
                Image.asset(
                  'assets/images/shaun.jpeg', // Pastikan path gambar Anda benar
                  height: 120, // Sesuaikan tinggi sesuai screenshot
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // Judul "Login in to Presiva"
                Text(
                  "Login in to Presiva",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.textDark, // Warna teks gelap
                    fontSize: 28, // Ukuran font lebih besar
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Deskripsi
                Text(
                  "Securely access your email, calendar, and files -- all in one place.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.normal.copyWith(
                    color: AppColors.textLight, // Warna teks abu-abu
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Input
                CustomInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  customValidator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Masukkan alamat email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Input
                CustomInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: !_isPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  customValidator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Tombol Lupa Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: Text(
                      'Forgot your Password?',
                      style: TextStyle(
                        color: AppColors.primary, // Warna biru primer
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Login
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary, // Warna loading
                      ),
                    )
                    : PrimaryButton(
                      label: 'Log In',
                      onPressed: _login,
                      // Warna tombol akan diatur di primary_button.dart menjadi hitam
                    ),
                const SizedBox(height: 20),

                // Teks "Don't have an account? Create an account"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.normal.copyWith(
                        color: AppColors.textDark, // Warna teks gelap
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                      child: Text(
                        "Create an account",
                        style: TextStyle(
                          color: AppColors.primary, // Warna biru primer
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

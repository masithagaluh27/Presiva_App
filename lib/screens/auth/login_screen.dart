import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/models/app_models.dart';
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
  final ApiService _apiService = ApiService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final isLoggedIn = ApiService.getToken() != null;
    if (isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final ApiResponse<AuthData> response = await _apiService.login(
        email: email,
        password: password,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        }
      } else {
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
    // Tinggi gambar header, sesuaikan jika perlu
    final double imageHeight =
        MediaQuery.of(context).size.height *
        0.35; // 35% dari tinggi layar untuk gambar atas

    return Scaffold(
      // Tidak perlu backgroundColor di Scaffold karena Stack akan menutupi seluruhnya
      body: Stack(
        // Menggunakan Stack untuk menumpuk elemen
        children: [
          // Latar belakang gambar Shaun the Sheep penuh layar
          Positioned.fill(
            child: Image.asset(
              'assets/images/shaun.jpeg', // Path gambar Shaun Anda
              fit: BoxFit.cover, // Memastikan gambar menutupi seluruh layar
            ),
          ),
          // Overlay semi-transparan untuk "shadow" pada background
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(
                0.6,
              ), // Meningkatkan opasitas untuk shadow yang lebih kuat
            ),
          ),

          // Konten utama yang berisi logo, kartu putih, dan formulir
          Positioned.fill(
            child: SafeArea(
              // Pastikan konten tidak terpotong oleh notch/status bar
              child: Column(
                children: [
                  // Ruang kosong di atas kartu putih agar ada jarak dari atas layar
                  // Disesuaikan agar logo lingkaran berada di tengah area transisi
                  SizedBox(
                    height: imageHeight - 60,
                  ), // Sesuaikan angka 60 untuk posisi kartu relatif terhadap gambar
                  // Kartu putih dengan radius dan konten formulir
                  Expanded(
                    // Memastikan kartu putih mengisi sisa ruang ke bawah
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            AppColors.card, // Latar belakang putih untuk form
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(
                            30,
                          ), // Sudut membulat di kiri atas
                          topRight: Radius.circular(
                            30,
                          ), // Sudut membulat di kanan atas
                        ),
                        boxShadow: [
                          // Tambahkan bayangan lembut
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: const Offset(0, -5), // Bayangan ke atas
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        // Tetap gunakan SingleChildScrollView di dalam kartu
                        // <<< PERUBAHAN DI SINI: MENINGKATKAN PADDING VERTIKAL BAGIAN BAWAH
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          40,
                          24,
                          80,
                        ), // Padding atas 40, bawah 80
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo Shaun the Sheep kecil di dalam kartu (lingkaran)
                              // Posisikan logo sedikit ke atas agar tumpang tindih dengan background
                              Transform.translate(
                                offset: const Offset(
                                  0.0,
                                  -80.0,
                                ), // Mengangkat logo ke atas
                                child: Container(
                                  width:
                                      120, // Ukuran container untuk lingkaran
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        AppColors
                                            .card, // Background putih untuk lingkaran logo
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 3,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/shaun_logo_small.png', // Path logo kecil Shaun Anda
                                      height:
                                          100, // Ukuran gambar di dalam lingkaran
                                      width: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              // Sesuaikan spasi setelah logo yang diangkat
                              const SizedBox(
                                height: -60,
                              ), // Mengurangi spasi karena logo sudah diangkat
                              // Judul "Login in to Presiva"
                              Text(
                                "Login in to Presiva",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Deskripsi
                              Text(
                                "Securely access your email, calendar, and files -- all in one place.",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.normal.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Email Input
                              CustomInputField(
                                controller: _emailController,
                                hintText: 'Email Address',
                                icon: Icons.email_outlined,
                                customValidator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(value)) {
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
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.forgotPassword,
                                    );
                                  },
                                  child: Text(
                                    'Forgot your Password?',
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
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
                                      color: AppColors.primaryLight,
                                    ),
                                  )
                                  : PrimaryButton(
                                    label: 'Log In',
                                    onPressed: _login,
                                  ),
                              const SizedBox(height: 20),

                              // Teks "Don't have an account? Create an account"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: AppTextStyles.normal.copyWith(
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap:
                                        () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.register,
                                        ),
                                    child: Text(
                                      "Create an account",
                                      style: TextStyle(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Tambahkan SizedBox di bagian paling bawah untuk memastikan scrollable
                              const SizedBox(
                                height: 20,
                              ), // Tambahan padding di paling bawah
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

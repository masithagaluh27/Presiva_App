import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/services/api_Services.dart';

import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Wait for the splash screen animation to play
    await Future.delayed(const Duration(seconds: 3));

    // Initialize ApiService to load the token from SharedPreferences
    // This is crucial to ensure the token is available before checking login status
    await ApiService.init();

    // Check if a token exists in ApiService (which means a user is logged in)
    final isLoggedIn =
        ApiService.getToken() !=
        null; // Assuming ApiService has a getter for token

    final nextRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;

    if (!mounted) return;

    // Navigate to the appropriate route
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Latar belakang Deep Navy Blue
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon alarm dengan warna emas/bronze
              const Icon(
                Icons.panorama_photosphere_select_outlined,
                size: 90,
                color: AppColors.gold,
              ),
              const SizedBox(height: 20),
              // Teks 'PRESIVA APP' dengan gaya heading dan warna emas/bronze
              Text(
                'PRESIVA APP',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.gold, // Terapkan warna emas/bronze di sini
                ),
              ),
              const SizedBox(height: 10),
              // Teks tagline dengan gaya normal dan warna teks terang (misal: abu-abu muda)
              Text(
                'Welcome to the future of attendance!',
                textAlign: TextAlign.center,
                style: AppTextStyles.normal.copyWith(
                  color:
                      AppColors
                          .textLight, // Warna abu-abu muda agar kontras dengan background gelap
                ),
              ),
              const SizedBox(height: 30),
              // CircularProgressIndicator dengan warna emas/bronze
              const CircularProgressIndicator(color: AppColors.primaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

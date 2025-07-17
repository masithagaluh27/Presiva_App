import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presiva/api/api_Services.dart';

import '../endpoint/app_routes.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    await ApiService.init();
    final isLoggedIn = ApiService.getToken() != null;
    final nextRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;

    if (!mounted) return;
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
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Presiva_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              // const Text(
              //   'PRESIVA',
              //   style: TextStyle(
              //     fontSize: 34,
              //     fontWeight: FontWeight.w700,
              //     letterSpacing: 1.5,
              //     color: Color(0xFF333333),
              //   ),
              // ),
              // const SizedBox(height: 10),

              // Tagline
              const Text(
                'Smart Attendance System',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Color(0xFF9E9E9E),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

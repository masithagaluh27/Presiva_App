import 'dart:async'; // Digunakan untuk Future.delayed dan Timer (meskipun timer tidak di sini, tetap dipertahankan jika ada kebutuhan di masa depan)

import 'package:flutter/material.dart'; // Import utama untuk widget Flutter
import 'package:presiva/services/api_Services.dart'; // Import untuk API service

import '../routes/app_routes.dart'; // Import untuk definisi rute aplikasi

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

    // Inisialisasi AnimationController untuk durasi 1.5 detik
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this, // Menggunakan SingleTickerProviderStateMixin
    );

    // Inisialisasi CurvedAnimation untuk efek fade in/out yang halus
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Kurva yang masuk dan keluar secara perlahan
    );

    // Memulai animasi fade in
    _animationController.forward();

    // Memulai urutan splash screen (delay, inisialisasi API, navigasi)
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Menunggu 3 detik sebelum melanjutkan
    await Future.delayed(const Duration(seconds: 3));
    // Inisialisasi layanan API
    await ApiService.init();

    // Mengecek apakah pengguna sudah login (token tersedia)
    final isLoggedIn = ApiService.getToken() != null;
    // Menentukan rute berikutnya berdasarkan status login
    final nextRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;

    // Memastikan widget masih terpasang sebelum melakukan navigasi
    if (!mounted) return;

    // Navigasi ke rute berikutnya, menggantikan rute splash screen
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    // Membuang controller animasi saat widget dibuang
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background putih bersih untuk splash screen
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity:
              _fadeAnimation, // Animasi fade diterapkan pada seluruh konten
          child: Column(
            mainAxisSize: MainAxisSize.min, // Membuat kolom sekecil mungkin
            children: [
              // Gambar logo Presiva
              Image.asset(
                'assets/images/shaun.jpeg', // Pastikan path ini benar
                width: 120, // Lebar gambar
                height: 120, // Tinggi gambar
              ),
              const SizedBox(height: 20), // Spasi vertikal
              // Teks 'PRESIVA'
              Text(
                'PRESIVA',
                style: TextStyle(color: Color(0xFF42A5F5)), // Warna biru terang
              ),

              const SizedBox(height: 10), // Spasi vertikal
              // Teks slogan/deskripsi
              Text(
                'Welcome to the future of attendance!',
                textAlign: TextAlign.center, // Teks rata tengah
                style: TextStyle(
                  color: Color(0xFF424242),
                ), // Warna abu-abu gelap
              ),

              const SizedBox(height: 30), // Spasi vertikal

              CircularProgressIndicator(
                // Warna indikator loading sama dengan warna utama logo
                color: const Color(0xFF42A5F5), // Warna biru terang
              ),
            ],
          ),
        ),
      ),
    );
  }
}

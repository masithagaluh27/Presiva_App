import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart'; // Penting: pastikan ini diimpor

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Tinggi standar tombol
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppColors
                  .primaryLight, // <<< INI PENTING: Warna tombol diatur di sini
          foregroundColor:
              AppColors
                  .textDark, // Warna teks tombol menyesuaikan screenshot (hitam)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

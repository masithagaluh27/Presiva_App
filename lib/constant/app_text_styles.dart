// constant/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart'; // Import AppColors

class AppTextStyles {
  // Constructor privat agar tidak bisa diinstansiasi secara langsung
  AppTextStyles._();

  // Method statis untuk Heading 1
  static TextStyle heading1(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark(
        context,
      ), // Menggunakan AppColors dengan context
    );
  }

  // Method statis untuk Heading 2
  static TextStyle heading2(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark(
        context,
      ), // Menggunakan AppColors dengan context
    );
  }

  // Method statis untuk Body 1
  static TextStyle body1(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      color: AppColors.textDark(
        context,
      ), // Menggunakan AppColors dengan context
    );
  }

  // Method statis untuk Body 2
  static TextStyle body2(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: AppColors.textDark(
        context,
      ), // Menggunakan AppColors dengan context
    );
  }

  // Method statis untuk Body 3 dengan parameter opsional
  static TextStyle body3({
    required BuildContext context, // Wajib menyertakan context
    Color? color,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: 12,
      color:
          color ??
          AppColors.textLight(
            context,
          ), // Menggunakan color parameter jika ada, default ke textLight dengan context
      fontWeight: fontWeight,
    );
  }

  static TextStyle extraLargeBold(BuildContext context) {
    return TextStyle(
      color: AppColors.textLight(
        context,
      ), // Menggunakan AppColors dengan context
    );
  }

  static TextStyle medium(BuildContext context) {
    return TextStyle(
      color: AppColors.textLight(
        context,
      ), // Menggunakan AppColors dengan context
    );
  }

  // Tambahkan gaya teks lainnya sesuai kebutuhan Anda, selalu sertakan BuildContext
}

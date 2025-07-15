// constant/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart'; // Import AppColors

class AppTextStyles {
  // Constructor privat agar tidak bisa diinstansiasi secara langsung
  AppTextStyles._();

  // Method statis untuk Heading 1
  static TextStyle heading1(BuildContext context) {
    return TextStyle(
      fontSize: 28, // Contoh ukuran lebih besar
      fontWeight: FontWeight.bold,
      color: AppColors.textDark(context),
    );
  }

  // Method statis untuk Heading 2
  static TextStyle heading2(BuildContext context) {
    return TextStyle(
      fontSize: 22, // Contoh ukuran
      fontWeight: FontWeight.bold,
      color: AppColors.textDark(context),
    );
  }

  // Tambahan: Method statis untuk Heading 3 (misal untuk nilai di stat item)
  static TextStyle heading3(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark(context),
    );
  }

  // Tambahan: Method statis untuk Heading 4 (misal untuk nilai di stat item yang lebih kecil)
  static TextStyle heading4(BuildContext context) {
    return TextStyle(
      fontSize: 17, // Ukuran yang saya gunakan di _buildStatListItem
      fontWeight: FontWeight.bold,
      color: AppColors.textDark(context),
    );
  }

  // Method statis untuk Body 1 (teks utama)
  static TextStyle body1(BuildContext context) {
    return TextStyle(fontSize: 16, color: AppColors.textDark(context));
  }

  // Method statis untuk Body 2 (teks sekunder/detail)
  static TextStyle body2(BuildContext context) {
    return TextStyle(fontSize: 14, color: AppColors.textDark(context));
  }

  // Method statis untuk Body 3 (teks kecil/metadata)
  static TextStyle body3({
    required BuildContext context,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: 12, // Ukuran yang saya gunakan di chart
      color: color ?? AppColors.textLight(context),
      fontWeight: fontWeight,
    );
  }

  // Tambahan: Method statis untuk gaya teks tombol
  static TextStyle button(BuildContext context) {
    return TextStyle(
      fontSize: 18, // Ukuran yang nyaman untuk tombol
      fontWeight: FontWeight.bold,
      color: AppColors.onPrimary(context),
    );
  }

  // Gaya yang tidak memiliki ukuran spesifik (jika masih ingin mempertahankannya)
  // Sebaiknya, tentukan fontSize dan fontWeight untuk semua gaya teks.
  static TextStyle extraLargeBold(BuildContext context) {
    return TextStyle(
      fontSize: 32, // Contoh ukuran
      fontWeight: FontWeight.bold,
      color: AppColors.textLight(context),
    );
  }

  static TextStyle medium(BuildContext context) {
    return TextStyle(
      fontSize: 16, // Contoh ukuran
      fontWeight: FontWeight.w500,
      color: AppColors.textLight(context),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  // Definisi warna dasar untuk Light Mode (sekarang menjadi satu-satunya definisi)
  static const Color primary = Color(0xFF2C3E50); // Dark Slate Gray / Deep Navy
  static const Color primaryLight = Color(
    0xFF34495E,
  ); // Slightly lighter primary for subtle variations
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(
    0xFF3498DB,
  ); // A vibrant, clean blue for actionable elements

  static const Color background = Color(
    0xFFF8F9FA,
  ); // Very light gray, almost white
  static const Color cardBackground =
      Colors.white; // Pure white for cards/containers
  static const Color inputFill = Color(
    0xFFECEFF1,
  ); // Soft gray for input fields, clearer contrast

  static const Color textDark = Color(0xFF212529); // Rich black for main text
  static const Color textLight = Color(
    0xFF6C757D,
  ); // Muted gray for secondary text
  static const Color placeholder = Color(
    0xFFADB5BD,
  ); // Lighter gray for placeholders

  static const Color border = Color(0xFFDEE2E6); // Light gray for borders

  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  static const Color successBackground = Color(0xFFD4EDDA);
  static const Color dangerBackground = Color(0xFFF8D7DA);
  static const Color warningBackground = Color(0xFFFFF3CD);

  static const Color disabledButton = Color(0xFFCED4DA);
  static const Color shadowColor = Color(0x1A000000);

  // Tambahan untuk onPrimary dan onError
  static const Color onPrimary =
      Colors.white; // Warna teks/ikon di atas primary
  static const Color onError = Colors.white; // Warna teks/ikon di atas error

  // New divider color
  static const Color divider = Color(
    0xFFE0E0E0,
  ); // A subtle light gray for dividers
}

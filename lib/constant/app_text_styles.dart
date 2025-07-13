import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';

class AppTextStyles {
  // Base text styles for consistency and reusability
  // These are private as they are meant to be used internally by other static methods.
  static const TextStyle _baseHeading = TextStyle(
    fontFamily: 'Montserrat', // Contoh font premium
    // Default font size and weight will be defined in specific heading styles
  );

  static const TextStyle _baseBody = TextStyle(
    fontFamily: 'Roboto', // Contoh font lain
    // Default font size and weight will be defined in specific body styles
  );

  // --- Heading Styles ---
  // Large heading, e.g., for screen titles
  static TextStyle heading1({FontWeight? fontWeight, Color? color}) =>
      _baseHeading.copyWith(
        fontSize: 32, // Ukuran lebih besar dari 24
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textDark, // Default warna gelap
      );

  // Main heading, often used for major sections
  static TextStyle heading2({FontWeight? fontWeight, Color? color}) =>
      _baseHeading.copyWith(
        fontSize: 24, // Sesuai dengan `heading` yang lama
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textDark,
      );

  // Sub-heading or prominent text
  static TextStyle heading3({FontWeight? fontWeight, Color? color}) =>
      _baseHeading.copyWith(
        fontSize: 20,
        fontWeight:
            fontWeight ?? FontWeight.w600, // Sedikit lebih tebal dari normal
        color: color ?? AppColors.textDark,
      );

  // --- Body Text Styles ---
  // Larger body text, e.g., for important paragraphs
  static TextStyle body1({FontWeight? fontWeight, Color? color}) =>
      _baseBody.copyWith(
        fontSize: 18,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textDark,
      );

  // Standard body text, e.g., for most paragraphs.
  // This corresponds to your old `normal` style.
  static TextStyle body2({FontWeight? fontWeight, Color? color}) =>
      _baseBody.copyWith(
        fontSize: 16, // Sesuai dengan `normal` yang lama
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textDark,
      );

  // Smaller body text, e.g., for descriptions or less prominent info
  static TextStyle body3({FontWeight? fontWeight, Color? color}) =>
      _baseBody.copyWith(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textDark,
      );

  // --- Caption/Small Text Styles ---
  // Smallest text, e.g., for captions, timestamps, or disclaimers
  static TextStyle caption({FontWeight? fontWeight, Color? color}) =>
      _baseBody.copyWith(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.normal,
        color:
            color ??
            AppColors.textLight, // Default warna lebih terang untuk caption
      );
}

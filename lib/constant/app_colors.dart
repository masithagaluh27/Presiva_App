import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2C3E50); // Dark Slate Gray / Deep Navy
  static const Color primaryLight = Color(
    0xFF34495E,
  ); // Slightly lighter primary for subtle variations
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(
    0xFF3498DB,
  ); // A vibrant, clean blue for actionable elements

  // Backgrounds - Lighter, cleaner
  static const Color background = Color(
    0xFFF8F9FA,
  ); // Very light gray, almost white
  static const Color cardBackground =
      Colors.white; // Pure white for cards/containers
  static const Color inputFill = Color(
    0xFFECEFF1,
  ); // Soft gray for input fields, clearer contrast

  // Text - Improved readability
  static const Color textDark = Color(0xFF212529); // Rich black for main text
  static const Color textLight = Color(
    0xFF6C757D,
  ); // Muted gray for secondary text
  static const Color placeholder = Color(
    0xFFADB5BD,
  ); // Lighter gray for placeholders

  // Borders & dividers - Softer, less intrusive
  static const Color border = Color(0xFFDEE2E6); // Light gray for borders

  // States - Clear and distinct
  static const Color success = Color(
    0xFF28A745,
  ); // Standard green for success (e.g., Present)
  static const Color error = Color(
    0xFFDC3545,
  ); // Standard red for critical (e.g., Absents, Check Out button)
  static const Color warning = Color(
    0xFFFFC107,
  ); // Standard amber for warnings (e.g., Late in)
  static const Color info = Color(0xFF2196F3);

  // Specific light background colors for the summary cards
  static const Color lightSuccessBackground = Color(
    0xFFD4EDDA,
  ); // Softer green for card background
  static const Color lightDangerBackground = Color(
    0xFFF8D7DA,
  ); // Softer red for card background
  static const Color lightWarningBackground = Color(
    0xFFFFF3CD,
  ); // Softer orange for card background

  // Additional useful colors (optional, but good to have)
  static const Color disabledButton = Color(
    0xFFCED4DA,
  ); // Gray for disabled buttons
  static const Color shadowColor = Color(
    0x1A000000,
  ); // Light black for subtle shadows
}

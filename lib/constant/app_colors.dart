import 'package:flutter/material.dart';

class AppColors {
  // Ini adalah definisi warna dasar untuk Light Mode
  // Anda bisa menjaga ini sebagai referensi, tetapi yang akan digunakan di getter adalah nilai dinamis.
  static const Color _lightPrimary = Color(
    0xFF2C3E50,
  ); // Dark Slate Gray / Deep Navy
  static const Color _lightPrimaryLight = Color(
    0xFF34495E,
  ); // Slightly lighter primary for subtle variations
  static const Color _lightSecondary = Color(0xFF03DAC6);
  static const Color _lightAccent = Color(
    0xFF3498DB,
  ); // A vibrant, clean blue for actionable elements

  static const Color _lightBackground = Color(
    0xFFF8F9FA,
  ); // Very light gray, almost white
  static const Color _lightCardBackground =
      Colors.white; // Pure white for cards/containers
  static const Color _lightInputFill = Color(
    0xFFECEFF1,
  ); // Soft gray for input fields, clearer contrast

  static const Color _lightTextDark = Color(
    0xFF212529,
  ); // Rich black for main text
  static const Color _lightTextLight = Color(
    0xFF6C757D,
  ); // Muted gray for secondary text
  static const Color _lightPlaceholder = Color(
    0xFFADB5BD,
  ); // Lighter gray for placeholders

  static const Color _lightBorder = Color(0xFFDEE2E6); // Light gray for borders

  static const Color _lightSuccess = Color(0xFF28A745);
  static const Color _lightError = Color(0xFFDC3545);
  static const Color _lightWarning = Color(0xFFFFC107);
  static const Color _lightInfo = Color(0xFF2196F3);

  static const Color _lightSuccessBackground = Color(0xFFD4EDDA);
  static const Color _lightDangerBackground = Color(0xFFF8D7DA);
  static const Color _lightWarningBackground = Color(0xFFFFF3CD);

  static const Color _lightDisabledButton = Color(0xFFCED4DA);
  static const Color _lightShadowColor = Color(0x1A000000);

  // Tambahan untuk onPrimary dan onError di Light Mode
  static const Color _lightOnPrimary =
      Colors.white; // Warna teks/ikon di atas primary
  static const Color _lightOnError =
      Colors.white; // Warna teks/ikon di atas error

  // New divider color for light mode
  static const Color _lightDivider = Color(
    0xFFE0E0E0,
  ); // A subtle light gray for dividers

  // Ini adalah definisi warna dasar untuk Dark Mode
  static const Color _darkPrimary = Color(
    0xFF1A2633,
  ); // Darker shade of your primary
  static const Color _darkPrimaryLight = Color(
    0xFF223140,
  ); // Slightly lighter dark primary
  static const Color _darkSecondary = Color(0xFF03DAC6);
  static const Color _darkAccent = Color(
    0xFF64B5F6,
  ); // Brighter blue for accent in dark mode

  static const Color _darkBackground = Color(
    0xFF121212,
  ); // Very dark gray, almost black
  static const Color _darkCardBackground = Color(
    0xFF1E1E1E,
  ); // Slightly lighter dark for cards
  static const Color _darkInputFill = Color(
    0xFF2A2A2A,
  ); // Darker gray for input fields

  static const Color _darkTextDark = Color(
    0xFFE0E0E0,
  ); // Light grey for main text
  static const Color _darkTextLight = Color(
    0xFFB0B0B0,
  ); // Muted light grey for secondary text
  static const Color _darkPlaceholder = Color(
    0xFF8D8D8D,
  ); // Darker gray for placeholders

  static const Color _darkBorder = Color(0xFF333333); // Darker gray for borders

  static const Color _darkSuccess = Color(0xFF66BB6A);
  static const Color _darkError = Color(0xFFEF5350);
  static const Color _darkWarning = Color(0xFFFFD54F);
  static const Color _darkInfo = Color(0xFF64B5F6);
  static const Color _white70 = Color(0xB3FFFFFF);
  static const Color _darkSuccessBackground = Color(0xFF2A422D);
  static const Color _darkDangerBackground = Color(0xFF4C2A2D);
  static const Color _darkWarningBackground = Color(0xFF4C422A);

  static const Color _darkDisabledButton = Color(0xFF424242);
  static const Color _darkShadowColor = Color(0x33FFFFFF);

  // Tambahan untuk onPrimary dan onError di Dark Mode
  static const Color _darkOnPrimary =
      Colors.white; // Warna teks/ikon di atas primary
  static const Color _darkOnError =
      Colors.white; // Warna teks/ikon di atas error

  // New divider color for dark mode
  static const Color _darkDivider = Color(
    0xFF424242,
  ); // A darker gray for dividers in dark mode

  // Getters publik yang menggunakan nama asli dan mengembalikan warna berdasarkan tema
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightPrimary
          : _darkPrimary;
  static Color primaryLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightPrimaryLight
          : _darkPrimaryLight;
  static Color secondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightSecondary
          : _darkSecondary;
  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightAccent
          : _darkAccent;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightBackground
          : _darkBackground;
  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightCardBackground
          : _darkCardBackground;
  static Color inputFill(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightInputFill
          : _darkInputFill;

  static Color textDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightTextDark
          : _darkTextDark;
  static Color textLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightTextLight
          : _darkTextLight;
  static Color placeholder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightPlaceholder
          : _darkPlaceholder;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightBorder
          : _darkBorder;

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightSuccess
          : _darkSuccess;
  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightError
          : _darkError;
  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightWarning
          : _darkWarning;
  static Color info(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? _lightInfo : _darkInfo;

  static Color lightSuccessBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightSuccessBackground
          : _darkSuccessBackground;
  static Color lightDangerBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightDangerBackground
          : _darkDangerBackground;
  static Color lightWarningBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightWarningBackground
          : _darkWarningBackground;

  static Color disabledButton(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightDisabledButton
          : _darkDisabledButton;
  static Color shadowColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightShadowColor
          : _darkShadowColor;

  // Getters yang baru ditambahkan
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightOnPrimary
          : _darkOnPrimary;

  static Color onError(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightOnError
          : _darkOnError;

  // New getter for divider color
  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightDivider
          : _darkDivider;
}

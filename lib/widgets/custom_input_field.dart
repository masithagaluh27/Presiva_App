import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? toggleVisibility;

  final String? labelText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? customValidator;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool readOnly;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.toggleVisibility,
    this.labelText,
    this.maxLines = 1,
    this.keyboardType,
    this.customValidator,
    this.fillColor,
    this.contentPadding,
    this.readOnly = false,
  });

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your ${hintText.toLowerCase()}';
    }

    if (hintText.toLowerCase().contains('email')) {
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    if (hintText.toLowerCase().contains('password')) {
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    }

    if (hintText.toLowerCase().contains('username') ||
        hintText.toLowerCase().contains('name')) {
      if (value.length < 3) {
        return '$hintText must be at least 3 characters';
      }
    }

    return null; // valid
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: customValidator ?? _defaultValidator,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textDark(context),
      ), // <<< Tambahkan warna teks dinamis
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        // labelStyle dan hintStyle juga bisa menggunakan warna dinamis jika diperlukan
        labelStyle: TextStyle(
          color: AppColors.textLight(context),
        ), // <<< Tambahkan warna label dinamis
        hintStyle: TextStyle(
          color: AppColors.placeholder(context),
        ), // <<< Tambahkan warna hint dinamis

        prefixIcon: Icon(
          icon,
          color: AppColors.primary(context),
        ), // <<< Perubahan di sini
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textLight(
                      context,
                    ), // <<< Perubahan di sini, menggunakan warna dinamis
                  ),
                  onPressed: toggleVisibility,
                )
                : null,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        filled: true,
        fillColor:
            fillColor ??
            AppColors.inputFill(
              context,
            ), // <<< Perubahan di sini, menggunakan warna dinamis
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ), // <<< Perubahan di sini
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ), // <<< Perubahan di sini
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary(context),
          ), // <<< Perubahan di sini
        ),
      ),
    );
  }
}

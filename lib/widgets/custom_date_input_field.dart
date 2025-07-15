import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart';

class CustomDateInputField extends StatelessWidget {
  final String labelText;
  final IconData icon;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final String? hintText;

  const CustomDateInputField({
    super.key,
    required this.labelText,
    required this.icon,
    required this.selectedDate,
    required this.onTap,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppColors.textLight, // <<< Perubahan di sini
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: AppColors.inputFill,
          prefixIcon: Icon(icon, color: AppColors.primary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        baseStyle: TextStyle(fontSize: 16, color: AppColors.textDark),
        child: Text(
          selectedDate == null
              ? hintText ?? 'Select ${labelText.toLowerCase()}'
              : DateFormat('yyyy-MM-dd').format(selectedDate!),
          style: TextStyle(
            color:
                selectedDate == null
                    ? AppColors.placeholder
                    : AppColors.textDark,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

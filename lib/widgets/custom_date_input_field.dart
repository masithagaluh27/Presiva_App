import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart';

class CustomDateInputField extends StatelessWidget {
  final String labelText;
  final IconData icon;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final String? hintText; // Optional hint text for when no date is chosen

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
            // Ubah const TextStyle menjadi TextStyle biasa karena color-nya dinamis
            color: AppColors.textLight(context), // <<< Perubahan di sini
          ),
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
          filled: true,
          fillColor: AppColors.inputFill(context), // <<< Perubahan di sini
          prefixIcon: Icon(
            icon,
            color: AppColors.primary(context), // <<< Perubahan di sini
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        baseStyle: TextStyle(
          // Ubah const TextStyle menjadi TextStyle biasa karena color-nya dinamis
          fontSize: 16,
          color: AppColors.textDark(context), // <<< Perubahan di sini
        ),
        child: Text(
          selectedDate == null
              ? hintText ?? 'Select ${labelText.toLowerCase()}'
              : DateFormat('yyyy-MM-dd').format(selectedDate!),
          style: TextStyle(
            color:
                selectedDate == null
                    ? AppColors.placeholder(context) // <<< Perubahan di sini
                    : AppColors.textDark(context), // <<< Perubahan di sini
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

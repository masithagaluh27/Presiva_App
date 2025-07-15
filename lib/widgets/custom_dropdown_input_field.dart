import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';

class CustomDropdownInputField<T> extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? menuMaxHeight;
  final String? Function(T?)? validator;

  const CustomDropdownInputField({
    super.key,
    required this.labelText,
    this.hintText,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.menuMaxHeight,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hintText ?? 'Select ${labelText.toLowerCase()}',
        style: TextStyle(color: AppColors.placeholder),
      ),
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.textLight),
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
      menuMaxHeight: menuMaxHeight,
      validator: validator,
      isExpanded: true,
    );
  }
}

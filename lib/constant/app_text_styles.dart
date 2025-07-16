import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );
  static TextStyle body3({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 12,
      color: color ?? AppColors.textLight,
      fontWeight: fontWeight,
    );
  }

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimary,
  );

  static const TextStyle extraLargeBold = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
  );

  static const TextStyle medium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );
}

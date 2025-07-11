import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Montserrat', // Contoh font premium
    fontSize: 24,
    fontWeight: FontWeight.bold,
    // Jangan set warna di sini jika ingin di-override di tempat lain
    // color: AppColors.textDark, // Misal, ini bisa menyebabkan konflik jika di-override
  );

  static const TextStyle normal = TextStyle(
    fontFamily: 'Roboto', // Contoh font lain
    fontSize: 16,
    // color: AppColors.textLight, // Atau jangan set di sini
  );

}

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final IconData icon; // New parameter for the IconData

  const AppLogo({
    super.key,
    this.size = 100,
    this.icon = Icons.calendar_today, // Default to a common calendar icon for attendance
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: Theme.of(context).primaryColor, // Example: use primary color of the theme
    );
  }
}
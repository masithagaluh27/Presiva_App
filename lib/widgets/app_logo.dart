import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final IconData icon; 

  const AppLogo({
    super.key,
    this.size = 100,
    this.icon = Icons.calendar_today, 
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: Theme.of(context).primaryColor, 
    );
  }
}

import 'package:flutter/material.dart';
import 'package:presiva/constant/app_colors.dart';


class CustomBottomNavigationBar extends StatelessWidget {
  
  final int currentIndex;
  final Function(int) onTap;

  /// Creates a [CustomBottomNavigationBar].
  ///
  /// [currentIndex] is required and determines which icon is highlighted.
  /// [onTap] is required and is called when a navigation item is tapped.
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primary, // Color for selected icon/label
      unselectedItemColor: Colors.grey, // Color for unselected icons/labels
      backgroundColor: Colors.white, // Background color of the navigation bar
      type:
          BottomNavigationBarType
              .fixed, // Ensures all labels are always visible
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time), // Icon for attendance/clock-in
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart), // Icon for reports/statistics
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), // Icon for reports/statistics
          label: 'Profile',
        ),
      ],
    );
  }
}

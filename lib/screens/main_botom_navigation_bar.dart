import 'package:flutter/material.dart';
import 'package:presiva/screens/attendance/attendance_list_screen.dart';
import 'package:presiva/screens/authentication/profile_screen.dart';
import 'package:presiva/screens/homescreen.dart';
import 'package:presiva/screens/reports/person_report_Screen.dart';
import 'package:presiva/widgets/custom_bottom_navigation_bar.dart';

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({super.key});
 static final ValueNotifier<bool> refreshHomeNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<bool> refreshAttendanceNotifier =
      ValueNotifier<bool>(false);
  // ValueNotifier for PersonReportScreen
  static final ValueNotifier<bool> refreshReportsNotifier = ValueNotifier<bool>(
    false,
  );
  // ValueNotifier for ProfileScreen
  static final ValueNotifier<bool> refreshProfileNotifier = ValueNotifier<bool>(
    false,
  );

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _selectedIndex = 0; // Start with Home tab 

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(
        refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier,
      ),  AttendanceListScreen(
        refreshNotifier: MainBottomNavigationBar.refreshAttendanceNotifier,
      ),     PersonReportScreen(
        refreshNotifier: MainBottomNavigationBar.refreshReportsNotifier,
      ),     ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshProfileNotifier,
      ), 
    ];
  }

    void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }

       if (index == 0) {
      MainBottomNavigationBar.refreshHomeNotifier.value =
          true; // Set value via widget name
    }
      else if (index == 1) {
      MainBottomNavigationBar.refreshAttendanceNotifier.value =
          true; 
    }
   else if (index == 2) {
      MainBottomNavigationBar.refreshReportsNotifier.value =
          true; 
    }    else if (index == 3) {
      MainBottomNavigationBar.refreshProfileNotifier.value =
          true;
    }  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex:
            _selectedIndex, 
        onTap: _onItemTapped, 
      ),
    );
  }
}

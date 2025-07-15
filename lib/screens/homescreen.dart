import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/models/app_models.dart';
import 'package:presiva/screens/attendance/request_screen.dart';
import 'package:presiva/screens/main_botom_navigation_bar.dart';
import 'package:presiva/services/api_Services.dart';


class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;
  const HomeScreen({super.key, required this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String _location = 'Getting Location...';
  String _currentDate = '';
  String _currentTime = '';
  Timer? _timer;

  AbsenceToday? _todayAbsence;
  AbsenceStats? _absenceStats;

  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _isCheckingInOrOut = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateDateTime();
    _determinePosition();
    _loadUserProfile();
    _fetchAttendanceData();

    widget.refreshNotifier.addListener(_handleRefreshSignal);

    // Timer untuk memperbarui jam setiap detik
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _fetchAttendanceData();
      _loadUserProfile();
      widget.refreshNotifier.value = false;
    }
  }

  // --- Fungsi untuk memuat profil pengguna ---
  Future<void> _loadUserProfile() async {
    final ApiResponse<User> response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _currentUser = response.data;
      });
    } else {
      print('Failed to load user profile: ${response.message}');
      setState(() {
        _currentUser = null;
      });
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      // Memastikan jam update setiap detik dengan format HH:mm:ss
      _currentDate = DateFormat(
        'EEEE, dd MMMM yyyy',
        'id_ID',
      ).format(now); // Added locale
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showErrorDialog('Location services are disabled. Please enable them.');
      }
      setState(() {
        _location = 'Location services disabled';
        _permissionGranted = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showErrorDialog(
            'Location permissions are denied. Please grant them in settings.',
          );
        }
        setState(() {
          _location = 'Location permissions denied';
          _permissionGranted = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
      setState(() {
        _location = 'Location permissions permanently denied';
        _permissionGranted = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _permissionGranted = true;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        _showErrorDialog('Failed to get current location: $e');
      }
      setState(() {
        _location = 'Failed to get location';
        _permissionGranted = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        // localeIdentifier: 'id_ID', // Uncomment if needed and supported for better accuracy
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Prioritize street, subLocality (kecamatan), locality (kota), administrativeArea (provinsi)
          _location = [
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
              ]
              .where((element) => element != null && element.isNotEmpty)
              .join(', ');
          if (_location.isEmpty) {
            _location = 'Unknown address'; // Fallback if no parts are found
          }
        });
      } else {
        setState(() {
          _location =
              'Address not found'; // Explicitly set if placemarks is empty
        });
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      setState(() {
        _location = 'Address not found'; // Handle error case
      });
    }
  }

  Future<void> _fetchAttendanceData() async {
    final ApiResponse<AbsenceToday> todayAbsenceResponse =
        await _apiService.getAbsenceToday();
    if (todayAbsenceResponse.statusCode == 200 &&
        todayAbsenceResponse.data != null) {
      setState(() {
        _todayAbsence = todayAbsenceResponse.data;
      });
    } else {
      print('Failed to get today\'s absence: ${todayAbsenceResponse.message}');
      setState(() {
        _todayAbsence = null;
      });
    }

    final ApiResponse<AbsenceStats> statsResponse =
        await _apiService.getAbsenceStats();
    if (statsResponse.statusCode == 200 && statsResponse.data != null) {
      setState(() {
        _absenceStats = statsResponse.data;
      });
    } else {
      print('Failed to get absence stats: ${statsResponse.message}');
      setState(() {
        _absenceStats = null;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition();
      return;
    }
    if (_isCheckingInOrOut) return;

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final String formattedCheckInTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkIn(
        checkInLat: _currentPosition!.latitude,
        checkInLng: _currentPosition!.longitude,
        checkInAddress: _location,
        status: 'masuk',
        attendanceDate: formattedAttendanceDate,
        checkInTime: formattedCheckInTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        _fetchAttendanceData();
        MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showErrorDialog('Check In Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-in: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition();
      return;
    }
    if (_isCheckingInOrOut) return;

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final String formattedCheckOutTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkOut(
        checkOutLat: _currentPosition!.latitude,
        checkOutLng: _currentPosition!.longitude,
        checkOutAddress: _location,
        attendanceDate: formattedAttendanceDate,
        checkOutTime: formattedCheckOutTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        _fetchAttendanceData();
        MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showErrorDialog('Check Out Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-out: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.background(context),
            title: Text(
              'Error',
              style: TextStyle(color: AppColors.textDark(context)),
            ),
            content: Text(
              message,
              style: TextStyle(color: AppColors.textDark(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(color: AppColors.primary(context)),
                ),
              ),
            ],
          ),
    );
  }

  String _calculateWorkingHours() {
    if (_todayAbsence == null || _todayAbsence!.jamMasuk == null) {
      return '00:00:00'; // Return 0 if not checked in
    }

    final DateTime checkInDateTime = _todayAbsence!.jamMasuk!;
    DateTime endDateTime;

    if (_todayAbsence!.jamKeluar != null) {
      endDateTime = _todayAbsence!.jamKeluar!;
    } else {
      endDateTime = DateTime.now();
    }

    // Ensure the duration is not negative. If for some reason checkOut is before checkIn,
    // or if only checkIn exists and it's in the future (unlikely but for robustness),
    // we should return 0 or handle it as an invalid state.
    if (endDateTime.isBefore(checkInDateTime)) {
      return '00:00:00'; // Or consider showing an error/N/A
    }

    final Duration duration = endDateTime.difference(checkInDateTime);

    // Ensure non-negative duration parts
    final int hours = duration.inHours.abs();
    final int minutes = duration.inMinutes.remainder(60).abs();
    final int seconds = duration.inSeconds.remainder(60).abs();

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Fungsi untuk Sapaan Dinamis ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting = '';
    String honorific = '';

    // Penentuan waktu
    if (hour >= 5 && hour < 12) {
      // 05:00 - 11:59
      greeting = 'Selamat Pagi';
    } else if (hour >= 12 && hour < 18) {
      // 12:00 - 17:59
      greeting = 'Selamat Siang';
    } else if (hour >= 18 && hour < 22) {
      // 18:00 - 21:59
      greeting = 'Selamat Malam';
    } else {
      // 22:00 - 04:59
      greeting = 'Selamat Tidur'; // Atau 'Selamat Malam'
    }

    // Penentuan panggilan berdasarkan gender dari _currentUser
    if (_currentUser?.jenis_kelamin != null) {
      final userGender = _currentUser!.jenis_kelamin!.toLowerCase();
      if (userGender == 'l' || userGender == 'laki-laki') {
        honorific = 'gantengku';
      } else if (userGender == 'p' || userGender == 'perempuan') {
        honorific = 'cantikku';
      }
    }

    // Menggabungkan sapaan
    if (honorific.isNotEmpty) {
      return '$greeting $honorific!';
    } else {
      // Jika gender tidak ada atau tidak dikenali, gunakan nama pengguna
      return '$greeting, ${_currentUser?.name ?? 'Pengguna'}!';
    }
  }

  // --- Fungsi untuk Filter Bulan ---
  Future<void> _selectMonthFilter(BuildContext context) async {
    final DateTime? pickedMonth = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary(context),
              onPrimary: AppColors.onPrimary(context),
              surface: AppColors.cardBackground(context),
              onSurface: AppColors.textDark(context),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: AppColors.cardBackground(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedMonth != null) {
      print(
        'Selected month for filter: ${DateFormat('MMMM yyyy').format(pickedMonth)}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filtering data for ${DateFormat('MMMM yyyy').format(pickedMonth)}',
          ),
          backgroundColor: AppColors.info(context),
        ),
      );
      // TODO: Implement actual data filtering based on the selected month
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.onPrimary(
                    context,
                  ), // Use onPrimary for contrast
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: TextStyle(
                          color: AppColors.textLight(context),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _location,
                        style: TextStyle(
                          color: AppColors.onPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: AppColors.onPrimary(context),
                    size: 24,
                  ),
                  onPressed: () {
                    // Handle notification button press
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary(context),
              AppColors.primary(context).withOpacity(0.8),
              AppColors.background(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.2, 1.0], // Adjust gradient stops
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100,
              ), // Adjusted padding to account for transparent AppBar
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32, // Slightly larger avatar
                          backgroundColor: AppColors.accent(
                            context,
                          ).withOpacity(0.2),
                          backgroundImage:
                              _currentUser?.profile_photo != null &&
                                      _currentUser!.profile_photo!.isNotEmpty
                                  ? NetworkImage(
                                    'https://appabsensi.mobileprojp.com/public/${_currentUser!.profile_photo!}',
                                  )
                                  : null,
                          child:
                              _currentUser?.profile_photo == null ||
                                      _currentUser!.profile_photo!.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    color: AppColors.accent(context),
                                    size: 35,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 24, // Larger greeting text
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary(context),
                                ),
                              ),
                              Text(
                                'Ready for a productive day?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textLight(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // More spacing
                  _buildMainActionCard(context, hasCheckedIn, hasCheckedOut),
                  const SizedBox(height: 30), // More spacing
                  _buildAttendanceSummary(context),
                  const SizedBox(height: 100), // Added bottom space
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RequestScreen()),
                    );
                    if (result == true) {
                      _fetchAttendanceData();
                      MainBottomNavigationBar.refreshAttendanceNotifier.value =
                          true;
                    }
                  },
                  icon: Icon(Icons.add_task, color: AppColors.primary(context)),
                  label: Text(
                    'Submit Request',
                    style: TextStyle(
                      color: AppColors.primary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold, // Make text bolder
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onPrimary(
                      context,
                    ), // Changed to onPrimary for contrast
                    foregroundColor: AppColors.primary(context),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ), // Slightly larger padding
                    side: BorderSide(
                      color: AppColors.primary(context).withOpacity(0.5),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8, // Added elevation
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionCard(
    BuildContext context,
    bool hasCheckedIn,
    bool hasCheckedOut,
  ) {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        color: AppColors.cardBackground(context),
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
        ), // Increased horizontal margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ), // More rounded corners
        elevation: 10, // Increased elevation for a floating effect
        shadowColor: AppColors.primary(
          context,
        ).withOpacity(0.2), // Subtle shadow color
        child: Padding(
          padding: const EdgeInsets.all(25.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Text(
                      _currentTime,
                      style: TextStyle(
                        fontSize: 52, // Larger time font
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark(context),
                        letterSpacing: 1.5, // Added letter spacing
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentDate,
                    style: TextStyle(
                      fontSize: 18, // Larger date font
                      color: AppColors.textLight(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40), // More spacing

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isCheckingInOrOut
                          ? null
                          : (hasCheckedIn
                              ? (hasCheckedOut ? null : _handleCheckOut)
                              : _handleCheckIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasCheckedIn
                            ? (hasCheckedOut
                                ? AppColors.textLight(context).withOpacity(
                                  0.5,
                                ) // Less prominent when both checked in/out
                                : AppColors.error(context))
                            : AppColors.primary(context),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ), // Larger button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8, // Elevated button
                    shadowColor:
                        hasCheckedIn
                            ? AppColors.error(context).withOpacity(0.3)
                            : AppColors.primary(context).withOpacity(0.3),
                  ),
                  child:
                      _isCheckingInOrOut
                          ? const SizedBox(
                            width: 28, // Larger loading indicator
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3, // Thicker stroke
                            ),
                          )
                          : Text(
                            hasCheckedIn
                                ? (hasCheckedOut ? 'Checked Out' : 'Check Out')
                                : 'Check In',
                            style: TextStyle(
                              color: AppColors.onPrimary(context),
                              fontSize: 22, // Larger button text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 25), // More spacing
              Divider(
                color: AppColors.textLight(context).withOpacity(0.4),
                thickness: 1,
              ), // Thicker and softer divider
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeDetail(
                    context,
                    Icons.login, // Changed icon for Check In
                    _todayAbsence?.jamMasuk?.toLocal().toString().substring(
                          11,
                          19,
                        ) ??
                        '', // Empty string for N/A value
                    'Check In',
                    AppColors.primary(context),
                    _todayAbsence?.jamMasuk == null
                        ? AppColors.textLight(context).withOpacity(0.7)
                        : AppColors.textDark(context), // Conditional text color
                  ),
                  _buildTimeDetail(
                    context,
                    Icons.logout, // Changed icon for Check Out
                    _todayAbsence?.jamKeluar?.toLocal().toString().substring(
                          11,
                          19,
                        ) ??
                        '', // Empty string for N/A value
                    'Check Out',
                    AppColors.error(context),
                    _todayAbsence?.jamKeluar == null
                        ? AppColors.textLight(context).withOpacity(0.7)
                        : AppColors.textDark(context), // Conditional text color
                  ),
                  _buildTimeDetail(
                    context,
                    Icons.timer, // Changed icon for Working HR's
                    _calculateWorkingHours(),
                    'Working Hours', // Changed label for clarity
                    AppColors.warning(context),
                    _todayAbsence?.jamMasuk == null
                        ? AppColors.textLight(context).withOpacity(0.7)
                        : AppColors.textDark(context), // Conditional text color
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated _buildTimeDetail to handle "N/A" display and differentiate styles
  Widget _buildTimeDetail(
    BuildContext context,
    IconData icon,
    String timeValue, // Renamed to timeValue to avoid confusion
    String label,
    Color iconColor, // Renamed to iconColor
    Color textColor, // New parameter for text color
  ) {
    bool isNA =
        timeValue.isEmpty ||
        timeValue == 'N/A' ||
        timeValue == '00:00:00'; // Check if value is effectively N/A or zero
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30), // Slightly larger icons
        const SizedBox(height: 8), // More spacing
        Text(
          isNA ? 'N/A' : timeValue, // Display "N/A" if value is empty/zero
          style: TextStyle(
            fontSize: 17, // Slightly larger font
            fontWeight: FontWeight.bold,
            color:
                isNA
                    ? AppColors.textLight(context).withOpacity(0.7)
                    : textColor, // Use light color for N/A
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textLight(context),
          ), // Slightly larger label
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
          ), // Increased padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance for this Month',
                style: TextStyle(
                  fontSize: 20, // Larger title
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark(context),
                ),
              ),
              InkWell(
                onTap: () {
                  _selectMonthFilter(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, // Adjusted padding
                    vertical: 8, // Adjusted padding
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textLight(context).withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(30),
                    color: AppColors.cardBackground(
                      context,
                    ), // Added background color to filter button
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor(context).withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMM').format(DateTime.now()).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark(context),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textDark(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15), // More spacing
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
          ), // Increased padding
          child: Card(
            color: AppColors.cardBackground(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // More rounded corners
            ),
            elevation: 8, // Increased elevation
            shadowColor: AppColors.shadowColor(
              context,
            ).withOpacity(0.15), // Subtle shadow
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25.0, // Increased padding
                vertical: 20.0, // Increased padding
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    context,
                    'Present',
                    _absenceStats?.totalMasuk.toString() ??
                        '0', // Default to '0'
                  ),
                  const Divider(
                    height: 25,
                    thickness: 0.8,
                  ), // Divider between stats
                  _buildStatRow(
                    context,
                    'Absent',
                    _absenceStats?.totalAbsen.toString() ??
                        '0', // Default to '0'
                  ),
                  const Divider(
                    height: 25,
                    thickness: 0.8,
                  ), // Divider between stats
                  _buildStatRow(
                    context,
                    'Permission',
                    _absenceStats?.totalIzin.toString() ??
                        '0', // Default to '0'
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper for attendance stats rows
  Widget _buildStatRow(BuildContext context, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textDark(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

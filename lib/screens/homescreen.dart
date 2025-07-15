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
      _determinePosition(); // Refresh location as well
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _loadUserProfile() async {
    final ApiResponse<User> response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _currentUser = response.data;
      });
    } else {
      // Don't invoke 'print' in production code. Use a logging framework.
      print('Failed to load user profile: ${response.message}');
      setState(() {
        _currentUser = null;
      });
      if (mounted) {
        // _showErrorDialog('Failed to load user profile: ${response.message}'); // Komen ini jika tidak ingin menampilkan dialog error pada kegagalan load profil
      }
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      // Menyesuaikan format tanggal dan waktu untuk tampilan yang lebih rapi
      _currentDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
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
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Membuat alamat lebih ringkas dan relevan
          _location = [
                place.thoroughfare, // Nama jalan/gang
                place.subLocality, // Kelurahan/desa
                place.locality, // Kota/Kabupaten
                place.administrativeArea, // Provinsi
              ]
              .where((element) => element != null && element.isNotEmpty)
              .join(', ');

          if (_location.isEmpty) {
            _location = 'Unknown address';
          }
        });
      } else {
        setState(() {
          _location = 'Address not found';
        });
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      setState(() {
        _location = 'Address not found';
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
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get attendance data: ${todayAbsenceResponse.message}')));
      }
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
      return '00:00:00';
    }

    final DateTime checkInDateTime = _todayAbsence!.jamMasuk!;
    DateTime endDateTime;

    if (_todayAbsence!.jamKeluar != null) {
      endDateTime = _todayAbsence!.jamKeluar!;
    } else {
      endDateTime = DateTime.now();
    }

    if (endDateTime.isBefore(checkInDateTime)) {
      return '00:00:00';
    }

    final Duration duration = endDateTime.difference(checkInDateTime);

    final int hours = duration.inHours.abs();
    final int minutes = duration.inMinutes.remainder(60).abs();
    final int seconds = duration.inSeconds.remainder(60).abs();

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting = '';
    String honorific = '';

    if (hour >= 5 && hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Selamat Siang';
    } else if (hour >= 18 && hour < 22) {
      greeting = 'Selamat Malam';
    } else {
      greeting = 'Selamat Tidur';
    }

    if (_currentUser?.jenis_kelamin != null) {
      final userGender = _currentUser!.jenis_kelamin!.toLowerCase();
      if (userGender == 'l' || userGender == 'laki-laki') {
        honorific = 'gantengku';
      } else if (userGender == 'p' || userGender == 'perempuan') {
        honorific = 'cantikku';
      }
    }

    if (honorific.isNotEmpty) {
      return '$greeting $honorific!';
    } else {
      return '$greeting, ${_currentUser?.name ?? 'Pengguna'}!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary(context),
                AppColors.primary(context).withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
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
                    color: AppColors.onPrimary(context),
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
                            color: AppColors.onPrimary(
                              context,
                            ).withOpacity(0.8), // Slightly dimmed white
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _location,
                          style: TextStyle(
                            color: AppColors.onPrimary(
                              context,
                            ), // White for location text
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow:
                              TextOverflow.ellipsis, // Tetap gunakan ellipsis
                          maxLines: 2, // Mengizinkan 2 baris untuk alamat
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            stops: const [0.0, 0.2, 1.0],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100, // Memberi ruang untuk AppBar
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
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
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary(context),
                                ),
                              ),
                              Text(
                                'Ready for a productive day?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDark(
                                    context,
                                  ), // Ini harusnya AppColors.textLight(context) jika di gradient atas
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildMainActionCard(context, hasCheckedIn, hasCheckedOut),
                  const SizedBox(
                    height: 100,
                  ), // Memberi ruang di bawah kartu utama
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onPrimary(context),
                    foregroundColor: AppColors.primary(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // Hapus atau ubah border agar tidak ada warna di bawah submit request
                    // side: BorderSide(
                    //   color: AppColors.primary(context).withOpacity(0.5),
                    //   width: 1,
                    // ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        shadowColor: AppColors.primary(context).withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
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
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark(context),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentDate,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textLight(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

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
                                ? AppColors.textLight(context).withOpacity(0.5)
                                : AppColors.error(context))
                            : AppColors.primary(context),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor:
                        hasCheckedIn
                            ? AppColors.error(context).withOpacity(0.3)
                            : AppColors.primary(context).withOpacity(0.3),
                  ),
                  child:
                      _isCheckingInOrOut
                          ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : Text(
                            hasCheckedIn
                                ? (hasCheckedOut
                                    ? 'Checked Out for Today'
                                    : 'Check Out')
                                : 'Check In',
                            style: TextStyle(
                              color: AppColors.onPrimary(context),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 25),
              Divider(
                color: AppColors.textLight(context).withOpacity(0.4),
                thickness: 1,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeDetail(
                    context,
                    Icons.login,
                    _todayAbsence?.jamMasuk != null
                        ? DateFormat(
                          'HH:mm:ss',
                        ).format(_todayAbsence!.jamMasuk!.toLocal())
                        : '',
                    'Check In',
                    AppColors.primary(context),
                    _todayAbsence?.jamMasuk == null
                        ? AppColors.textLight(context).withOpacity(0.7)
                        : AppColors.textDark(context),
                  ),
                  _buildTimeDetail(
                    context,
                    Icons.logout,
                    _todayAbsence?.jamKeluar != null
                        ? DateFormat(
                          'HH:mm:ss',
                        ).format(_todayAbsence!.jamKeluar!.toLocal())
                        : '',
                    'Check Out',
                    AppColors.error(context),
                    _todayAbsence?.jamKeluar == null
                        ? AppColors.textLight(context).withOpacity(0.7)
                        : AppColors.textDark(context),
                  ),
                  _buildTimeDetail(
                    context,
                    Icons.timer,
                    _calculateWorkingHours(),
                    'Working Hours',
                    AppColors.warning(context),
                    _todayAbsence?.jamMasuk == null
                        ? AppColors.textLight(context).withOpacity(0.7)
                        : AppColors.textDark(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDetail(
    BuildContext context,
    IconData icon,
    String timeValue,
    String label,
    Color iconColor,
    Color textColor,
  ) {
    bool isNA =
        timeValue.isEmpty || timeValue == 'N/A' || timeValue == '00:00:00';
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 8),
        Text(
          isNA ? 'N/A' : timeValue,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color:
                isNA
                    ? AppColors.textLight(context).withOpacity(0.7)
                    : textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.textLight(context)),
        ),
      ],
    );
  }
}

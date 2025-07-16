// Copyright 2024 Your Company Name. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart'; // Import AutoSizeText
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/models/app_models.dart';
import 'package:presiva/screens/attendance/request_screen.dart';
import 'package:presiva/screens/main_botom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;
  const HomeScreen({super.key, required this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String _location = 'Mendapatkan Lokasi...';
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
      print('Failed to load user profile: ${response.message}');
      setState(() {
        _currentUser = null;
      });
      // if (mounted) {
      //   _showErrorDialog('Failed to load user profile: ${response.message}');
      // }
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
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
        _showErrorDialog('Layanan lokasi dinonaktifkan. Mohon aktifkan.');
      }
      setState(() {
        _location = 'Layanan lokasi dinonaktifkan';
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
            'Izin lokasi ditolak. Mohon berikan izin di pengaturan.',
          );
        }
        setState(() {
          _location = 'Izin lokasi ditolak';
          _permissionGranted = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showErrorDialog(
          'Izin lokasi ditolak secara permanen, kami tidak dapat meminta izin.',
        );
      }
      setState(() {
        _location = 'Izin lokasi ditolak secara permanen';
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
        _showErrorDialog('Gagal mendapatkan lokasi saat ini: $e');
      }
      setState(() {
        _location = 'Gagal mendapatkan lokasi';
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
          _location = [
                place.thoroughfare,
                place.subLocality,
                place.locality,
                place.administrativeArea,
              ]
              .where((element) => element != null && element.isNotEmpty)
              .join(', ');

          if (_location.isEmpty) {
            _location = 'Alamat tidak ditemukan';
          }
        });
      } else {
        setState(() {
          _location = 'Alamat tidak ditemukan';
        });
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      setState(() {
        _location = 'Alamat tidak ditemukan';
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
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get attendance data: ${todayAbsenceResponse.message}')));
      // }
    }
  }

  Future<void> _handleCheckIn() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Lokasi tidak tersedia. Pastikan layanan lokasi diaktifkan dan izin diberikan.',
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
          _showErrorDialog('Masuk gagal: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Terjadi kesalahan saat check-in: $e');
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
        'Lokasi tidak tersedia. Pastikan layanan lokasi diaktifkan dan izin diberikan.',
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
          _showErrorDialog('Keluar gagal: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Terjadi kesalahan saat check-out: $e');
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
            backgroundColor: AppColors.background,
            title: Text(
              'Kesalahan',
              style: TextStyle(color: AppColors.textDark),
            ),
            content: Text(message, style: TextStyle(color: AppColors.textDark)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: AppColors.primary)),
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
      greeting = 'Selamat pagi,';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Selamat siang,';
    } else if (hour >= 18 && hour < 22) {
      greeting = 'Selamat malam,';
    } else {
      greeting = 'tidur nyenyak,';
    }

    if (_currentUser?.jenis_kelamin != null) {
      final userGender = _currentUser!.jenis_kelamin!.toLowerCase();
      if (userGender == 'l' || userGender == 'laki-laki') {
        honorific = 'ganteng!';
      } else if (userGender == 'p' || userGender == 'perempuan') {
        honorific = 'cantik!';
      }
    }

    String name = _currentUser?.name ?? 'Pengguna';
    List<String> nameParts = name.split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';

    if (honorific.isNotEmpty) {
      return '$greeting $firstName $honorific';
    } else {
      return '$greeting $firstName!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;
    const double bottomButtonAreaHeight = 92.0;
    // Tambahkan tinggi untuk copyright text
    const double copyrightTextHeight = 40.0;

    const double customHeaderHeight = 120.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: customHeaderHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius:
                                  28, // Ukuran avatar juga dikecilkan sedikit
                              backgroundColor: AppColors.accent.withOpacity(
                                0.2,
                              ),
                              backgroundImage:
                                  _currentUser?.profile_photo != null &&
                                          _currentUser!
                                              .profile_photo!
                                              .isNotEmpty
                                      ? NetworkImage(
                                        'https://appabsensi.mobileprojp.com/public/${_currentUser!.profile_photo!}',
                                      )
                                      : null,
                              child:
                                  _currentUser?.profile_photo == null ||
                                          _currentUser!.profile_photo!.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        color: AppColors.accent,
                                        size: 30, // Ukuran ikon juga dikecilkan
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      fontSize:
                                          18, // Ukuran font greeting juga dikecilkan
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Siap untuk hari yang produktif?',
                                    style: TextStyle(
                                      fontSize:
                                          14, // Ukuran font tagline juga dikecilkan
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
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

          // Main Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              // Sesuaikan padding atas karena header lebih kecil
              padding: EdgeInsets.only(
                top: customHeaderHeight + 20.0, // Padding atas disesuaikan
                // Menambahkan copyrightTextHeight ke bottom padding
                bottom: bottomButtonAreaHeight + copyrightTextHeight + 20.0,
              ),
              child: Column(
                children: [
                  _buildMainActionCard(context, hasCheckedIn, hasCheckedOut),

                  const SizedBox(height: 20.0), // Spasi yang ditambahkan
                ],
              ),
            ),
          ),

          // Bottom Button Area
          Positioned(
            bottom:
                copyrightTextHeight -
                10, // Sesuaikan posisi agar tidak menumpuk
            left: 0,
            right: 0,
            child: Container(
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
                icon: Icon(Icons.add_task, color: AppColors.primary),
                label: Text(
                  'Izin',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onPrimary,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          ),
          // Copyright text di paling bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '© ${DateTime.now().year} Presiva. All rights reserved.',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
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
        color: AppColors.cardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        shadowColor: AppColors.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lokasi dipindahkan ke sini
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: AutoSizeText(
                        _location,
                        maxLines: 3,
                        minFontSize: 12,
                        maxFontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                        color: AppColors.textDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentDate,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textLight,
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
                                ? AppColors.textLight.withOpacity(0.5)
                                : AppColors.error)
                            : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor:
                        hasCheckedIn
                            ? AppColors.error.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
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
                                    ? 'Telah keluar untuk hari ini'
                                    : 'Keluar')
                                : 'Masuk',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 25),
              Divider(
                color: AppColors.textLight.withOpacity(0.4),
                thickness: 1,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeDetail(
                    Icons.login,
                    _todayAbsence?.jamMasuk != null
                        ? DateFormat(
                          'HH:mm:ss',
                        ).format(_todayAbsence!.jamMasuk!.toLocal())
                        : '',
                    'Masuk',
                    AppColors.primary,
                    _todayAbsence?.jamMasuk == null
                        ? AppColors.textLight.withOpacity(0.7)
                        : AppColors.textDark,
                  ),
                  _buildTimeDetail(
                    Icons.logout,
                    _todayAbsence?.jamKeluar != null
                        ? DateFormat(
                          'HH:mm:ss',
                        ).format(_todayAbsence!.jamKeluar!.toLocal())
                        : '',
                    'Keluar',
                    AppColors.error,
                    _todayAbsence?.jamKeluar == null
                        ? AppColors.textLight.withOpacity(0.7)
                        : AppColors.textDark,
                  ),
                  _buildTimeDetail(
                    Icons.timer,
                    _calculateWorkingHours(),
                    'Jam Kerja',
                    AppColors.warning,
                    _todayAbsence?.jamMasuk == null
                        ? AppColors.textLight.withOpacity(0.7)
                        : AppColors.textDark,
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
    IconData icon,
    String timeValue,
    String label,
    Color iconColor,
    Color textColor,
  ) {
    bool isNA =
        timeValue.isEmpty || timeValue == '---' || timeValue == '00:00:00';
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 8),
        Text(
          isNA ? '---' : timeValue,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isNA ? AppColors.textLight.withOpacity(0.7) : textColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textLight)),
      ],
    );
  }
}

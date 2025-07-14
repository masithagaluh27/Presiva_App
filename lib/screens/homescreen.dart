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

// Enum LocationType dihilangkan karena tidak lagi digunakan

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
      _currentDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
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
      Placemark place = placemarks[0];
      setState(() {
        _location = "${place.street}, ${place.subLocality}, ${place.locality}";
      });
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
            backgroundColor: AppColors.background(
              context,
            ), // <<< Perubahan di sini
            title: Text(
              'Error',
              style: TextStyle(color: AppColors.textDark(context)),
            ), // <<< Perubahan di sini
            content: Text(
              message,
              style: TextStyle(color: AppColors.textDark(context)),
            ), // <<< Perubahan di sini
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.primary(context),
                  ), // <<< Perubahan di sini
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

    final Duration duration = endDateTime.difference(checkInDateTime);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

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
      if (userGender == 'L' || userGender == 'laki-laki') {
        honorific = 'gantengku';
      } else if (userGender == 'P' || userGender == 'perempuan') {
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
              primary: AppColors.primary(context), // <<< Perubahan di sini
              onPrimary: AppColors.onPrimary(context), // <<< Perubahan di sini
              surface: AppColors.cardBackground(
                context,
              ), // <<< Perubahan di sini
              onSurface: AppColors.textDark(context), // <<< Perubahan di sini
            ),
            dialogTheme: DialogTheme(
              // Ubah DialogThemeData menjadi DialogTheme
              backgroundColor: AppColors.cardBackground(
                context,
              ), // <<< Perubahan di sini
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
          backgroundColor: AppColors.info(context), // <<< Perubahan di sini
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

    return Scaffold(
      backgroundColor: AppColors.background(context), // <<< Perubahan di sini
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary(context), // <<< Perubahan di sini
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
                  color: AppColors.textLight(context),
                  size: 24,
                ), // <<< Perubahan di sini
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
                        ), // <<< Perubahan di sini
                      ),
                      Text(
                        _location,
                        style: TextStyle(
                          // Ubah const TextStyle menjadi TextStyle biasa
                          color: AppColors.onPrimary(
                            context,
                          ), // Menggunakan onPrimary untuk teks di atas primary
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
                    color: AppColors.onPrimary(
                      context,
                    ), // Menggunakan onPrimary untuk ikon notifikasi
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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                // Ubah const BoxDecoration menjadi BoxDecoration biasa
                color: AppColors.primary(context), // <<< Perubahan di sini
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent(
                          context,
                        ).withOpacity(0.2), // <<< Perubahan di sini
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
                                  color: AppColors.accent(
                                    context,
                                  ), // <<< Perubahan di sini
                                  size: 30,
                                )
                                : null,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              // Ubah const TextStyle menjadi TextStyle biasa
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary(
                                context,
                              ), // Menggunakan onPrimary karena di atas primary
                            ),
                          ),
                          Text(
                            'Ready for a productive day?',
                            style: TextStyle(
                              // Ubah const TextStyle menjadi TextStyle biasa
                              fontSize: 14,
                              color: AppColors.textLight(
                                context,
                              ), // <<< Perubahan di sini
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildMainActionCard(
                  context,
                  hasCheckedIn,
                  hasCheckedOut,
                ), // <<< Lewatkan context
                const SizedBox(height: 20),
                _buildAttendanceSummary(context), // <<< Lewatkan context
                const SizedBox(height: 100),
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
                icon: Icon(
                  Icons.add_task,
                  color: AppColors.primary(context),
                ), // <<< Perubahan di sini
                label: Text(
                  'Submit Request',
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontSize: 18,
                  ), // <<< Perubahan di sini
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background(
                    context,
                  ), // <<< Perubahan di sini
                  foregroundColor: AppColors.primary(
                    context,
                  ), // <<< Perubahan di sini
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: AppColors.primary(
                      context,
                    ).withOpacity(0.5), // <<< Perubahan di sini
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
    // Tambahkan context
    return Card(
      color: AppColors.cardBackground(context), // <<< Perubahan di sini
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label GENERAL SHIFT dipindahkan ke paling atas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success(
                  context,
                ).withOpacity(0.1), // <<< Perubahan di sini
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'GENERAL SHIFT',
                style: TextStyle(
                  // Ubah const TextStyle menjadi TextStyle biasa
                  color: AppColors.success(context), // <<< Perubahan di sini
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Informasi tanggal dan jam
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _currentTime,
                  style: TextStyle(
                    // Ubah const TextStyle menjadi TextStyle biasa
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark(context), // <<< Perubahan di sini
                  ),
                ),
                Text(
                  _currentDate,
                  style: TextStyle(
                    // Ubah const TextStyle menjadi TextStyle biasa
                    fontSize: 16,
                    color: AppColors.textLight(
                      context,
                    ), // <<< Perubahan di sini
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Tombol Check In dan Check Out (lonjong dan memanjang)
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
                              ? AppColors.textLight(
                                context,
                              ) // <<< Perubahan di sini
                              : AppColors.error(
                                context,
                              )) // <<< Perubahan di sini
                          : AppColors.primary(context), // <<< Perubahan di sini
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child:
                    _isCheckingInOrOut
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color:
                                Colors
                                    .white, // Ini bisa tetap putih atau AppColors.onPrimary(context)
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          hasCheckedIn
                              ? (hasCheckedOut ? 'Checked Out' : 'Check Out')
                              : 'Check In',
                          style: TextStyle(
                            // Ubah const TextStyle menjadi TextStyle biasa
                            color: AppColors.onPrimary(
                              context,
                            ), // Menggunakan onPrimary untuk teks tombol
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: AppColors.textLight(context),
            ), // <<< Perubahan di sini
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeDetail(
                  context, // <<< Lewatkan context
                  Icons.watch_later_outlined,
                  _todayAbsence?.jamMasuk?.toLocal().toString().substring(
                        11,
                        19,
                      ) ??
                      'N/A',
                  'Check In',
                  AppColors.primary(context), // <<< Perubahan di sini
                ),
                _buildTimeDetail(
                  context, // <<< Lewatkan context
                  Icons.watch_later_outlined,
                  _todayAbsence?.jamKeluar?.toLocal().toString().substring(
                        11,
                        19,
                      ) ??
                      'N/A',
                  'Check Out',
                  AppColors.error(context), // <<< Perubahan di sini
                ),
                _buildTimeDetail(
                  context, // <<< Lewatkan context
                  Icons.watch_later_outlined,
                  _calculateWorkingHours(),
                  'Working HR\'s',
                  AppColors.warning(context), // <<< Perubahan di sini
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDetail(
    BuildContext context, // Tambahkan context di sini
    IconData icon,
    String time,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(
          time,
          style: TextStyle(
            // Ubah const TextStyle menjadi TextStyle biasa
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark(context), // <<< Perubahan di sini
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight(context),
          ), // <<< Perubahan di sini
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary(BuildContext context) {
    // Tambahkan context
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance for this Month',
                style: TextStyle(
                  // Ubah const TextStyle menjadi TextStyle biasa
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark(context), // <<< Perubahan di sini
                ),
              ),
              InkWell(
                onTap: () {
                  _selectMonthFilter(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textLight(
                        context,
                      ).withOpacity(0.5), // <<< Perubahan di sini
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMM').format(DateTime.now()).toUpperCase(),
                        style: TextStyle(
                          // Ubah const TextStyle menjadi TextStyle biasa
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark(
                            context,
                          ), // <<< Perubahan di sini
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textDark(
                          context,
                        ), // <<< Perubahan di sini
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildAttendanceStatsCard(context), // <<< Lewatkan context
        ),
      ],
    );
  }

  Widget _buildAttendanceStatsCard(BuildContext context) {
    // Tambahkan context
    return Card(
      color: AppColors.cardBackground(context), // <<< Perubahan di sini
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context, // <<< Lewatkan context
                  'Total Hadir',
                  _absenceStats?.totalMasuk.toString() ?? '0',
                  AppColors.primary(context), // <<< Perubahan di sini
                ),
                _buildStatItem(
                  context, // <<< Lewatkan context
                  'Total Izin',
                  _absenceStats?.totalIzin.toString() ?? '0',
                  AppColors.info(context), // <<< Perubahan di sini
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    // Tambahkan context
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textDark(context),
          ), // <<< Perubahan di sini
        ),
      ],
    );
  }
}

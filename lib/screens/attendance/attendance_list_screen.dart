import 'dart:async';
import 'package:presiva/constant/app_colors.dart'; // Pastikan path ini benar dan AppColors memiliki definisi warna yang kaya
import 'package:presiva/models/app_models.dart'; // Pastikan path ini benar
import 'package:presiva/screens/main_botom_navigation_bar.dart'; // Untuk notifikasi refresh
import 'package:presiva/services/api_Services.dart'; // Pastikan path ini benar
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const AttendanceListScreen({super.key, required this.refreshNotifier});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Absence>> _attendanceFuture;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _fetchAndFilterAttendances();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      print(
        'AttendanceListScreen: Refresh signal received, refreshing list...',
      );
      _refreshList();
      widget.refreshNotifier.value = false;
    }
  }

  Future<List<Absence>> _fetchAndFilterAttendances() async {
    final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
    final String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

    try {
      final ApiResponse<List<Absence>> response = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      if (response.statusCode == 200 && response.data != null) {
        final List<Absence> fetchedAbsences = response.data!;
        fetchedAbsences.sort((a, b) {
          if (a.attendanceDate == null && b.attendanceDate == null) return 0;
          if (a.attendanceDate == null) return 1;
          if (b.attendanceDate == null) return -1;
          return b.attendanceDate!.compareTo(a.attendanceDate!);
        });
        return fetchedAbsences;
      } else {
        // Handle API specific errors or messages from response.message
        throw Exception(response.message);
      }
    } catch (e) {
      print('Error fetching and filtering attendance list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _attendanceFuture = _fetchAndFilterAttendances();
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateTime newSelectedMonth = DateTime(picked.year, picked.month, 1);
      if (newSelectedMonth.year != _selectedMonth.year ||
          newSelectedMonth.month != _selectedMonth.month) {
        setState(() {
          _selectedMonth = newSelectedMonth;
        });
        _refreshList();
      }
    }
  }

  String _calculateWorkingHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) {
      return '00:00:00';
    }

    DateTime endDateTime = checkOut ?? DateTime.now();
    if (endDateTime.isBefore(checkIn)) {
      return '00:00:00'; // Prevent negative duration if checkout is before checkin
    }

    final Duration duration = endDateTime.difference(checkIn);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAttendanceTile(Absence absence) {
    Color barColor;
    Color statusPillColor;
    Color cardBackgroundColor;
    Color timeTextColor;
    IconData statusIcon;

    bool isRequestType =
        absence.status?.toLowerCase() == 'izin' ||
        absence.status?.toLowerCase() == 'cuti';

    if (isRequestType) {
      barColor = AppColors.warning;
      statusPillColor = AppColors.warning;
      cardBackgroundColor = AppColors.lightWarningBackground;
      timeTextColor = AppColors.textDark;
      statusIcon = Icons.info_outline; // Icon for "Izin" / "Cuti"
    } else {
      if (absence.status?.toLowerCase() == 'late') {
        barColor = AppColors.error;
        statusPillColor = AppColors.error;
        cardBackgroundColor = AppColors.lightDangerBackground;
        timeTextColor = AppColors.error;
        statusIcon = Icons.hourglass_empty; // Icon for "Late"
      } else {
        barColor = AppColors.success;
        statusPillColor = AppColors.success;
        cardBackgroundColor = AppColors.lightSuccessBackground;
        timeTextColor = AppColors.success;
        statusIcon = Icons.check_circle_outline; // Icon for "Masuk" / "Hadir"
      }
    }

    final DateTime? displayDate = absence.attendanceDate;
    final String formattedDate =
        displayDate != null
            ? DateFormat('E, MMM d, yyyy').format(displayDate)
            : 'N/A';

    return Card(
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 6, // Slightly increased elevation for more depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ), // More rounded corners
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8.0, // Thicker left bar
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17, // Slightly larger font
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isRequestType
                                    ? statusPillColor
                                    : statusPillColor.withOpacity(
                                      0.15,
                                    ), // More subtle for non-requests
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Pill shape
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 18,
                                color:
                                    isRequestType
                                        ? Colors.white
                                        : statusPillColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                absence.status?.toUpperCase() ?? 'N/A',
                                style: TextStyle(
                                  color:
                                      isRequestType
                                          ? Colors.white
                                          : AppColors
                                              .textDark, // Keep text dark for subtle background
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // More space
                    if (!isRequestType)
                      Column(
                        // Use Column for vertical alignment of location/address
                        children: [
                          _buildTimeAndLocationRow(
                            Icons.login, // Icon for Check In
                            'Check In',
                            absence.checkIn?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                'N/A',
                            absence.checkInAddress ?? 'N/A',
                            timeTextColor,
                          ),
                          const SizedBox(height: 10), // Space between in/out
                          _buildTimeAndLocationRow(
                            Icons.logout, // Icon for Check Out
                            'Check Out',
                            absence.checkOut?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                'N/A',
                            absence.checkOutAddress ?? 'N/A',
                            timeTextColor,
                          ),
                          const SizedBox(height: 10),
                          _buildTimeAndLocationRow(
                            Icons.timer, // Icon for Working Hours
                            'Working HR\'s',
                            _calculateWorkingHours(
                              absence.checkIn,
                              absence.checkOut,
                            ),
                            '', // No address for working hours
                            timeTextColor,
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                        ), // Consistent padding
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description,
                              color: AppColors.textLight.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reason: ${absence.alasanIzin?.isNotEmpty == true ? absence.alasanIzin : 'N/A'}',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                  height:
                                      1.4, // Line height for better readability
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Tombol Delete/Cancel
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded, // Slightly different close icon
                  color: AppColors.textLight.withOpacity(0.7),
                  size: 24, // Slightly larger icon
                ),
                onPressed: () async {
                  if (absence.status?.toLowerCase() != 'izin' &&
                      absence.status?.toLowerCase() != 'cuti') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Only "Izin" or "Cuti" entries can be deleted.',
                        ),
                        backgroundColor: AppColors.error, // Make it noticeable
                      ),
                    );
                    return;
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Text(
                            'Cancel Entry',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            'Are you sure you want to cancel this entry? This action cannot be undone.',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text('No'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                  );

                  if (confirmed == true) {
                    try {
                      if (absence.id == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot delete: Invalid Absence ID.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      final ApiResponse<Absence> deleteResponse =
                          await _apiService.deleteAbsence(absence.id);

                      if (deleteResponse.statusCode == 200) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(deleteResponse.message),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        await _refreshList();
                        MainBottomNavigationBar.refreshHomeNotifier.value =
                            true;
                      } else {
                        String errorMessage = deleteResponse.message;
                        if (deleteResponse.errors != null) {
                          deleteResponse.errors!.forEach((key, value) {
                            errorMessage +=
                                '\n$key: ${(value as List).join(', ')}';
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to cancel entry: $errorMessage',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'An error occurred during cancellation: $e',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndLocationRow(
    IconData icon,
    String label,
    String time,
    String? address,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textLight.withOpacity(0.7), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $time',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600, // Semi-bold
                  fontSize: 15,
                ),
              ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Attendance Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ], // Example gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: const BoxDecoration(
              color:
                  AppColors
                      .cardBackground, // A lighter background for the header section
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Overview', // Lebih deskriptif
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(
                      0.1,
                    ), // Subtle background for month selector
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                              1,
                            );
                          });
                          _refreshList();
                        },
                      ),
                      GestureDetector(
                        onTap: () => _selectMonth(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            DateFormat('MMM yyyy')
                                .format(_selectedMonth)
                                .toUpperCase(), // Show year as well
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                              1,
                            );
                          });
                          _refreshList();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshList,
              color: AppColors.primary,
              child: FutureBuilder<List<Absence>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 4, // More prominent spinner
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Oops! Something went wrong: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshList,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final attendances = snapshot.data ?? [];

                  if (attendances.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/no_data.png', // Tambahkan ilustrasi ini di folder assets Anda
                              height: 150,
                              width: 150,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No attendance records found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Time to make some new memories!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceTile(attendances[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

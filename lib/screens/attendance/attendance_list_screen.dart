import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart'; // Pastikan AppColors Anda mendukung tema
import 'package:presiva/models/app_models.dart';
import 'package:presiva/services/api_Services.dart';
// import 'package:presiva/screens/main_botom_navigation_bar.dart'; // Jika tidak digunakan, bisa dihapus

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
          data: Theme.of(context).copyWith(
            // Gunakan tema aplikasi saat ini
            colorScheme: ColorScheme.light(
              primary: AppColors.primary(context),
              onPrimary: Colors.white,
              onSurface: AppColors.textDark(context),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary(context),
              ),
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
    Color statusPillBackgroundColor;
    Color statusPillTextColor;
    Color cardBackgroundColor;
    Color timeTextColor;
    IconData statusIcon;

    bool isRequestType =
        absence.status?.toLowerCase() == 'izin' ||
        absence.status?.toLowerCase() == 'cuti';

    if (isRequestType) {
      barColor = AppColors.warning(context);
      statusPillBackgroundColor = AppColors.warning(context);
      statusPillTextColor = Colors.white;
      cardBackgroundColor = AppColors.lightWarningBackground(context);
      timeTextColor = AppColors.textDark(context);
      statusIcon = Icons.info_outline; // Icon for "Izin" / "Cuti"
    } else {
      if (absence.status?.toLowerCase() == 'late') {
        barColor = AppColors.error(context);
        statusPillBackgroundColor = AppColors.error(context);
        statusPillTextColor = Colors.white;
        cardBackgroundColor = AppColors.lightDangerBackground(context);
        timeTextColor = AppColors.error(context);
        statusIcon = Icons.hourglass_empty; // Icon for "Late"
      } else {
        barColor = AppColors.success(context);
        statusPillBackgroundColor = AppColors.success(context);
        statusPillTextColor = Colors.white;
        cardBackgroundColor = AppColors.lightSuccessBackground(context);
        timeTextColor = AppColors.success(context);
        statusIcon = Icons.check_circle_outline; // Icon for "Masuk" / "Hadir"
      }
    }

    final DateTime? displayDate = absence.attendanceDate;
    final String formattedDate =
        displayDate != null
            ? DateFormat('EEEE, MMM d, yyyy').format(
              displayDate,
            ) // Full day name
            : 'N/A';

    return Card(
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4, // Moderate elevation for a modern look
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left bar for status color
            Container(
              width: 6.0,
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark(context),
                          ),
                        ),
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusPillBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 16,
                                color: statusPillTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                absence.status?.toUpperCase() ?? 'N/A',
                                style: TextStyle(
                                  color: statusPillTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Check-in, Check-out, Working Hours (if not a request type)
                    if (!isRequestType)
                      Column(
                        children: [
                          _buildTimeAndLocationRow(
                            context,
                            Icons.login_rounded, // Modern check-in icon
                            'Check In',
                            absence.checkIn?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                'N/A',
                            absence.checkInAddress ?? 'N/A',
                            timeTextColor,
                          ),
                          const SizedBox(height: 8),
                          _buildTimeAndLocationRow(
                            context,
                            Icons.logout_rounded, // Modern check-out icon
                            'Check Out',
                            absence.checkOut?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                'N/A',
                            absence.checkOutAddress ?? 'N/A',
                            timeTextColor,
                          ),
                          const SizedBox(height: 8),
                          _buildTimeAndLocationRow(
                            context,
                            Icons.timer_outlined, // Modern timer icon
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
                    else // Reason for "Izin" / "Cuti"
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons
                                  .description_outlined, // Modern description icon
                              color: AppColors.textLight(
                                context,
                              ).withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reason: ${absence.alasanIzin?.isNotEmpty == true ? absence.alasanIzin : 'N/A'}',
                                style: TextStyle(
                                  color: AppColors.textLight(context),
                                  fontSize: 14,
                                  height: 1.4,
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
            // Delete/Cancel button aligned to top right
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.cancel_outlined, // A clear cancel icon
                  color: AppColors.textLight(context).withOpacity(0.6),
                  size: 24,
                ),
                onPressed: () async {
                  if (absence.status?.toLowerCase() != 'izin' &&
                      absence.status?.toLowerCase() != 'cuti') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Only "Izin" or "Cuti" entries can be deleted.',
                        ),
                        backgroundColor: AppColors.error(context),
                      ),
                    );
                    return;
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.cardBackground(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            'Cancel Entry',
                            style: TextStyle(
                              color: AppColors.textDark(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to cancel this entry? This action cannot be undone.',
                            style: TextStyle(
                              color: AppColors.textLight(context),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary(context),
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
                                backgroundColor: AppColors.error(context),
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
                          SnackBar(
                            content: const Text(
                              'Cannot delete: Invalid Absence ID.',
                            ),
                            backgroundColor: AppColors.error(context),
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
                            backgroundColor: AppColors.success(context),
                          ),
                        );
                        await _refreshList();
                        // uncomment baris di bawah jika MainBottomNavigationBar.refreshHomeNotifier diperlukan
                        // MainBottomNavigationBar.refreshHomeNotifier.value = true;
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
                              backgroundColor: AppColors.error(context),
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
                            backgroundColor: AppColors.error(context),
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
    BuildContext context,
    IconData icon,
    String label,
    String time,
    String? address,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.textLight(context).withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $time',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    color: AppColors.textLight(context).withOpacity(0.8),
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
    // Determine if the current theme is dark or light
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Attendance Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color:
                isDarkMode
                    ? Colors.white
                    : Colors.white, // Text color on gradient app bar
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary(context),
                AppColors.secondary(context),
              ],
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
          // Monthly Overview Section - Modernized
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(
                context,
              ), // Use card background for this section
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ), // More rounded
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor(context),
                  blurRadius: 10, // Increased blur
                  offset: const Offset(0, 5), // More prominent shadow
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark(context),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectMonth(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Slightly less rounded for a sleek button
                            border: Border.all(
                              color: AppColors.primary(
                                context,
                              ).withOpacity(0.3),
                            ), // Subtle border
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppColors.primary(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'MMMM yyyy',
                                ).format(_selectedMonth), // Full month name
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary(context),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary(context).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons
                                  .chevron_left_rounded, // More modern arrow icon
                              size: 24,
                              color: AppColors.primary(context),
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
                          IconButton(
                            icon: Icon(
                              Icons
                                  .chevron_right_rounded, // More modern arrow icon
                              size: 24,
                              color: AppColors.primary(context),
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
              ],
            ),
          ),
          const SizedBox(height: 16), // Space between monthly overview and list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshList,
              color: AppColors.primary(context),
              child: FutureBuilder<List<Absence>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary(context),
                        strokeWidth: 4,
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
                              Icons
                                  .cloud_off_outlined, // More modern error icon
                              color: AppColors.error(context),
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Oops! Something went wrong: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight(context),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshList,
                              icon: const Icon(
                                Icons.refresh_rounded,
                              ), // Modern refresh icon
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary(context),
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
                            // You can keep this image or replace it with an icon as well
                            Image.asset(
                              'assets/images/shaun.jpeg', // Make sure this asset exists
                              height: 150,
                              width: 150,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No attendance records found for this month.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight(context),
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ), // Padding for the last item
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

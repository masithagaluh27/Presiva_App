import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/models/app_models.dart';

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
    // Format tanggal awal bulan (_selectedMonth) ke 'YYYY-MM-01'
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
            colorScheme: ColorScheme.light(
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
      return '00:00:00';
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
      barColor = AppColors.warning;
      statusPillBackgroundColor = AppColors.warning;
      statusPillTextColor = Colors.white;
      cardBackgroundColor = AppColors.warningBackground;
      statusIcon = Icons.info_outline;
      timeTextColor = AppColors.textDark;
    } else {
      if (absence.status?.toLowerCase() == 'late') {
        barColor = AppColors.error;
        statusPillBackgroundColor = AppColors.error;
        statusPillTextColor = Colors.white;
        cardBackgroundColor = AppColors.dangerBackground;
        timeTextColor = AppColors.error;
        statusIcon = Icons.hourglass_empty;
      } else {
        barColor = AppColors.success;
        statusPillBackgroundColor = AppColors.success;
        statusPillTextColor = Colors.white;
        cardBackgroundColor = AppColors.successBackground;
        timeTextColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
      }
    }

    final DateTime? displayDate = absence.attendanceDate;

    // format tanggal
    final String formattedDate =
        displayDate != null
            ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(displayDate)
            : '---';

    return Card(
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Side bar warna (indikator status)
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
                    // Bagian tanggal dan status pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tanggal kehadiran
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),

                        // Pill status (contoh: "MASUK", "IZIN", "LATE")
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
                                absence.status?.toUpperCase() ?? '---',
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
                    // Detail Check In/Check Out
                    if (!isRequestType)
                      Column(
                        children: [
                          _buildTimeAndLocationRow(
                            context,
                            Icons.login_rounded,
                            'Check In',
                            absence.checkIn?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                '---',
                            absence.checkInAddress ?? '---',
                            timeTextColor,
                          ),
                          const SizedBox(height: 8),
                          _buildTimeAndLocationRow(
                            context,
                            Icons.logout_rounded,
                            'Check Out',
                            absence.checkOut?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                '---',
                            absence.checkOutAddress ?? '---',
                            timeTextColor,
                          ),
                          const SizedBox(height: 8),
                          _buildTimeAndLocationRow(
                            context,
                            Icons.timer_outlined,
                            'Working HR\'s',
                            _calculateWorkingHours(
                              absence.checkIn,
                              absence.checkOut,
                            ),
                            '', // Working HRs doesn't have an address
                            timeTextColor,
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: AppColors.textLight.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reason: ${absence.alasanIzin?.isNotEmpty == true ? absence.alasanIzin : '---'}',
                                style: TextStyle(
                                  color: AppColors.textLight,
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

            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: AppColors.textLight.withOpacity(0.6),
                  size: 24,
                ),
                onPressed: () async {
                  // Logika untuk  mengizinkan pembatalan 'Izin'
                  if (absence.status?.toLowerCase() != 'izin' &&
                      absence.status?.toLowerCase() != 'cuti') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Only "Izin" entries can be deleted.',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  // Konfirmasi dialog sebelum menghapus
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            'Cancel Entry',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
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
                          SnackBar(
                            content: const Text(
                              'Cannot delete: Invalid Absence ID.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      // Panggilan API untuk menghapus entri
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
                        await _refreshList(); // Perbarui daftar setelah penghapusan berhasil
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

  // Widget pembantu untuk menampilkan waktu dan lokasi (Check In/Check Out/Working HRs).
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
                  fontWeight: FontWeight.w600,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Attendance Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.5)],
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
          // Bagian "Monthly Overview" dan pemilih bulan
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul "Monthly Overview"
                Text(
                  'Monthly Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol untuk memilih bulan (tanggal)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectMonth(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              // Menampilkan bulan dan tahun yang sedang dipilih
                              Text(
                                DateFormat(
                                  'MMMM yyyy',
                                  'id_ID', // Format bulan dalam Bahasa Indonesia
                                ).format(_selectedMonth),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol panah untuk navigasi bulan (sebelumnya/selanjutnya)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              size: 24,
                              color: AppColors.primary,
                            ),
                            // Mengurangi bulan saat ini dan me-refresh daftar
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
                              Icons.chevron_right_rounded,
                              size: 24,
                              color: AppColors.primary,
                            ),
                            // Menambah bulan saat ini dan me-refresh daftar
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
          const SizedBox(height: 16),
          // Bagian daftar kehadiran yang di-scroll
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  _refreshList, // Fungsi untuk refresh saat ditarik ke bawah
              color: AppColors.primary,
              child: FutureBuilder<List<Absence>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
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
                              color: AppColors.error,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Oops! Terjadi kesalahan: ${snapshot.error}', // Translated
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshList,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'), // Translated
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
                            Icon(Icons.calendar_month),
                            const SizedBox(height: 20),
                            Text(
                              'Tidak ada catatan kehadiran yang ditemukan untuk bulan ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ListView builder untuk menampilkan setiap tile kehadiran
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceTile(attendances[index]);
                    },
                  );
                },
              ),
            ),
          ),

          Padding(
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
        ],
      ),
    );
  }
}

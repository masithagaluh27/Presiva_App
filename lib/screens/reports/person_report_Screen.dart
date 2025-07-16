import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart';
import 'package:presiva/models/app_models.dart'; // Pastikan path model Anda benar
import 'package:presiva/api/api_Services.dart'; // Pastikan path service Anda benar

class PersonReportScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier; // Gunakan tipe yang spesifik
  const PersonReportScreen({super.key, required this.refreshNotifier});

  @override
  State<PersonReportScreen> createState() => _PersonReportScreenState();
}

class _PersonReportScreenState extends State<PersonReportScreen> {
  final ApiService _apiService = ApiService();

  late Future<void> _reportDataFuture;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  int _presentCount = 0;
  int _absentCount = 0; // Untuk total 'Absen' (alpha / tanpa izin)
  int _permitCount = 0; // Untuk total 'Izin' (dengan izin)
  int _lateInCount = 0; // Dihitung lokal

  int _totalWorkingDaysInMonth = 0;
  String _totalWorkingHours = '0hr 0min';
  double _overallAttendancePercentage = 0.0;

  List<BarChartGroupData> _barChartGroupData = [];
  double _maxYValue = 10.0;

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchAndCalculateMonthlyReports();
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
        'PersonReportScreen: Refresh signal received, refreshing reports...',
      );
      setState(() {
        _reportDataFuture = _fetchAndCalculateMonthlyReports();
      });
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _fetchAndCalculateMonthlyReports() async {
    setState(() {
      _presentCount = 0;
      _absentCount = 0;
      _permitCount = 0;
      _lateInCount = 0;
      _totalWorkingDaysInMonth = 0;
      _totalWorkingHours = '0hr 0min';
      _overallAttendancePercentage = 0.0;
      _barChartGroupData = [];
      _maxYValue = 10.0;
    });

    try {
      final ApiResponse<AbsenceStats> statsResponse =
          await _apiService.getAbsenceStats();
      if (statsResponse.statusCode == 200 && statsResponse.data != null) {
        final AbsenceStats stats = statsResponse.data!;
        setState(() {
          _presentCount = stats.totalMasuk;
          _permitCount = stats.totalIzin;
          _absentCount = stats.totalAbsen;
        });
      } else {
        print('Failed to get absence stats: ${statsResponse.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load summary: ${statsResponse.message}'),
            ),
          );
        }
      }

      final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final String endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

      final ApiResponse<List<Absence>> historyResponse = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      Duration totalWorkingDuration = Duration.zero;
      int actualPresentCountFromHistory = 0;
      int actualAbsentCountFromHistory = 0;
      int actualPermitCountFromHistory = 0;
      int actualLateCountFromHistory = 0;

      int daysInMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
      _totalWorkingDaysInMonth = daysInMonth;

      if (historyResponse.statusCode == 200 && historyResponse.data != null) {
        for (var absence in historyResponse.data!) {
          if (absence.attendanceDate == null) {
            print('Skipping absence entry due to null attendanceDate.');
            continue;
          }

          final DateTime entryDate = absence.attendanceDate!;

          if (absence.status?.toLowerCase() == 'masuk') {
            actualPresentCountFromHistory++;
            if (absence.checkIn != null && absence.checkOut != null) {
              final checkInTime = absence.checkIn!;
              final checkOutTime = absence.checkOut!;
              if (checkOutTime.isAfter(checkInTime)) {
                totalWorkingDuration += checkOutTime.difference(checkInTime);
              }
            }
            if (absence.checkIn != null) {
              final officeStart = DateTime(
                entryDate.year,
                entryDate.month,
                entryDate.day,
                9,
                0,
                0,
              );
              if (absence.checkIn!.isAfter(officeStart)) {
                actualLateCountFromHistory++;
              }
            }
          } else if (absence.status?.toLowerCase() == 'izin') {
            actualPermitCountFromHistory++;
          } else if (absence.status?.toLowerCase() == 'absen') {
            actualAbsentCountFromHistory++;
          }
        }
      } else {
        print(
          'Failed to get absence history for working hours: ${historyResponse.message}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load working hours: ${historyResponse.message}',
              ),
            ),
          );
        }
      }

      final int totalHours = totalWorkingDuration.inHours;
      final int remainingMinutes = totalWorkingDuration.inMinutes.remainder(60);
      String formattedTotalWorkingHours =
          '${totalHours}hr ${remainingMinutes}min';

      double calculatedAttendancePercentage = 0.0;
      if (_totalWorkingDaysInMonth > 0) {
        calculatedAttendancePercentage =
            (actualPresentCountFromHistory / _totalWorkingDaysInMonth) * 100;
      }

      setState(() {
        _presentCount = actualPresentCountFromHistory;
        _absentCount = actualAbsentCountFromHistory;
        _permitCount = actualPermitCountFromHistory;
        _lateInCount = actualLateCountFromHistory;
        _totalWorkingHours = formattedTotalWorkingHours;
        _overallAttendancePercentage = calculatedAttendancePercentage;

        _updateBarChartData(
          _presentCount,
          _absentCount + _permitCount, // Gabungkan Absen dan Izin untuk chart
          _lateInCount,
        );
      });
    } catch (e) {
      print('Error fetching and calculating monthly reports: $e');
      _updateSummaryCounts(0, 0, 0, 0, 0, '0hr 0min', 0.0);
      _updateBarChartData(0, 0, 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred loading reports: $e')),
        );
      }
    }
  }

  void _updateSummaryCounts(
    int present,
    int absent,
    int permit,
    int late,
    int totalWorkingDays,
    String totalHrs,
    double attendancePercentage,
  ) {
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _permitCount = permit;
      _lateInCount = late;
      _totalWorkingDaysInMonth = totalWorkingDays;
      _totalWorkingHours = totalHrs;
      _overallAttendancePercentage = attendancePercentage;
    });
  }

  void _updateBarChartData(int present, int absentAndPermit, int late) {
    _maxYValue = [
      present.toDouble(),
      absentAndPermit.toDouble(),
      late.toDouble(),
      5.0,
    ].reduce((a, b) => a > b ? a : b);

    _maxYValue = (_maxYValue * 1.2).ceilToDouble();
    if (_maxYValue < 10) _maxYValue = 10;

    _barChartGroupData = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: present.toDouble(),
            color: AppColors.success, // Hapus `(context)`
            width: 25,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: absentAndPermit.toDouble(),
            color: AppColors.error, // Hapus `(context)`
            width: 25,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: late.toDouble(),
            color: AppColors.warning, // Hapus `(context)`
            width: 25,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    ];
  }

  Widget _buildStatListItem(
    BuildContext context,
    String title,
    dynamic value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground, // Hapus `(context)`
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor, // Hapus `(context)`
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.body2.copyWith(
                // Menggunakan AppTextStyles.body2
                fontWeight: FontWeight.w500,
                color: AppColors.textDark, // Hapus `(context)`
              ),
            ),
            Text(
              value.toString(),
              style: AppTextStyles.heading4.copyWith(
                // Menggunakan AppTextStyles.heading4
                color: color,
              ), // Menggunakan heading4 untuk nilai, dengan warna opsional
            ),
          ],
        ),
      ),
    );
  }

  Widget getTitles(BuildContext context, double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'MASUK';
        break;
      case 1:
        text = 'ABSEN/IZIN';
        break;
      case 2:
        text = 'TERLAMBAT';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(
        text,
        style: AppTextStyles.body2.copyWith(
          // Menggunakan AppTextStyles.body2
          fontWeight: FontWeight.bold,
          color: AppColors.textDark, // Hapus `(context)`
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).brightness == Brightness.light
                    ? ColorScheme.light(
                      primary: AppColors.primary, // Hapus `(context)`
                      onPrimary: AppColors.onPrimary, // Hapus `(context)`
                      surface: AppColors.background, // Hapus `(context)`
                      onSurface: AppColors.textDark, // Hapus `(context)`
                    )
                    : ColorScheme.dark(
                      primary: AppColors.primary, // Hapus `(context)`
                      onPrimary: AppColors.onPrimary, // Hapus `(context)`
                      surface: AppColors.background, // Hapus `(context)`
                      onSurface: AppColors.textDark, // Hapus `(context)`
                    ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Hapus `(context)`
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primary, // Hapus `(context)`
              foregroundColor: AppColors.onPrimary, // Hapus `(context)`
              elevation: 0,
            ),
            dialogTheme: DialogTheme(
              backgroundColor: AppColors.cardBackground, // Hapus `(context)`
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
        _reportDataFuture = _fetchAndCalculateMonthlyReports();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Hapus `(context)`
      body: FutureBuilder<void>(
        future: _reportDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary, // Hapus `(context)`
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading data: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.error,
                  ), // Menggunakan AppTextStyles.body2, Hapus `(context)`
                ),
              ),
            );
          }
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary, // Hapus `(context)`
                        AppColors.secondary.withOpacity(
                          0.8,
                        ), // Hapus `(context)`
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Report',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.onPrimary,
                            ), // Menggunakan AppTextStyles.heading1, Hapus `(context)`
                          ),
                          Text(
                            'Review your attendance overview below.',
                            style: AppTextStyles.body1.copyWith(
                              // Menggunakan AppTextStyles.body1
                              color: AppColors.onPrimary.withOpacity(
                                0.8,
                              ), // Hapus `(context)`
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Card(
                            margin: const EdgeInsets.only(top: 25.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.primary.withOpacity(
                              0.2,
                            ), // Hapus `(context)`
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16.0,
                                40.0,
                                16.0,
                                16.0,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Monthly Overview',
                                        style:
                                            AppTextStyles
                                                .heading2, // Menggunakan AppTextStyles.heading2
                                      ),
                                      GestureDetector(
                                        onTap: () => _selectMonth(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors
                                                    .background, // Hapus `(context)`
                                            border: Border.all(
                                              color:
                                                  AppColors
                                                      .border, // Hapus `(context)`
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                DateFormat('MMM yyyy')
                                                    .format(_selectedMonth)
                                                    .toUpperCase(),
                                                style: AppTextStyles.body2.copyWith(
                                                  // Menggunakan AppTextStyles.body2
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.calendar_month,
                                                size: 18,
                                                color:
                                                    AppColors
                                                        .textDark, // Hapus `(context)`
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildStatListItem(
                                    context,
                                    'Total Working Days',
                                    _totalWorkingDaysInMonth.toString(),
                                    AppColors.info, // Hapus `(context)`
                                  ),
                                  _buildStatListItem(
                                    context,
                                    'Total Present Days',
                                    _presentCount.toString(),
                                    AppColors.success, // Hapus `(context)`
                                  ),
                                  _buildStatListItem(
                                    context,
                                    'Total Absent Days',
                                    _absentCount.toString(),
                                    AppColors.error, // Hapus `(context)`
                                  ),
                                  _buildStatListItem(
                                    context,
                                    'Total Izin Days',
                                    _permitCount.toString(),
                                    AppColors.warning, // Hapus `(context)`
                                  ),
                                  _buildStatListItem(
                                    context,
                                    'Total Late Entries',
                                    _lateInCount.toString(),
                                    Colors
                                        .orange, // Menggunakan Colors.orange karena AppColors.orange tidak ada
                                  ),
                                  _buildStatListItem(
                                    context,
                                    'Total Working Hours',
                                    _totalWorkingHours,
                                    AppColors.primary, // Hapus `(context)`
                                  ),
                                  _buildStatListItem(
                                    context,
                                    'Overall Attendance %',
                                    '${_overallAttendancePercentage.toStringAsFixed(0)}%',
                                    _overallAttendancePercentage >= 80
                                        ? AppColors
                                            .success // Hapus `(context)`
                                        : AppColors.error, // Hapus `(context)`
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: MediaQuery.of(context).size.width / 2 - 25,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.background, // Hapus `(context)`
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors
                                            .shadowColor, // Hapus `(context)`
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.insert_chart_outlined,
                                color: AppColors.primary, // Hapus `(context)`
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(
                      height: 20,
                    ), // Memberikan sedikit ruang di bagian bawah setelah chart
                    // Tombol "View Attendance History" telah dihapus dari sini.
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart'; // Import AppTextStyles
import 'package:presiva/models/app_models.dart';
import 'package:presiva/services/api_Services.dart';

class PersonReportScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

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
  int _absentCount = 0;
  int _lateInCount = 0;
  int _totalWorkingDaysInMonth = 0;
  String _totalWorkingHours = '0hr';

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
      _lateInCount = 0;
      _totalWorkingDaysInMonth = 0;
      _totalWorkingHours = '0hr';
      _barChartGroupData = [];
    });

    try {
      final ApiResponse<AbsenceStats> statsResponse =
          await _apiService.getAbsenceStats();
      if (statsResponse.statusCode == 200 && statsResponse.data != null) {
        final AbsenceStats stats = statsResponse.data!;
        setState(() {
          _presentCount = stats.totalMasuk;
          _absentCount = stats.totalIzin;
          _lateInCount = stats.totalAbsen;
        });
      } else {
        print('Failed to get absence stats: ${statsResponse.message}');
        _updateSummaryCounts(0, 0, 0, 0, '0hr');
        _updateBarChartData(0, 0, 0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load summary: ${statsResponse.message}'),
            ),
          );
        }
        return;
      }

      final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final String endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

      final ApiResponse<List<Absence>> historyResponse = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      Duration totalWorkingDuration = Duration.zero;
      int actualPresentCount = 0;
      int actualAbsentCount = 0;
      int actualLateCount = 0;

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
            actualPresentCount++;
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
                actualLateCount++;
              }
            }
          } else if (absence.status?.toLowerCase() == 'izin') {
            actualAbsentCount++;
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

      setState(() {
        _presentCount = actualPresentCount;
        _absentCount = actualAbsentCount;
        _lateInCount = actualLateCount;
        _totalWorkingHours = formattedTotalWorkingHours;
        _updateBarChartData(_presentCount, _absentCount, _lateInCount);
      });
    } catch (e) {
      print('Error fetching and calculating monthly reports: $e');
      _updateSummaryCounts(0, 0, 0, 0, '0hr');
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
    int late,
    int totalWorkingDays,
    String totalHrs,
  ) {
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _lateInCount = late;
      _totalWorkingDaysInMonth = totalWorkingDays;
      _totalWorkingHours = totalHrs;
    });
  }

  void _updateBarChartData(int present, int absent, int late) {
    _maxYValue = [
      present.toDouble(),
      absent.toDouble(),
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
            color: Colors.green,
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
            toY: absent.toDouble(),
            color: Colors.red,
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
            color: Colors.orange,
            width: 25,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    ];
  }

  // Menerima BuildContext untuk mengakses AppColors dan AppTextStyles
  Widget _buildStatListItem(
    BuildContext context,
    String title,
    dynamic value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context), // Menggunakan BuildContext
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            style: TextStyle(
              fontSize: 16.0, // Perkirakan ukuran font untuk 'medium'
              fontWeight:
                  FontWeight.w500, // Perkirakan ketebalan font untuk 'medium'
              color: AppColors.textDark(context),
            ),
          ),
          Text(value.toString(), style: AppTextStyles.body1(context)),
        ],
      ),
    );
  }

  // Function to get titles for the bottom axis
  Widget getTitles(BuildContext context, double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'MASUK';
        break;
      case 1:
        text = 'IZIN';
        break;
      case 2:
        text = 'TERLAMBAT';
        break;
      default:
        text = '';
        break;
    }
    // Use SideTitleWidget correctly with axisSide from TitleMeta
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(
        text,
        style: TextStyle(
          fontSize:
              14.0, // Perkirakan ukuran font untuk 'bold' (umumnya 14 atau 16)
          fontWeight: FontWeight.bold, // Menjadikan teks tebal
          color: AppColors.textDark(context),
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
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary(
              context,
            ), // Menggunakan BuildContext
            colorScheme: ColorScheme.light(
              primary: AppColors.primary(context),
            ), // Menggunakan BuildContext
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
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
      backgroundColor: AppColors.background(
        context,
      ), // Menggunakan BuildContext
      body: FutureBuilder<void>(
        future: _reportDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Stack(
            children: [
              // Background gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary(context), // Menggunakan BuildContext
                        AppColors.secondary(
                          context,
                        ), // Menggunakan BuildContext
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Content
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 20),
                    // Welcome section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                              fontFamily:
                                  'Montserrat', // Ganti dengan font family Anda jika ada
                            ),
                          ),
                          Text(
                            'Test this monthly report',
                            style: TextStyle(
                              fontSize:
                                  16.0, // Perkirakan ukuran font yang sesuai dengan 'medium'
                              fontWeight:
                                  FontWeight
                                      .w500, // Perkirakan ketebalan font untuk 'medium'
                              color:
                                  Colors
                                      .white70, // Gunakan warna yang Anda inginkan secara langsung
                              // fontFamily: 'Montserrat', // Opsional: Tambahkan font family jika Anda menggunakannya secara konsisten
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Monthly Overview Card
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
                            elevation: 4,
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
                                        style: TextStyle(
                                          fontSize:
                                              20.0, // Perkirakan ukuran font untuk judul (sesuai dengan 'title' sebelumnya)
                                          fontWeight:
                                              FontWeight
                                                  .bold, // Perkirakan ketebalan font untuk judul
                                          color: AppColors.textDark(context),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _selectMonth(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
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
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold, // Sesuai dengan 'AppTextStyles.bold'
                                                  color: AppColors.textDark(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: AppColors.textDark(
                                                  context,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Stats list - now calls the defined method
                                  _buildStatListItem(
                                    context, // Meneruskan BuildContext
                                    'Total Working Days',
                                    _totalWorkingDaysInMonth.toString().padLeft(
                                      2,
                                      '0',
                                    ),
                                    Colors.blueGrey,
                                  ),
                                  _buildStatListItem(
                                    context, // Meneruskan BuildContext
                                    'Total Present Days',
                                    _presentCount.toString().padLeft(2, '0'),
                                    Colors.green,
                                  ),
                                  _buildStatListItem(
                                    context, // Meneruskan BuildContext
                                    'Total Absent Days',
                                    _absentCount.toString().padLeft(2, '0'),
                                    Colors.red,
                                  ),
                                  _buildStatListItem(
                                    context, // Meneruskan BuildContext
                                    'Total Late Entries',
                                    _lateInCount.toString().padLeft(2, '0'),
                                    Colors.orange,
                                  ),
                                  _buildStatListItem(
                                    context, // Meneruskan BuildContext
                                    'Total Working Hours',
                                    _totalWorkingHours,
                                    AppColors.primary(
                                      context,
                                    ), // Menggunakan BuildContext
                                  ),
                                  _buildStatListItem(
                                    context, // Meneruskan BuildContext
                                    'Overall Attendance %',
                                    '${(_presentCount / (_totalWorkingDaysInMonth == 0 ? 1 : _totalWorkingDaysInMonth) * 100).toStringAsFixed(0)}%',
                                    Colors.teal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Icon
                          Positioned(
                            top: 0,
                            left: MediaQuery.of(context).size.width / 2 - 25,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.background(
                                  context,
                                ), // Menggunakan BuildContext
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.home_work_outlined,
                                color: AppColors.primary(
                                  context,
                                ), // Menggunakan BuildContext
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Bar Chart Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Overview (Bar Chart)',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_presentCount + _absentCount + _lateInCount > 0)
                            AspectRatio(
                              aspectRatio: 1.5,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: _maxYValue,
                                      barTouchData: BarTouchData(
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem: (
                                            BarChartGroupData group,
                                            int groupIndex,
                                            BarChartRodData rod,
                                            int rodIndex,
                                          ) {
                                            String category;
                                            switch (group.x) {
                                              case 0:
                                                category = 'Present';
                                                break;
                                              case 1:
                                                category = 'Absent';
                                                break;
                                              case 2:
                                                category = 'Late';
                                                break;
                                              default:
                                                category = '';
                                            }
                                            return BarTooltipItem(
                                              '$category\n',
                                              TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text:
                                                      rod.toY
                                                          .toInt()
                                                          .toString(),
                                                  style: TextStyle(
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.yellow,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget:
                                                (value, meta) => getTitles(
                                                  context,
                                                  value,
                                                  meta,
                                                ), // Meneruskan BuildContext
                                            reservedSize: 38,
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              if (value % 1 == 0) {
                                                return SideTitleWidget(
                                                  axisSide: meta.axisSide,
                                                  space: 4,
                                                  child: Text(
                                                    value.toInt().toString(),
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: AppColors.textDark(
                                                        context,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                          color: const Color(0xff37434d),
                                          width: 1,
                                        ),
                                      ),
                                      barGroups: _barChartGroupData,
                                      gridData: const FlGridData(show: true),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No attendance data available for the selected month to display chart.',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontStyle:
                                        FontStyle
                                            .italic, // Memberikan gaya italic
                                    fontWeight:
                                        FontWeight
                                            .normal, // Biasanya pesan info tidak terlalu tebal
                                    color: AppColors.textLight(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // View Details Button
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary(
                            context,
                          ), // Menggunakan BuildContext
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary(
                                context,
                              ).withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
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

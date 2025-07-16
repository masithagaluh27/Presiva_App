import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/models/app_models.dart';
import 'package:presiva/api/api_Services.dart';

import '../../widgets/custom_date_input_field.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/primary_button.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final ApiService _apiService = ApiService();
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }
    if (_reasonController.text.isEmpty) {
      _showSnackBar('Please enter a reason for the request.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      
      final String formattedDate = DateFormat(
        'yyyy-MM-dd', 
      
      ).format(_selectedDate!);

      final ApiResponse<Absence> response = await _apiService.submitIzinRequest(
        date: formattedDate,
        alasanIzin: _reasonController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSnackBar('Request submitted successfully!');
          Navigator.pop(context, true);
        }
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showSnackBar('Failed to submit request: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Izin Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4.0,
        shadowColor: AppColors.primary.withOpacity(0.3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fill out the form to submit your leave or absence request.',
              style: TextStyle(
                fontSize: 16.0,
                color: AppColors.textDark.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            _buildInputContainer(
              child: CustomDateInputField(
                labelText: 'Select Date',
                icon: Icons.calendar_today,
                selectedDate: _selectedDate,
                onTap: () => _selectDate(context),
                hintText:
                    _selectedDate == null
                        ? 'Tap to choose a date'
                        : DateFormat('dd MMMM yyyy', 'id_ID').format(
                          _selectedDate!,
                        ),
              ),
            ),
            const SizedBox(height: 25),
            _buildInputContainer(
              child: CustomInputField(
                controller: _reasonController,
                labelText: 'Reason for Request',
                hintText: 'e.g., Annual leave, sick leave, personal matters',
                icon: Icons.edit_note,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                customValidator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reason cannot be empty';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : PrimaryButton(
                  label: 'Submit Izin',
                  onPressed: _submitRequest,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: child),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:presiva/constant/app_colors.dart'; // Assuming this defines your color palette
import 'package:presiva/models/app_models.dart';
import 'package:presiva/services/api_Services.dart';

import '../../widgets/custom_date_input_field.dart'; // Your CustomDateInputField
import '../../widgets/custom_input_field.dart'; // Your CustomInputField
import '../../widgets/primary_button.dart'; // Your PrimaryButton

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false; // Add loading state

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
              // Gunakan ColorScheme.light di sini karena kita menimpa tema date picker agar selalu light
              primary: AppColors.primary(context), // <--- UBAH DI SINI
              onPrimary: Colors.white, // Header text color, bisa tetap putih
              onSurface: AppColors.textDark(context), // <--- UBAH DI SINI
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary(
                  context,
                ), // <--- UBAH DI SINI
              ),
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
    // Basic validation
    if (_selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }
    if (_reasonController.text.isEmpty) {
      _showSnackBar('Please enter a reason for the request.');
      return;
    }

    setState(() {
      _isLoading = true; // Set loading to true
    });

    try {
      // Format the selected date to yyyy-MM-dd as required by the /izin API
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);

      // Call the dedicated submitIzinRequest method from ApiService
      final ApiResponse<Absence> response = await _apiService.submitIzinRequest(
        date: formattedDate, // Pass the formatted date as 'date'
        alasanIzin: _reasonController.text.trim(), // Only send the reason text
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSnackBar('Request submitted successfully!');
          Navigator.pop(context, true); // Pop with true to indicate success
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
        _isLoading = false; // Set loading to false
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
      backgroundColor: AppColors.background(context), // <--- UBAH DI SINI
      appBar: AppBar(
        title: const Text(
          'New Request',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make app bar title bold
          ),
        ),
        backgroundColor: AppColors.primary(context), // <--- UBAH DI SINI
        foregroundColor:
            Colors
                .white, // Jika Anda ingin foreground tetap putih terlepas dari tema, biarkan Colors.white. Jika ingin dinamis, gunakan AppColors.textLight(context) atau sejenisnya.
        elevation: 4.0, // Add a subtle shadow
        shadowColor: AppColors.primary(
          context,
        ).withOpacity(0.3), // <--- UBAH DI SINI
        centerTitle: true, // Center the title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 20.0,
        ), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fill out the form to submit your leave or absence request.',
              style: TextStyle(
                fontSize: 16.0,
                color: AppColors.textDark(
                  context,
                ).withOpacity(0.7), // <--- UBAH DI SINI
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Date Picker using CustomDateInputField
            _buildInputContainer(
              child: CustomDateInputField(
                labelText: 'Select Date',
                icon: Icons.calendar_today,
                selectedDate: _selectedDate,
                onTap: () => _selectDate(context),
                hintText: 'Tap to choose a date',
              ),
            ),
            const SizedBox(height: 25), // Increased spacing
            // Reason Text Field using CustomInputField
            _buildInputContainer(
              child: CustomInputField(
                controller: _reasonController,
                labelText: 'Reason for Request',
                hintText: 'e.g., Annual leave, sick leave, personal matters',
                icon: Icons.edit_note,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                fillColor: AppColors.inputFill(context), // <--- UBAH DI SINI
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
            const SizedBox(height: 40), // Increased spacing
            // Submit Button using PrimaryButton
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary(context),
                  ), // <--- UBAH DI SINI
                )
                : PrimaryButton(
                  label: 'Submit Request',
                  onPressed: _submitRequest,
                ),
          ],
        ),
      ),
    );
  }

  // Helper method to wrap input fields in a consistent container for elegance
  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        // Untuk warna background kontainer, jika Anda ingin dinamis, gunakan AppColors.cardBackground(context)
        // Jika Anda selalu ingin putih terang, biarkan Colors.white.
        color: AppColors.cardBackground(
          context,
        ), // <--- UBAH DI SINI (Opsional, tergantung keinginan)
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(
              context,
            ).withOpacity(0.1), // <--- UBAH DI SINI
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), // subtle shadow
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: child),
    );
  }
}

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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Button text color
              ),
            ),
            // You can also customize other aspects here for a more refined look
            // For example, shape of the date picker dialog
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
      backgroundColor:
          AppColors.background, // Use your defined background color
      appBar: AppBar(
        title: const Text(
          'New Request',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make app bar title bold
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4.0, // Add a subtle shadow
        shadowColor: AppColors.primary.withOpacity(0.3), // Shadow color
        centerTitle: true, // Center the title
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView
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
                color: AppColors.textDark.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Date Picker using CustomDateInputField
            // Wrapped in a Container for a card-like effect
            _buildInputContainer(
              child: CustomDateInputField(
                labelText: 'Select Date',
                icon: Icons.calendar_today,
                selectedDate: _selectedDate,
                onTap: () => _selectDate(context),
                hintText: 'Tap to choose a date', // More engaging hint text
              ),
            ),
            const SizedBox(height: 25), // Increased spacing
            // Reason Text Field using CustomInputField
            // Wrapped in a Container for a card-like effect
            _buildInputContainer(
              child: CustomInputField(
                controller: _reasonController,
                labelText:
                    'Reason for Request', // This becomes the floating label
                hintText:
                    'e.g., Annual leave, sick leave, personal matters', // This remains the hint text inside the field
                icon: Icons.edit_note,
                maxLines: 5, // Increased maxLines for more detailed input
                keyboardType:
                    TextInputType.multiline, // Set keyboard to multiline
                fillColor: AppColors.inputFill, // Match previous fillColor
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18, // Adjusted vertical padding for multiline
                ),
                customValidator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reason cannot be empty';
                  }
                  return null;
                },
                // Add styling to CustomInputField if not already present internally
                // For example:
                // border: OutlineInputBorder(
                //   borderRadius: BorderRadius.circular(12.0),
                //   borderSide: BorderSide.none, // Or a subtle color
                // ),
                // focusedBorder: OutlineInputBorder(
                //   borderRadius: BorderRadius.circular(12.0),
                //   borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                // ),
                // hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
                // labelStyle: TextStyle(color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 40), // Increased spacing
            // Submit Button using PrimaryButton
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : PrimaryButton(
                  label: 'Submit Request',
                  onPressed: _submitRequest,
                  // Ensure PrimaryButton supports elevated style internally
                  // For example, within PrimaryButton:
                  // style: ElevatedButton.styleFrom(
                  //   backgroundColor: AppColors.primary,
                  //   foregroundColor: Colors.white,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12.0),
                  //   ),
                  //   padding: const EdgeInsets.symmetric(vertical: 16.0),
                  //   elevation: 5.0, // Add elevation
                  //   shadowColor: AppColors.primary.withOpacity(0.4), // Shadow color
                  // ),
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
        color: Colors.white, // A clean white background for inputs
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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

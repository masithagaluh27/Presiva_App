import 'package:flutter/material.dart';
import 'package:presiva/api/api_Services.dart';
import 'package:presiva/constant/app_colors.dart';
import 'package:presiva/constant/app_text_styles.dart'; // Import AppTextStyles
import 'package:presiva/models/app_models.dart';
import 'package:presiva/screens/authentication/edit_profile_screen.dart';

import '../../endpoint/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const ProfileScreen({super.key, required this.refreshNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadUserData();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _loadUserData();
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final ApiResponse<User> response = await _apiService.getProfile();

    setState(() => _isLoading = false);

    if (response.statusCode == 200 && response.data != null) {
      setState(() => _currentUser = response.data);
    } else {
      print('Failed to load user profile: ${response.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile: ${response.message}',
              style: TextStyle(color: AppColors.onError),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _currentUser = null);
    }
  }

  void _logout(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Logout Confirmation',
              style: AppTextStyles.heading3.copyWith(color: AppColors.textDark),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: AppTextStyles.body2.copyWith(color: AppColors.textLight),
            ),
            backgroundColor: AppColors.cardBackground,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                ),
                child: Text(
                  'Logout',
                  style: AppTextStyles.body1.copyWith(color: AppColors.onError),
                ),
              ),
            ],
          ),
    );

    if (confirmLogout == true) {
      await ApiService.clearToken();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  void _navigateToEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User data not loaded yet. Please wait.',
            style: TextStyle(color: AppColors.onError),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _currentUser!),
      ),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = _currentUser?.name ?? 'Guest User';
    final String email = _currentUser?.email ?? 'guest@example.com';
    final String jenisKelamin =
        _currentUser?.jenis_kelamin == 'L'
            ? 'Laki-laki'
            : _currentUser?.jenis_kelamin == 'P'
            ? 'Perempuan'
            : 'N/A';
    final String profilePhotoUrl = _currentUser?.profile_photo ?? '';
    final String designation = _currentUser?.training_title ?? 'Employee';

    ImageProvider<Object>? profileImageProvider;
    if (profilePhotoUrl.isNotEmpty) {
      final String fullImageUrl =
          profilePhotoUrl.startsWith('http')
              ? profilePhotoUrl
              : 'https://appabsensi.mobileprojp.com/public/$profilePhotoUrl';
      profileImageProvider = NetworkImage(fullImageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: AppTextStyles.heading2.copyWith(color: AppColors.onPrimary),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadUserData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(profileImageProvider, username, designation),
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          children: [
                            _buildContentCard(
                              email,
                              _currentUser?.batch_ke,
                              jenisKelamin,
                              designation,

                              profilePhotoUrl,
                            ),
                            const SizedBox(height: 20),
                            _buildActionOptions(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader(ImageProvider<Object>? image, String name, String role) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: image,
              child:
                  image == null
                      ? Icon(Icons.person, size: 60, color: AppColors.primary)
                      : null,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.onPrimary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(
    String email,
    String? batchKe,
    String jenisKelamin,
    String designation,

    String profilePhotoPath,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        shadowColor: AppColors.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Personal Details',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textDark.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 20),

              //PROFILE DETAILS
              _buildDetailRow('Email ID', email, Icons.email_outlined),
              if (batchKe != null) ...[
                Divider(color: AppColors.border, height: 25),
                _buildDetailRow(
                  'Batch',
                  batchKe,
                  Icons.calendar_today_outlined,
                ),
              ],
              Divider(color: AppColors.border, height: 25),
              _buildDetailRow('Gender', jenisKelamin, Icons.transgender),
              Divider(color: AppColors.border, height: 25),
              _buildDetailRow('Designation', designation, Icons.work_outline),
              Divider(color: AppColors.border, height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body3(
                    color: AppColors.textLight.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Optional Notification Switch (can uncomment if used)
          // Card(
          //   color: AppColors.cardBackground,
          //   margin: EdgeInsets.zero,
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(15),
          //   ),
          //   child: ListTile(
          //     leading: Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          //     title: Text('Notifications', style: AppTextStyles.body1.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
          //     trailing: Switch.adaptive(
          //       value: _notificationEnabled,
          //       onChanged: (val) => setState(() => _notificationEnabled = val),
          //       activeColor: AppColors.primary,
          //     ),
          //   ),
          // ),
          Card(
            color: AppColors.cardBackground,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.1),
            child: ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.primary),
              title: Text(
                'Edit Profile',
                style: AppTextStyles.body1.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: AppColors.textLight,
              ),
              onTap: _navigateToEditProfile,
            ),
          ),
          const SizedBox(height: 15),
          Card(
            color: AppColors.cardBackground,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
            shadowColor: AppColors.error.withOpacity(0.1),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                'Logout',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.error,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: AppColors.textLight,
              ),
              onTap: () => _logout(context),
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

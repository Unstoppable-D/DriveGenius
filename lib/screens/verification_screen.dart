import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/appwrite_constants.dart';
import '../providers/auth_provider.dart';
import '../services/appwrite_service.dart';
import 'client/client_dashboard_screen.dart';
import 'driver/driver_dashboard_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _isUploadingDocument = false;
  
  // File and image storage
  PlatformFile? _idDocument;
  File? _profileImage;
  String? _idDocumentUrl;
  String? _profileImageUrl;
  
  // Address form controllers
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  
  // Form validation
  final _formKey = GlobalKey<FormState>();
  
  late AppwriteService _appwriteService;
  late AuthProvider _authProvider;
  
  @override
  void initState() {
    super.initState();
    _appwriteService = AppwriteService();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Load existing profile data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProfileData();
    });
  }

  Future<void> _loadExistingProfileData() async {
    try {
      final user = _authProvider.user;
      if (user == null) return;
      
      // Load existing verification data
      final verificationData = await _appwriteService.getVerificationData(user.id);
      if (verificationData != null && mounted) {
        setState(() {
          _houseNumberController.text = verificationData.data['house_number'] ?? '';
          _streetController.text = verificationData.data['street'] ?? '';
          _townController.text = verificationData.data['town'] ?? '';
          _stateController.text = verificationData.data['state'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading existing profile data: $e');
    }
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _streetController.dispose();
    _townController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _authProvider.isDriver ? 'Driver Verification' : 'Profile Setup',
          style: AppTextStyles.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? AppSizes.md : AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header Section
                _buildModernHeader(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
                
                // Profile Picture Section
                _buildModernProfilePictureSection(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
                
                // Document Upload Section (Drivers Only)
                if (_authProvider.isDriver) ...[
                  _buildModernDocumentUploadSection(isSmallScreen),
                  SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
                ],
                
                // Address Section
                _buildModernAddressSection(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
                
                // Submit Button
                _buildModernSubmitButton(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
                
                // Info Section
                _buildModernInfoSection(isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? AppSizes.md : AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.08),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with animated background
          Container(
            padding: EdgeInsets.all(isSmallScreen ? AppSizes.md : AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              _authProvider.isDriver ? Icons.directions_car_filled : Icons.person_pin_circle,
              size: isSmallScreen ? 40 : 48,
              color: AppColors.primary,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? AppSizes.md : AppSizes.lg),
          
          Text(
            _authProvider.isDriver ? 'Complete Your Driver Profile' : 'Complete Your Profile',
            style: (isSmallScreen ? AppTextStyles.h4 : AppTextStyles.h3).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isSmallScreen ? AppSizes.sm : AppSizes.md),
          
          Text(
            _authProvider.isDriver 
                ? 'Upload required documents and complete your profile to start accepting trips'
                : 'Add your profile picture and address to complete your setup',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfilePictureSection(bool isSmallScreen) {
    return _buildModernCard(
      icon: Icons.camera_alt_rounded,
      iconColor: AppColors.secondary,
      title: 'Profile Picture',
      subtitle: 'Upload a clear photo of yourself',
      child: Column(
        children: [
          // Profile Image Preview
          if (_profileImage != null) ...[
            Center(
              child: Container(
                width: isSmallScreen ? 100 : 120,
                height: isSmallScreen ? 100 : 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  child: Image.file(
                    _profileImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: AppSizes.md),
            
            // Change Photo Button
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _takePhoto(ImageSource.gallery),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Change Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Upload Options
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _takePhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: AppSizes.md),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _takePhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppSizes.md),
            
            // Info Box
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Profile picture is required for verification',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Upload Progress Indicator
          if (_isUploadingImage) ...[
            SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Uploading profile image...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernDocumentUploadSection(bool isSmallScreen) {
    return _buildModernCard(
      icon: Icons.upload_file_rounded,
      iconColor: AppColors.primary,
      title: 'Driver License / ID Document',
      subtitle: 'Upload a clear photo of your driver license or ID',
      child: Column(
        children: [
          // Document Preview
          if (_idDocument != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Selected',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          _idDocument!.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Size: ${(_idDocument!.size / 1024).toStringAsFixed(1)} KB',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _idDocument = null;
                        _idDocumentUrl = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppSizes.md),
            
            // Change Document Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickIdDocument,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Change Document'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Upload Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickIdDocument,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Choose Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: AppSizes.md),
            
            // Document Requirements
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        'Document Requirements:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    '• Clear, readable image or PDF\n• Valid government-issued ID\n• Not expired\n• Maximum file size: 10MB',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.info,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Upload Progress Indicator
          if (_isUploadingDocument) ...[
            SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Uploading document...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernAddressSection(bool isSmallScreen) {
    return _buildModernCard(
      icon: Icons.location_on_rounded,
      iconColor: AppColors.accent,
      title: 'Address Information',
      subtitle: 'Provide your residential address',
      child: Column(
        children: [
          // Address Form Fields
          _buildModernTextField(
            controller: _houseNumberController,
            label: 'House Number',
            hint: 'Enter house number',
            icon: Icons.home_rounded,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: AppSizes.md),
          
          _buildModernTextField(
            controller: _streetController,
            label: 'Street',
            hint: 'Enter street name',
            icon: Icons.streetview_rounded,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: AppSizes.md),
          
          _buildModernTextField(
            controller: _townController,
            label: 'Town/City',
            hint: 'Enter town or city',
            icon: Icons.location_city_rounded,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: AppSizes.md),
          
          _buildModernTextField(
            controller: _stateController,
            label: 'State',
            hint: 'Enter state',
            icon: Icons.map_rounded,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: AppSizes.lg),
          
          // Address Preview
          if (_houseNumberController.text.isNotEmpty ||
              _streetController.text.isNotEmpty ||
              _townController.text.isNotEmpty ||
              _stateController.text.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        'Address Preview:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '${_houseNumberController.text} ${_streetController.text}, ${_townController.text}, ${_stateController.text}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.accent),
        suffixIcon: controller.text.trim().isNotEmpty
            ? Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
      style: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        color: AppColors.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label.toLowerCase()';
        }
        return null;
      },
    );
  }

  Widget _buildModernSubmitButton(bool isSmallScreen) {
    final canSubmit = _canSubmit();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: canSubmit ? [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: canSubmit && !_isSubmitting ? _submitVerification : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? AppColors.success : AppColors.border,
          foregroundColor: canSubmit ? Colors.white : AppColors.textSecondary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: isSmallScreen ? AppSizes.md : AppSizes.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Submitting...',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _authProvider.isDriver ? Icons.verified_user_rounded : Icons.check_circle_rounded,
                    size: 24,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    _authProvider.isDriver ? 'Submit for Verification' : 'Complete Profile',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: canSubmit ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModernInfoSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? AppSizes.md : AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                'Important Information',
                style: (isSmallScreen ? AppTextStyles.h6 : AppTextStyles.h5).copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSizes.md),
          
          if (_authProvider.isDriver) ...[
            Text(
              '• Your verification will be reviewed within 24-48 hours\n• You can start accepting trips after verification is approved\n• Keep your documents up to date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.info,
                height: 1.5,
              ),
            ),
          ] else ...[
            Text(
              '• Your profile will be completed immediately\n• You can start booking trips right away\n• Keep your information up to date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.info,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          child,
        ],
      ),
    );
  }

  bool _canSubmit() {
    // Check if profile picture is uploaded
    if (_profileImage == null) {
      print('❌ Submit validation: Profile image missing');
      return false;
    }
    
    // Check if document is uploaded (for drivers only)
    if (_authProvider.isDriver && _idDocument == null) {
      print('❌ Submit validation: Driver document missing');
      return false;
    }
    
    // Check if address fields are filled
    if (_houseNumberController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty ||
        _townController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty) {
      print('❌ Submit validation: Address fields incomplete');
      return false;
    }
    
    // Check if any upload is in progress
    if (_isUploadingImage || _isUploadingDocument) {
      print('❌ Submit validation: Upload in progress');
      return false;
    }
    
    print('✅ Submit validation: All requirements met');
    return true;
  }

  Future<void> _pickIdDocument() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _idDocument = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _isUploadingImage = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo != null) {
        setState(() {
          _profileImage = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = _authProvider.user;
      if (user == null) {
        throw Exception('User not found. Please log in again.');
      }

      String? profileImageFileId;
      String? documentFileId;
      String? documentUrl;

      // Upload profile image with proper error handling
      if (_profileImage == null) {
        throw Exception('Profile image is required. Please select an image first.');
      }
      
      String profileUrl = '';
      
      try {
        setState(() {
          _isUploadingImage = true;
        });
        
        // Validate profile image file
        if (_profileImage!.path.isEmpty) {
          throw Exception('Selected profile image is corrupted or empty. Please select a different image.');
        }
        
        print('📁 Uploading profile image to profile bucket');
        print('   File path: ${_profileImage!.path}');
        
        // Use new method that returns both fileId and viewable URL with PUBLIC READ permission
        final (profileFileId, profileUrlResult) = await _appwriteService.uploadAvatar(
          userId: user.id,
          filePath: _profileImage!.path,
        );
        
        profileImageFileId = profileFileId;
        profileUrl = profileUrlResult;
        
        print('✅ Profile image uploaded successfully: $profileImageFileId');
        print('   Viewable URL: $profileUrl');
        
      } catch (uploadError) {
        print('❌ Profile image upload failed: $uploadError');
        throw Exception('Failed to upload profile image: ${uploadError.toString()}');
      } finally {
        setState(() {
          _isUploadingImage = false;
        });
      }

      // Upload ID document for drivers only
      if (_authProvider.isDriver) {
        if (_idDocument == null) {
          throw Exception('Driver document is required for verification. Please select a document.');
        }
        try {
          setState(() {
            _isUploadingDocument = true;
          });
          
          // Validate driver document file
          final documentPath = _idDocument!.path;
          final documentBytes = _idDocument!.bytes;
          
          if ((documentPath == null || documentPath.isEmpty) && documentBytes == null) {
            throw Exception('Selected driver document is corrupted or empty. Please select a different document.');
          }
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = path.extension(_idDocument!.name);
          final customFileName = 'document_${user.id}_$timestamp$extension';
          
          print('📁 Uploading driver document: $customFileName');
          print('   File path: $documentPath');
          print('   Has bytes: ${documentBytes != null}');
          
          if (documentPath != null && documentPath.isNotEmpty) {
            final (docFileId, docUrl) = await _appwriteService.uploadDriverDocument(
              userId: user.id,
              filePath: documentPath,
            );
            documentFileId = docFileId;
            documentUrl = docUrl;
          } else {
            throw Exception('Document path is required for upload');
          }
          
          // Store the actual fileId for future reference
          // documentFileId is already set
          
          print('✅ Driver document uploaded successfully: $documentFileId');
          print('   Custom filename: $customFileName');
          print('   Appwrite fileId: $documentFileId');
          print('   Full URL: ${_appwriteService.getFileUrl(bucketId: 'documents', fileId: documentFileId)}');
        } catch (uploadError) {
          print('❌ Driver document upload failed: $uploadError');
          throw Exception('Failed to upload driver document: ${uploadError.toString()}');
        } finally {
          setState(() {
            _isUploadingDocument = false;
          });
        }
      }

      // Build address data
      final addressData = {
        'addressLine1': '${_houseNumberController.text.trim()} ${_streetController.text.trim()}'.trim(),
        'city': _townController.text.trim(),
        'state': _stateController.text.trim(),
        'country': 'Nigeria',
        'postalCode': '',
      };

      // Update user preferences with flexible data
      try {
        print('📝 Updating user preferences with verification data...');
        
        await _appwriteService.updateUserPrefs(
          profileImageFileId: profileImageFileId,
          documentFileId: documentFileId,
          documentType: _authProvider.isDriver ? 'LICENSE' : null,
          address: addressData,
        );
        
        print('✅ User preferences updated successfully');
      } catch (prefsError) {
        print('❌ Failed to update user preferences: $prefsError');
        throw Exception('Failed to update user preferences: ${prefsError.toString()}');
      }

              // Save avatar, address, and document URL in Account preferences for fast access
        try {
          print('✅ Saving avatar, address, and document URL to preferences...');
          
          await _appwriteService.savePrefsAfterVerification(
            profileImageUrl: profileUrl,
            documentUrl: documentUrl,
            houseNumber: _houseNumberController.text.trim(),
            street: _streetController.text.trim(),
            city: _townController.text.trim(),
            state: _stateController.text.trim(),
          );
          
          print('✅ Avatar, address, and document URL saved to preferences');
        } catch (prefsError) {
          print('❌ Failed to save preferences: $prefsError');
          throw Exception('Failed to save preferences: ${prefsError.toString()}');
        }

        // Mark user verified in the profiles collection
        try {
          print('✅ Marking user as verified in profiles...');
          
          await _appwriteService.markUserVerifiedInProfiles();
          
          print('✅ User marked as verified in profiles collection');
        } catch (verifyError) {
          print('❌ Failed to mark user as verified: $verifyError');
          throw Exception('Failed to mark user as verified: ${verifyError.toString()}');
        }

      // Create/update verification record using new method
      try {
        print('📝 Creating/updating verification record...');
        
        await _appwriteService.upsertVerification(
          userId: user.id,
          role: _authProvider.isDriver ? 'driver' : 'client',
          profileImageUrl: profileUrl,
          documentUrl: documentUrl ?? '', // Use the actual URL, not fileId
          houseNumber: _houseNumberController.text.trim(),
          street: _streetController.text.trim(),
          city: _townController.text.trim(),
          state: _stateController.text.trim(),
          status: 'VERIFIED', // Mark as verified immediately
        );
        
        print('✅ Verification record created/updated successfully');
      } catch (verificationError) {
        print('❌ Verification record creation failed: $verificationError');
        throw Exception('Failed to create verification record: ${verificationError.toString()}');
      }

              // Update local user state and refresh preferences
        try {
          // Refresh preferences from Appwrite to ensure consistency
          await _authProvider.refreshPrefs(_appwriteService);
          
          // Also set verified status locally
          _authProvider.setVerified(true);
          
          print('✅ Local user state updated and preferences refreshed');
        } catch (localUpdateError) {
          print('⚠️ Local user state update failed: $localUpdateError');
          // Don't fail the entire process for local state update
        }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authProvider.isDriver 
                ? 'Verification submitted successfully! You will be notified once approved.'
                : 'Profile completed successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to home screen after successful verification
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      print('❌ Verification submission failed: $e');
      
      if (mounted) {
        // Show specific error messages based on error type
        String errorMessage = 'Verification failed';
        
        if (e.toString().contains('profile image')) {
          errorMessage = 'Profile image upload failed. Please try again.';
        } else if (e.toString().contains('driver document')) {
          errorMessage = 'Driver document upload failed. Please try again.';
        } else if (e.toString().contains('User not found')) {
          errorMessage = 'Session expired. Please log in again.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Allow user to retry
                setState(() {
                  _isSubmitting = false;
                });
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

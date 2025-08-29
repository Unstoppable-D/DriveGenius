import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/appwrite_constants.dart';
import '../providers/auth_provider.dart';
import '../services/appwrite_service.dart';
import '../widgets/verification_badge.dart';
import '../widgets/logout_button.dart';
import 'package:appwrite/appwrite.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user's profile
  
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppwriteService _appwriteService = AppwriteService();
  
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _verificationData;
  bool _isLoading = true;
  bool _isOwnProfile = false;
  String? _profileImageUrl;
  String? _documentUrl;
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }
  
  Future<void> _loadProfileData() async {
    try {
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      final targetUserId = widget.userId ?? currentUserId;
      
      if (targetUserId == null) {
        throw Exception('No user ID available');
      }
      
      _isOwnProfile = targetUserId == currentUserId;
      
      // Load profile data
      final profileDoc = await _appwriteService.getUserProfile(targetUserId);
      _profileData = profileDoc.data;
      
      // Load verification data
      try {
        final verificationDoc = await _appwriteService.getVerificationData(targetUserId);
        if (verificationDoc != null) {
          _verificationData = verificationDoc.data;
          
          // Get file URLs if available
          if (_verificationData?['profileImageUrl'] != null) {
            _profileImageUrl = _appwriteService.getFileUrl(
              bucketId: AppwriteIds.profileBucketId,
              fileId: _verificationData!['profileImageUrl'],
            );
            print('✅ Profile image URL loaded: $_profileImageUrl');
          }
          
                  if (_verificationData?['documentUrl'] != null) {
          _documentUrl = _appwriteService.getFileUrl(
            bucketId: AppwriteIds.profileBucketId,
            fileId: _verificationData!['documentUrl'],
          );
          print('✅ Document URL loaded: $_documentUrl');
        }
        }
      } catch (e) {
        // Verification data might not exist yet
        print('No verification data found: $e');
      }
      
      // Also check if user has a profile image in their profile data
              if (_profileData?['profileImage'] != null && _profileImageUrl == null) {
          _profileImageUrl = _appwriteService.getFileUrl(
            bucketId: AppwriteIds.profileBucketId,
            fileId: _profileData!['profileImage'],
          );
          print('✅ Profile image from profile data: $_profileImageUrl');
        }
      
    } catch (e) {
      print('Error loading profile data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_profileData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Profile not found',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'The requested profile could not be loaded.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit profile screen
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            const SizedBox(height: AppSizes.xl),
            
            // Details Card
            _buildDetailsCard(),
            
            const SizedBox(height: AppSizes.lg),
            
            // Driver Document Card (if applicable)
            if (_profileData?['role'] == 'driver')
              _buildDriverDocumentCard(),
            
            const SizedBox(height: AppSizes.lg),
            
            // Ratings & Stats Card
            _buildRatingsCard(),
            
            const SizedBox(height: AppSizes.lg),
            
            // Actions Card
            _buildActionsCard(),
            
            // Logout Button (only for own profile)
            if (_isOwnProfile) ...[
              const SizedBox(height: AppSizes.xl),
              const LogoutButton.block(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final name = _profileData?['name'] ?? 'Unknown User';
        final role = _profileData?['role'] ?? 'Unknown';
        final isVerified = authProvider.isVerified; // Use AuthProvider state instead of cached data
        
        return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 4,
              ),
            ),
            child: ClipOval(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final avatarUrl = authProvider.avatarUrl;
                  
                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                    return Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderAvatar(name);
                      },
                    );
                  } else {
                    return _buildPlaceholderAvatar(name);
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Name and Role
          Text(
            name,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSizes.xs),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Text(
              role.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.md),
          
          // Verification Status
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final isVerified = authProvider.isVerified;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isVerified 
                        ? Icons.check_circle 
                        : Icons.pending,
                    color: isVerified 
                        ? AppColors.success 
                        : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    isVerified 
                        ? 'Verified' 
                        : 'Verification Pending',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isVerified 
                          ? AppColors.success 
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
        );
      },
    );
  }
  
  Widget _buildPlaceholderAvatar(String name) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailsCard() {
    final email = _profileData?['email'] ?? 'No email';
    final phone = _profileData?['phone'] ?? 'No phone';
    final houseNumber = _verificationData?['houseNumber'] ?? '';
    final street = _verificationData?['street'] ?? '';
    final city = _verificationData?['city'] ?? '';
    final state = _verificationData?['state'] ?? '';
    
    final address = [houseNumber, street, city, state]
        .where((part) => part.isNotEmpty)
        .join(', ');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          _buildDetailRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: AppSizes.md),
          _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
                      const SizedBox(height: AppSizes.md),
            _buildDetailRow(Icons.location_on_outlined, 'Address', 
                Provider.of<AuthProvider>(context, listen: false).addressDisplay),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(width: AppSizes.md),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDriverDocumentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver License / ID',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final docUrl = authProvider.documentUrl;
              
              if (docUrl != null && docUrl.isNotEmpty) {
                return GestureDetector(
                  onTap: () {
                    // Open document in external browser
                    _launchDocumentUrl(docUrl);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: AppColors.info,
                          size: 24,
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Text(
                            'View Document',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          color: AppColors.info,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: AppColors.textTertiary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Text(
                          'No document uploaded',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          )
        ],
      ),
    );
  }
  
  Widget _buildRatingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance & Stats',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.star,
                  'Rating',
                  '4.8',
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _buildStatItem(
                  Icons.trip_origin,
                  'Total Trips',
                  '127',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _buildStatItem(
                  Icons.trending_up,
                  'This Month',
                  '23',
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: AppTextStyles.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          if (_isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: AppSizes.md),
                    Text(
                      'Edit Profile',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_profileData?['role'] == 'driver')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to request trip screen
                  Navigator.pushNamed(context, '/request-trip', 
                      arguments: {'driverId': widget.userId});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_car),
                    const SizedBox(width: AppSizes.md),
                    Text(
                      'Request Trip',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showDocumentPreview() {
    if (_documentUrl != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Document Preview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Document preview functionality will be implemented here.'),
              const SizedBox(height: AppSizes.md),
              Text('Document URL: $_documentUrl'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _launchDocumentUrl(String url) {
    // Launch document URL in external browser
    try {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open document: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

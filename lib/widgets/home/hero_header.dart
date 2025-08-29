import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../screens/verification_screen.dart';

class HeroHeader extends StatelessWidget {
  final User user;
  final Map<String, dynamic>? verificationData;
  final VoidCallback? onVerificationTap;

  const HeroHeader({
    super.key,
    required this.user,
    this.verificationData,
    this.onVerificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = user.isVerified;
    final verificationStatus = user.isVerified ? 'verified' : 'pending';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSizes.lg),
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E5BFF),
            const Color(0xFF4F8CFF),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5BFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Welcome back, ${user.name.split(' ').first}',
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Role and Verification Chips using Wrap to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Role Badge
              Chip(
                label: Text(
                  user.role.name.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                backgroundColor: user.role == UserRole.driver 
                    ? const Color(0xFF16A34A) 
                    : const Color(0xFF2563EB),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              
              // Verification Chip
              _buildVerificationChip(isVerified, verificationStatus),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildVerificationChip(bool isVerified, String verificationStatus) {
    if (verificationStatus == 'verified') {
      return Chip(
        label: Text(
          'Verified',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        avatar: const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 18,
        ),
        backgroundColor: AppColors.success,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      );
    }
    
    Color chipColor;
    IconData icon;
    String text;
    
    if (verificationStatus == 'rejected') {
      chipColor = AppColors.error;
      icon = Icons.info;
      text = 'Rejected';
    } else {
      chipColor = AppColors.warning;
      icon = Icons.schedule;
      text = 'Pending';
    }
    
    return GestureDetector(
      onTap: onVerificationTap ?? () {
        // Default navigation to verification screen
      },
      child: Chip(
        label: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        avatar: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        backgroundColor: chipColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

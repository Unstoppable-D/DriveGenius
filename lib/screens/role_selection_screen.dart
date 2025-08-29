import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // Threshold for small screens
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.selectRole),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppSizes.lg : AppSizes.xl),
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
            
            // Header
            Text(
              AppStrings.selectRole,
              style: (isSmallScreen ? AppTextStyles.h3 : AppTextStyles.h2).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isSmallScreen ? AppSizes.sm : AppSizes.md),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: Text(
                'Choose how you want to use DriveGenius',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? AppSizes.xl : AppSizes.xxl),
            
            // Client Role Card
            _buildRoleCard(
              context: context,
              title: AppStrings.client,
              description: AppStrings.clientDescription,
              icon: Icons.person,
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(role: UserRole.client),
                  ),
                );
              },
            ),
            
            SizedBox(height: isSmallScreen ? AppSizes.md : AppSizes.lg),
            
            // Driver Role Card
            _buildRoleCard(
              context: context,
              title: AppStrings.driver,
              description: AppStrings.driverDescription,
              icon: Icons.directions_car,
              color: AppColors.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(role: UserRole.driver),
                  ),
                );
              },
            ),
            
            // Flexible spacer
            const Spacer(flex: 1),
            
            // Back Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                AppStrings.back,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            
            // Bottom padding for small screens
            SizedBox(height: isSmallScreen ? AppSizes.md : 0),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSizes.md : AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: isSmallScreen ? 50 : 60,
              height: isSmallScreen ? 50 : 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                icon,
                size: isSmallScreen ? 25 : 30,
                color: color,
              ),
            ),
            
            SizedBox(width: isSmallScreen ? AppSizes.md : AppSizes.lg),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (isSmallScreen ? AppTextStyles.h6 : AppTextStyles.h5).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? AppSizes.xs : AppSizes.xs),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: isSmallScreen ? AppSizes.iconXs : AppSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}

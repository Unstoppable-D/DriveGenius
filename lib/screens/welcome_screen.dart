import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // Threshold for small screens
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? AppSizes.lg : AppSizes.xl),
            child: Column(
              children: [
                // Top spacer - flexible
                const Spacer(flex: 1),
                
                // App Logo
                Container(
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car_filled,
                    size: isSmallScreen ? 40 : 50,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
                
                // Welcome Text
                Text(
                  'Welcome to',
                  style: (isSmallScreen ? AppTextStyles.h4 : AppTextStyles.h3).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isSmallScreen ? AppSizes.xs : AppSizes.sm),
                
                Text(
                  AppStrings.appName,
                  style: (isSmallScreen ? AppTextStyles.h2 : AppTextStyles.h1).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isSmallScreen ? AppSizes.sm : AppSizes.md),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                  child: Text(
                    AppStrings.appTagline,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Middle spacer - flexible
                const Spacer(flex: 1),
                
                // Action Buttons
                Column(
                  children: [
                    // Get Started Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: isSmallScreen ? AppTextStyles.buttonMedium : AppTextStyles.buttonLarge,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? AppSizes.sm : AppSizes.md),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? AppSizes.sm : AppSizes.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: Text(
                          AppStrings.login,
                          style: (isSmallScreen ? AppTextStyles.buttonMedium : AppTextStyles.buttonLarge).copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom spacer - flexible
                SizedBox(height: isSmallScreen ? AppSizes.lg : AppSizes.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

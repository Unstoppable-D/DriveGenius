import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BackHomeButton extends StatelessWidget {
  final String? label;
  final bool showLabel;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? customRoute;

  const BackHomeButton({
    super.key,
    this.label,
    this.showLabel = true,
    this.icon = Icons.arrow_back,
    this.onPressed,
    this.customRoute,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () => _handleNavigation(context),
      icon: Icon(icon, size: 20),
      label: showLabel 
          ? Text(label ?? 'Back to Home')
          : const SizedBox.shrink(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary.withOpacity(0.1),
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(
            color: AppColors.secondary.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context) {
    // Try to go back if there's navigation history
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Fallback to home route
      Navigator.pushReplacementNamed(
        context, 
        customRoute ?? AppRoutes.home,
      );
    }
  }
}

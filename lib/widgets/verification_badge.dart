import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  final bool showText;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 20.0,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppSizes.xs),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Colors.white,
            size: size * 0.8,
          ),
          if (showText) ...[
            const SizedBox(width: AppSizes.xs),
            Text(
              'Verified',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';

class FooterContact extends StatelessWidget {
  const FooterContact({super.key});

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.lg),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              
              // Phone contact
              InkWell(
                onTap: () => _launchUrl('tel:+2348164171778'),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '+2348164171778',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSizes.sm),
              
              // Email contact
              InkWell(
                onTap: () => _launchUrl('mailto:apexsoftwars9@gmail.com'),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        'apexsoftwars9@gmail.com',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

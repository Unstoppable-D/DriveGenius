import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Earnings Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

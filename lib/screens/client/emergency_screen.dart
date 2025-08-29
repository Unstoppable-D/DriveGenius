import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Emergency Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

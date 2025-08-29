import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class TripManagementScreen extends StatelessWidget {
  const TripManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Management'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Trip Management Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

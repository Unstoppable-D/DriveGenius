import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Requests'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Job Requests Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

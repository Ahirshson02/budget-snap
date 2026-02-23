import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centered loading spinner used across all screens during async operations.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}
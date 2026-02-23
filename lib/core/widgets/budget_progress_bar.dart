import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.allocated,
  });

  final double spent;
  final double allocated;

  double get _progress =>
      allocated <= 0 ? 0 : (spent / allocated).clamp(0.0, 1.0);

  Color _barColor(BuildContext context) {
    if (_progress < 0.7) return AppColors.success;
    if (_progress < 0.9) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    // Bar height scales slightly with screen size: 6px on small, 10px on large
    final barHeight = (context.screenWidth * 0.02).clamp(6.0, 10.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: barHeight,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(_barColor(context)),
      ),
    );
  }
}
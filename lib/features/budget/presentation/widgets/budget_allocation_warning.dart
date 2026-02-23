import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/currency_text.dart';
import '../../domain/models/budget.dart';

/// Shows a warning when category allocations exceed the total budget,
/// or an info chip when there is unallocated budget remaining.
class BudgetAllocationWarning extends StatelessWidget {
  const BudgetAllocationWarning({super.key, required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final unallocated = budget.unallocated;
    final theme       = Theme.of(context);
    final hPad        = context.widthFraction(0.03).clamp(10.0, 16.0);
    final vPad        = context.heightFraction(0.012).clamp(8.0, 14.0);
    final iconSize    = context.widthFraction(0.045).clamp(16.0, 20.0);
    final fontSize    = context.widthFraction(0.032).clamp(11.0, 13.0);

    if (unallocated == 0) return const SizedBox.shrink();

    final isOver        = unallocated < 0;
    final color         = isOver ? AppColors.error : AppColors.success;
    final icon          = isOver
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
    final bgColor       = color.withOpacity(0.08);
    final borderColor   = color.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: vPad,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(width: context.widthFraction(0.02).clamp(6.0, 10.0)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: fontSize,
                  color: color,
                ),
                children: [
                  TextSpan(
                    text: isOver
                        ? 'Over-allocated by '
                        : 'Unallocated: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '\$${unallocated.abs().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: isOver
                        ? '. Reduce category amounts to stay within budget.'
                        : '. Assign remaining funds to a category.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
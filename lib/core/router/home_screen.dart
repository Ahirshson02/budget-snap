import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/budget_progress_bar.dart';
import '../../core/widgets/currency_text.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/budget/domain/models/budget.dart';
import '../../features/budget/domain/models/category.dart';
import '../../features/budget/presentation/providers/budget_notifier.dart';
import '../../features/budget/presentation/providers/budget_state.dart';
import '../../features/budget/presentation/widgets/create_budget_sheet.dart';
import '../widgets/manual_charge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _selectedMonth;
 @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    // Schedule the initial load after the first frame so the
    // provider is fully registered before we call into it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Triggers a fresh load on the notifier for the current month.
  /// Always reads the provider fresh inside this method so it
  /// always targets the correct family instance.
  void _load() {
    ref
        .read(budgetNotifierProvider(_selectedMonth).notifier)
        .loadBudget(_selectedMonth);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
    // Use addPostFrameCallback so setState has completed and the new
    // provider instance exists before we call load on it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _showCreateBudget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => CreateBudgetSheet(month: _selectedMonth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetNotifierProvider(_selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Snap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthSelector(
            month: _selectedMonth,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
          ),
          Expanded(
            child: switch (budgetState) {
              BudgetLoading() || BudgetInitial() =>
                const AppLoadingIndicator(),
              BudgetError(:final message) => AppErrorWidget(
                  message: message,
                  onRetry: _load,
                ),
              BudgetEmpty(:final month) => AppEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No budget yet',
                  subtitle:
                      'Create a budget for ${DateFormat.yMMMM().format(month)}.',
                  actionLabel: 'Create Budget',
                  onAction: _showCreateBudget,
                ),
             BudgetLoaded(:final budget, :final spentPerCategory, :final uncategorizedSpent) =>
              _BudgetOverview(
                budget: budget,
                spentPerCategory: spentPerCategory,
                uncategorizedSpent: uncategorizedSpent,
                onCreateBudget: _showCreateBudget,
                month: _selectedMonth
              ),
            },
          ),
        ],
      ),
      floatingActionButton: budgetState is BudgetEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCreateBudget,
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            )
          : null,
    );
  }
}

// ----------------------------------------------------------------
// Month selector
// ----------------------------------------------------------------

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.heightFraction(0.01).clamp(6.0, 12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrevious,
          ),
          Text(
            DateFormat.yMMMM().format(month),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Budget overview
// ----------------------------------------------------------------
class _BudgetOverview extends StatelessWidget {
  const _BudgetOverview({
    required this.budget,
    required this.spentPerCategory,
    required this.uncategorizedSpent,
    required this.onCreateBudget,
    required this.month,
  });

  final Budget budget;
  final Map<String, double> spentPerCategory;
  final double uncategorizedSpent;
  final VoidCallback onCreateBudget;
  final DateTime month;
  @override
  Widget build(BuildContext context) {
    // Total spent = all categorized spending + uncategorized spending.
    // Previously totalSpent only summed categorized expenses, which
    // made the progress bar and remaining amount inaccurate.
    final categorizedSpent =
        spentPerCategory.values.fold(0.0, (a, b) => a + b);
    final totalSpent = categorizedSpent + uncategorizedSpent;
    final remaining  = budget.totalBudget - totalSpent;
    final theme      = Theme.of(context);
    final hPad       = context.horizontalPadding;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: context.heightFraction(0.015).clamp(8.0, 16.0),
      ),
      children: [
        _SummaryCard(
          budget: budget,
          totalSpent: totalSpent,
          remaining: remaining,
        ),
        SizedBox(height: context.heightFraction(0.02).clamp(8.0, 20.0)),
        Text(
          'Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: context.heightFraction(0.01).clamp(4.0, 10.0)),

        // Categorized spending cards
        if (budget.categories.isEmpty && uncategorizedSpent == 0)
          AppEmptyState(
            icon: Icons.category_outlined,
            title: 'No categories',
            subtitle: 'Go to Budget to add spending categories.',
          )
        else ...[
          ...budget.categories.map(
            (cat) => _CategoryCard(
              category: cat,
              spent: spentPerCategory[cat.id] ?? 0,
              month: month,
            ),
          ),

          // Uncategorized card — only shown when there is uncategorized
          // spending. Displayed last so categorized items appear first.
          if (uncategorizedSpent > 0)
            _UncategorizedCard(amount: uncategorizedSpent, month: month),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.budget,
    required this.totalSpent,
    required this.remaining,
  });

  final Budget budget;
  final double totalSpent;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    // Card inner padding scales with screen width
    final innerPad  = context.widthFraction(0.04).clamp(12.0, 24.0);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            SizedBox(height: context.heightFraction(0.005).clamp(2.0, 6.0)),
            CurrencyText(
              budget.totalBudget,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: context.heightFraction(0.015).clamp(8.0, 16.0)),
            BudgetProgressBar(
              spent: totalSpent,
              allocated: budget.totalBudget,
            ),
            SizedBox(height: context.heightFraction(0.015).clamp(8.0, 16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryChip(
                  label: 'Spent',
                  amount: totalSpent,
                  color: AppColors.error,
                ),
                _SummaryChip(
                  label: 'Remaining',
                  amount: remaining,
                  color: remaining >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        CurrencyText(
          amount,
          style: TextStyle(
            // Font size scales with screen width, clamped to readable range
            fontSize: (context.screenWidth * 0.045).clamp(16.0, 22.0),
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.spent,
    required this.month,
  });

  final Category category;
  final double spent;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final remaining = category.allocatedAmount - spent;
    final theme     = Theme.of(context);
    final innerPad  = context.widthFraction(0.04).clamp(12.0, 20.0);

    return Card(
      margin: EdgeInsets.only(
        bottom: context.heightFraction(0.01).clamp(6.0, 12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) => IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    iconSize: (context.screenWidth * 0.05).clamp(18.0, 22.0),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Add charge',
                    color: AppColors.primary,
                    onPressed: () => showAddManualExpenseDialog(
                      context: context,
                      ref: ref,
                      category: category,
                      month: month
                    ),
                  ),
                ),
                CurrencyText(
                  remaining,
                  style: TextStyle(
                    fontSize: (context.screenWidth * 0.038).clamp(14.0, 18.0),
                    fontWeight: FontWeight.w700,
                    color: remaining >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.heightFraction(0.01).clamp(4.0, 10.0)),
            BudgetProgressBar(spent: spent, allocated: category.allocatedAmount),
            SizedBox(height: context.heightFraction(0.008).clamp(4.0, 8.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.labelSmall,
                    children: [
                      TextSpan(
                        text: '\$${spent.toStringAsFixed(2)}',
                      ),
                      TextSpan(
                        text:
                            ' of \$${category.allocatedAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

/// Displays the total of all expenses that have no category assigned.
///
/// Shows no allocated amount or progress bar because uncategorized
/// spending has no budget ceiling — it is purely informational.
class _UncategorizedCard extends StatelessWidget {
  const _UncategorizedCard({required this.amount, required this.month});

  final double amount;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final innerPad = context.widthFraction(0.04).clamp(12.0, 20.0);

    return Card(
      margin: EdgeInsets.only(
        bottom: context.heightFraction(0.01).clamp(6.0, 12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Row(
          children: [
            // Muted icon distinguishes this from regular category cards
            Container(
              width: context.widthFraction(0.08).clamp(28.0, 40.0),
              height: context.widthFraction(0.08).clamp(28.0, 40.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                size: context.widthFraction(0.045).clamp(16.0, 22.0),
                color: theme.colorScheme.outline,
              ),
            ),
            SizedBox(width: context.widthFraction(0.03).clamp(8.0, 14.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Uncategorized',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) => IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          iconSize: (context.screenWidth * 0.05).clamp(18.0, 22.0),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Add charge',
                          color: AppColors.primary,
                          onPressed: () => showAddManualExpenseDialog(
                            context: context,
                            ref: ref,
                            category: null,
                            month: month
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'No category assigned',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            CurrencyText(
              amount,
              style: TextStyle(
                fontSize: (context.screenWidth * 0.038).clamp(14.0, 18.0),
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
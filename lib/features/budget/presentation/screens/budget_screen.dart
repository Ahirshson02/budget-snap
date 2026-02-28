import 'package:budget_snap/features/budget/presentation/widgets/budget_allocation_warning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/budget_progress_bar.dart';
import '../../../../core/widgets/currency_text.dart';
import '../../domain/models/category.dart';
import '../providers/budget_notifier.dart';
import '../providers/budget_state.dart';
import '../widgets/add_category_sheet.dart';
import '../widgets/create_budget_sheet.dart';
import '../widgets/edit_category_sheet.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    ref
        .read(budgetNotifierProvider(_selectedMonth).notifier)
        .loadBudget(_selectedMonth);
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

  void _showAddCategory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => AddCategorySheet(month: _selectedMonth),
    );
  }

  void _showEditCategory(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => EditCategorySheet(
        month: _selectedMonth,
        category: category,
      ),
    );
  }

  void _showEditTotal(double current) {
    final ctrl =
        TextEditingController(text: current.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Total Budget'),
        content: TextFormField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Total Amount',
            prefixText: '\$',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text);
              if (value != null && value > 0) {
                ref
                    .read(budgetNotifierProvider(_selectedMonth).notifier)
                    .updateBudgetTotal(value);
                Navigator.pop(_);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"? Expenses in this category will become uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(budgetNotifierProvider(_selectedMonth).notifier)
          .deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetNotifierProvider(_selectedMonth));
    final theme       = Theme.of(context);
    final hPad        = context.horizontalPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM().format(_selectedMonth)),
        actions: [
          if (budgetState is BudgetLoaded)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Category',
              onPressed: _showAddCategory,
            ),
        ],
      ),
      body: switch (budgetState) {
        BudgetLoading() || BudgetInitial() => const AppLoadingIndicator(),
        BudgetError(:final message) => AppErrorWidget(
            message: message,
            onRetry: _load,
          ),
        BudgetEmpty(:final month) => AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No budget for this month',
            subtitle:
                'Create a budget for ${DateFormat.yMMMM().format(month)}.',
            actionLabel: 'Create Budget',
            onAction: _showCreateBudget,
          ),
        BudgetLoaded(:final budget, :final spentPerCategory) =>
          ListView(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: context.heightFraction(0.015).clamp(8.0, 16.0),
            ),
            children: [
              // Total budget card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(
                    context.widthFraction(0.04).clamp(12.0, 24.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Budget',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            // In budget_screen.dart ListView children, after the total budget Card:
                            SizedBox(height: context.heightFraction(0.015).clamp(8.0, 16.0)),
                            BudgetAllocationWarning(budget: budget),
                            SizedBox(height: context.heightFraction(0.015).clamp(8.0, 16.0)),
                            SizedBox(
                              height: context.heightFraction(0.005)
                                  .clamp(2.0, 6.0),
                            ),
                            CurrencyText(
                              budget.totalBudget,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '\$${budget.totalAllocated.toStringAsFixed(2)} allocated',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showEditTotal(budget.totalBudget),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: context.heightFraction(0.02).clamp(8.0, 20.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCategory,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              SizedBox(
                height: context.heightFraction(0.01).clamp(4.0, 10.0),
              ),
              if (budget.categories.isEmpty)
                AppEmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories yet',
                  subtitle: 'Add categories to organize your spending.',
                )
              else
                ...budget.categories.map(
                  (cat) => _CategoryTile(
                    category: cat,
                    spent: spentPerCategory[cat.id] ?? 0,
                    onEdit: () => _showEditCategory(cat),
                    onDelete: () => _confirmDeleteCategory(cat),
                  ),
                ),
            ],
          ),
      },
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
// Category tile
// ----------------------------------------------------------------

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(
              height: context.heightFraction(0.008).clamp(4.0, 10.0),
            ),
            BudgetProgressBar(
              spent: spent,
              allocated: category.allocatedAmount,
            ),
            SizedBox(
              height: context.heightFraction(0.008).clamp(4.0, 8.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allocated',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                CurrencyText(
                  category.allocatedAmount,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                CurrencyText(
                  remaining,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: remaining >= 0
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
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
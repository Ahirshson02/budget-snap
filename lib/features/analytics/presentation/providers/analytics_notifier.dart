import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_exception.dart';
import '../../../budget/data/providers/budget_repository_provider.dart';
import '../../../budget/domain/models/budget.dart';
import '../../../budget/domain/repositories/budget_repository.dart';
import '../../../receipt/data/providers/expense_repository_provider.dart';
import '../../../receipt/domain/models/expense.dart';
import '../../../receipt/domain/repositories/expense_repository.dart';
import 'analytics_state.dart';

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({
    required BudgetRepository budgetRepository,
    required ExpenseRepository expenseRepository,
  })  : _budgetRepo = budgetRepository,
        _expenseRepo = expenseRepository,
        super(const AnalyticsState.initial());

  final BudgetRepository _budgetRepo;
  final ExpenseRepository _expenseRepo;

  /// Load analytics for [currentMonth] and the month prior.
  Future<void> loadAnalytics(DateTime currentMonth) async {
    state = const AnalyticsState.loading();

    try {
      final previousMonth = DateTime(
        currentMonth.year,
        currentMonth.month - 1,
      );

      // Fetch both months in parallel.
      final results = await Future.wait([
        _buildMonthSummary(currentMonth),
        _buildMonthSummary(previousMonth),
      ]);

      state = AnalyticsState.loaded(
        currentMonth: results[0],
        previousMonth: results[1].totalSpent > 0 ? results[1] : null,
      );
    } on AppException catch (e) {
      state = AnalyticsState.error(_friendlyMessage(e));
    }
  }

  Future<MonthSummary> _buildMonthSummary(DateTime month) async {
    final budget   = await _budgetRepo.getBudgetByMonth(month);
    final expenses = await _expenseRepo.getExpensesByMonth(month);

    final categoryNames = {
      if (budget != null)
        for (final c in budget.categories) c.id: c.name,
    };

    final Map<String, double> spentByCategory = {};

    for (final expense in expenses) {
      if (expense.categoryId == null) {
        spentByCategory['Uncategorized'] =
            (spentByCategory['Uncategorized'] ?? 0) + expense.total;
        continue;
      }

      final name = categoryNames[expense.categoryId] ?? 'Other';
      spentByCategory[name] = (spentByCategory[name] ?? 0) + expense.total;
    }

    return MonthSummary(
      month: month,
      totalSpent: expenses.fold(0, (sum, e) => sum + e.total),
      totalBudget: budget?.totalBudget ?? 0,
      spentByCategory: spentByCategory,
    );
  }

  String _friendlyMessage(AppException e) => switch (e) {
        UnauthorizedException() => 'Please sign in to continue.',
        ValidationException()   => e.message,
        NotFoundException()     => 'The requested data could not be found.',
        ServerException()       => 'A server error occurred. Please try again.',
        LocalException()        => 'A local error occurred. Please try again.',
      };
}

final analyticsNotifierProvider =
    StateNotifierProvider.autoDispose<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(
    budgetRepository: ref.watch(budgetRepositoryProvider),
    expenseRepository: ref.watch(expenseRepositoryProvider),
  ),
);
import '../models/expense.dart';

/// Contract for all expense persistence operations.
abstract class ExpenseRepository {
  /// Fetch all expenses for the given month, sorted by date descending.
  Future<List<Expense>> getExpensesByMonth(DateTime month);

  /// Fetch a single expense with its line items.
  Future<Expense?> getExpenseById(String expenseId);

  /// Fetch all expenses belonging to a specific category.
  Future<List<Expense>> getExpensesByCategory(String categoryId);

  /// Fetch expenses across all months for analytics.
  /// [limit] caps results to avoid loading unbounded data.
  Future<List<Expense>> getAllExpenses({int limit = 200});

  /// Save a new expense with its line items.
  /// Line items are inserted in a batch after the expense row is created.
  /// Both operations are wrapped in a Supabase transaction.
  Future<Expense> createExpense({
    required DateTime date,
    required double total,
    String? merchant,
    String? categoryId,
    String? comment,
    required List<({String name, double price, String? categoryId})> items,
  });

  /// Update expense-level fields (merchant, date, total, comment, category).
  Future<Expense> updateExpense({
    required String expenseId,
    required DateTime date,
    required double total,
    String? merchant,
    String? categoryId,
    String? comment,
  });

  /// Replace all line items for an expense.
  /// Deletes existing items and inserts the new list atomically.
  Future<Expense> updateExpenseItems({
    required String expenseId,
    required List<({String name, double price, String? categoryId})> items,
  });

  /// Permanently delete an expense and its line items (cascade).
  Future<void> deleteExpense(String expenseId);
}
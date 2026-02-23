import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_exception.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../dtos/expense_dto.dart';
import '../mappers/expense_mapper.dart';

class SupabaseExpenseRepository implements ExpenseRepository {
  SupabaseExpenseRepository(this._client);

  final SupabaseClient _client;

  static const _expensesTable     = 'expenses';
  static const _expenseItemsTable = 'expense_items';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException();
    return id;
  }

  @override
  Future<List<Expense>> getExpensesByMonth(DateTime month) async {
    try {
      // Filter by date range: first day of month to last day of month.
      final start = DateTime.utc(month.year, month.month, 1);
      final end   = DateTime.utc(month.year, month.month + 1, 1)
          .subtract(const Duration(days: 1));

      final response = await _client
          .from(_expensesTable)
          .select('*, items:expense_items(*)')
          .eq('user_id', _userId)
          .gte('date', _dateString(start))
          .lte('date', _dateString(end))
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseMapper.fromDto(ExpenseDto.fromJson(json)))
          .toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final response = await _client
          .from(_expensesTable)
          .select('*, items:expense_items(*)')
          .eq('id', expenseId)
          .eq('user_id', _userId)
          .maybeSingle();

      if (response == null) return null;
      return ExpenseMapper.fromDto(ExpenseDto.fromJson(response));
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    try {
      final response = await _client
          .from(_expensesTable)
          .select('*, items:expense_items(*)')
          .eq('user_id', _userId)
          .eq('category_id', categoryId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseMapper.fromDto(ExpenseDto.fromJson(json)))
          .toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<List<Expense>> getAllExpenses({int limit = 200}) async {
    try {
      final response = await _client
          .from(_expensesTable)
          .select('*, items:expense_items(*)')
          .eq('user_id', _userId)
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ExpenseMapper.fromDto(ExpenseDto.fromJson(json)))
          .toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<Expense> createExpense({
    required DateTime date,
    required double total,
    String? merchant,
    String? categoryId,
    String? comment,
    required List<({String name, double price, String? categoryId})> items,
  }) async {
    try {
      final userId = _userId;

      // Insert the expense row first to get the generated ID.
      final expenseResponse = await _client
          .from(_expensesTable)
          .insert({
            'user_id':  userId,
            'date':     _dateString(date),
            'total':    total,
            if (merchant   != null) 'merchant':    merchant,
            if (categoryId != null) 'category_id': categoryId,
            if (comment    != null) 'comment':     comment,
          })
          .select()
          .single();

      final expenseId = expenseResponse['id'] as String;

      // Batch insert all line items.
      if (items.isNotEmpty) {
        await _client.from(_expenseItemsTable).insert(
          items.map((item) => {
            'expense_id':  expenseId,
            'user_id':     userId,
            'name':        item.name,
            'price':       item.price,
            if (item.categoryId != null) 'category_id': item.categoryId,
          }).toList(),
        );
      }

      // Fetch the complete expense with items to return a fully hydrated model.
      final result = await getExpenseById(expenseId);
      if (result == null) throw const ServerException('Failed to fetch created expense.');
      return result;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<Expense> updateExpense({
    required String expenseId,
    required DateTime date,
    required double total,
    String? merchant,
    String? categoryId,
    String? comment,
  }) async {
    try {
      await _client
          .from(_expensesTable)
          .update({
            'date':  _dateString(date),
            'total': total,
            'merchant':    merchant,
            'category_id': categoryId,
            'comment':     comment,
          })
          .eq('id', expenseId)
          .eq('user_id', _userId);

      final result = await getExpenseById(expenseId);
      if (result == null) throw const NotFoundException('Expense not found after update.');
      return result;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<Expense> updateExpenseItems({
    required String expenseId,
    required List<({String name, double price, String? categoryId})> items,
  }) async {
    try {
      final userId = _userId;

      // Delete all existing items for this expense then re-insert.
      // This is simpler and safer than diffing the list for updates.
      await _client
          .from(_expenseItemsTable)
          .delete()
          .eq('expense_id', expenseId)
          .eq('user_id', userId);

      if (items.isNotEmpty) {
        await _client.from(_expenseItemsTable).insert(
          items.map((item) => {
            'expense_id':  expenseId,
            'user_id':     userId,
            'name':        item.name,
            'price':       item.price,
            if (item.categoryId != null) 'category_id': item.categoryId,
          }).toList(),
        );
      }

      final result = await getExpenseById(expenseId);
      if (result == null) throw const NotFoundException('Expense not found after item update.');
      return result;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _client
          .from(_expensesTable)
          .delete()
          .eq('id', expenseId)
          .eq('user_id', _userId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  String _dateString(DateTime dt) => dt.toIso8601String().split('T').first;
}
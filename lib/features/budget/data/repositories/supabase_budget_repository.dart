import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/app_exception.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/budget_repository.dart';
import '../dtos/budget_dto.dart';
import '../dtos/category_dto.dart';
import '../mappers/budget_mapper.dart';

/// Supabase implementation of [BudgetRepository].
///
/// All Supabase calls are wrapped in try/catch and re-thrown as typed
/// [AppException] subclasses. This keeps Supabase's exception types
/// from leaking into the domain or presentation layers.
class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  // Table name constants — single source of truth, no magic strings.
  static const _budgetsTable    = 'budgets';
  static const _categoriesTable = 'categories';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException();
    return id;
  }

  // ----------------------------------------------------------------
  // Budget operations
  // ----------------------------------------------------------------

  @override
  Future<Budget?> getBudgetByMonth(DateTime month) async {
    try {
      final normalized = _firstOfMonth(month);

      // Fetch budget with nested categories in a single query.
      // Supabase supports PostgREST resource embedding via the
      // 'categories(*)' syntax — returns categories as a nested array.
      final response = await _client
          .from(_budgetsTable)
          .select('*, categories(*)')
          .eq('user_id', _userId)
          .eq('month', _dateString(normalized))
          .maybeSingle();

      if (response == null) return null;

      final dto = BudgetDto.fromJson(response);
      return BudgetMapper.fromDto(dto);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<List<Budget>> getAllBudgets() async {
    try {
      final response = await _client
          .from(_budgetsTable)
          .select('*, categories(*)')
          .eq('user_id', _userId)
          .order('month', ascending: false);

      return (response as List)
          .map((json) => BudgetMapper.fromDto(BudgetDto.fromJson(json)))
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
  Future<Budget> createBudget({
    required DateTime month,
    required double totalBudget,
  }) async {
    try {
      final userId     = _userId;
      final normalized = _firstOfMonth(month);

      // Check uniqueness manually before insert to give a clear error.
      // The DB constraint will also catch this, but the PostgrestException
      // message is less readable for the UI layer.
      final existing = await getBudgetByMonth(normalized);
      if (existing != null) {
        throw ValidationException(
          'A budget for ${_dateString(normalized)} already exists.',
        );
      }

      final response = await _client
          .from(_budgetsTable)
          .insert({
            'user_id':      userId,
            'month':        _dateString(normalized),
            'total_budget': totalBudget,
          })
          .select('*, categories(*)')
          .single();

      return BudgetMapper.fromDto(BudgetDto.fromJson(response));
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<Budget> updateBudget({
    required String budgetId,
    required double totalBudget,
  }) async {
    try {
      final response = await _client
          .from(_budgetsTable)
          .update({'total_budget': totalBudget})
          .eq('id', budgetId)
          .eq('user_id', _userId) // RLS belt-and-suspenders check
          .select('*, categories(*)')
          .single();

      return BudgetMapper.fromDto(BudgetDto.fromJson(response));
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _client
          .from(_budgetsTable)
          .delete()
          .eq('id', budgetId)
          .eq('user_id', _userId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  // ----------------------------------------------------------------
  // Category operations
  // ----------------------------------------------------------------

  @override
  Future<Category> createCategory({
    required String budgetId,
    required String name,
    required double allocatedAmount,
    String? colorHex,
  }) async {
    try {
      final response = await _client
          .from(_categoriesTable)
          .insert({
            'budget_id':        budgetId,
            'user_id':          _userId,
            'name':             name,
            'allocated_amount': allocatedAmount,
            if (colorHex != null) 'color_hex': colorHex,
          })
          .select()
          .single();

      return CategoryMapper.fromDto(CategoryDto.fromJson(response));
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    required double allocatedAmount,
    String? colorHex,
  }) async {
    try {
      final response = await _client
          .from(_categoriesTable)
          .update({
            'name':             name,
            'allocated_amount': allocatedAmount,
            if (colorHex != null) 'color_hex': colorHex,
          })
          .eq('id', categoryId)
          .eq('user_id', _userId)
          .select()
          .single();

      return CategoryMapper.fromDto(CategoryDto.fromJson(response));
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _client
          .from(_categoriesTable)
          .delete()
          .eq('id', categoryId)
          .eq('user_id', _userId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw LocalException(e.toString());
    }
  }

  // ----------------------------------------------------------------
  // Private helpers
  // ----------------------------------------------------------------

  DateTime _firstOfMonth(DateTime dt) => DateTime.utc(dt.year, dt.month, 1);

  String _dateString(DateTime dt) => dt.toIso8601String().split('T').first;
}
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../dtos/budget_dto.dart';
import '../dtos/category_dto.dart';

/// Converts between [BudgetDto] (Supabase data) and [Budget] (domain).
abstract class BudgetMapper {
  /// DTO → Domain
  static Budget fromDto(BudgetDto dto) {
    return Budget(
      id: dto.id,
      userId: dto.userId,
      // Parse "2024-03-01" → DateTime. Always UTC to avoid timezone drift.
      month: DateTime.parse(dto.month).toUtc(),
      totalBudget: dto.totalBudget,
      categories: dto.categories.map(CategoryMapper.fromDto).toList(),
      createdAt: DateTime.parse(dto.createdAt).toUtc(),
      updatedAt: DateTime.parse(dto.updatedAt).toUtc(),
    );
  }

  /// Domain → Map for Supabase insert/update.
  /// We omit id on insert (Supabase generates it) and omit timestamps
  /// (handled by DB defaults and triggers).
  static Map<String, dynamic> toInsertMap(Budget budget) {
    return {
      'user_id':      budget.userId,
      // Normalize to first of month before storing
      'month':        _firstOfMonth(budget.month).toIso8601String().split('T').first,
      'total_budget': budget.totalBudget,
    };
  }

  static Map<String, dynamic> toUpdateMap(Budget budget) {
    return {
      'total_budget': budget.totalBudget,
    };
  }

  static DateTime _firstOfMonth(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, 1);
}

abstract class CategoryMapper {
  /// DTO → Domain
  static Category fromDto(CategoryDto dto) {
    return Category(
      id: dto.id,
      budgetId: dto.budgetId,
      userId: dto.userId,
      name: dto.name,
      allocatedAmount: dto.allocatedAmount,
      colorHex: dto.colorHex,
      createdAt: DateTime.parse(dto.createdAt).toUtc(),
      updatedAt: DateTime.parse(dto.updatedAt).toUtc(),
    );
  }

  /// Domain → Map for Supabase insert.
  static Map<String, dynamic> toInsertMap(Category category) {
    return {
      'budget_id':        category.budgetId,
      'user_id':          category.userId,
      'name':             category.name,
      'allocated_amount': category.allocatedAmount,
      if (category.colorHex != null) 'color_hex': category.colorHex,
    };
  }

  static Map<String, dynamic> toUpdateMap(Category category) {
    return {
      'name':             category.name,
      'allocated_amount': category.allocatedAmount,
      if (category.colorHex != null) 'color_hex': category.colorHex,
    };
  }
}
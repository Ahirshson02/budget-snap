import '../../domain/models/expense.dart';
import '../../domain/models/expense_item.dart';
import '../dtos/expense_dto.dart';
import '../dtos/expense_item_dto.dart';

abstract class ExpenseMapper {
  /// DTO → Domain
  static Expense fromDto(ExpenseDto dto) {
    return Expense(
      id: dto.id,
      userId: dto.userId,
      categoryId: dto.categoryId,
      merchant: dto.merchant,
      date: DateTime.parse(dto.date).toUtc(),
      total: dto.total,
      comment: dto.comment,
      items: dto.items.map(ExpenseItemMapper.fromDto).toList(),
      createdAt: DateTime.parse(dto.createdAt).toUtc(),
      updatedAt: DateTime.parse(dto.updatedAt).toUtc(),
    );
  }

  /// Domain → Map for Supabase insert.
  static Map<String, dynamic> toInsertMap(Expense expense) {
    return {
      'user_id':     expense.userId,
      if (expense.categoryId != null) 'category_id': expense.categoryId,
      if (expense.merchant   != null) 'merchant':    expense.merchant,
      'date':    expense.date.toIso8601String().split('T').first,
      'total':   expense.total,
      if (expense.comment != null) 'comment': expense.comment,
    };
  }

  static Map<String, dynamic> toUpdateMap(Expense expense) {
    return {
      if (expense.categoryId != null) 'category_id': expense.categoryId,
      if (expense.merchant   != null) 'merchant':    expense.merchant,
      'date':  expense.date.toIso8601String().split('T').first,
      'total': expense.total,
      if (expense.comment != null) 'comment': expense.comment,
    };
  }
}

abstract class ExpenseItemMapper {
  static ExpenseItem fromDto(ExpenseItemDto dto) {
    return ExpenseItem(
      id: dto.id,
      expenseId: dto.expenseId,
      userId: dto.userId,
      categoryId: dto.categoryId,
      name: dto.name,
      price: dto.price,
      createdAt: DateTime.parse(dto.createdAt).toUtc(),
    );
  }

  static Map<String, dynamic> toInsertMap(ExpenseItem item) {
    return {
      'expense_id':  item.expenseId,
      'user_id':     item.userId,
      if (item.categoryId != null) 'category_id': item.categoryId,
      'name':  item.name,
      'price': item.price,
    };
  }
}
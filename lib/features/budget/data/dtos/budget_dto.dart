import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/budget.dart';
import 'category_dto.dart';

part 'budget_dto.freezed.dart';
part 'budget_dto.g.dart';

/// Data Transfer Object for the `budgets` Supabase table.
///
/// Supabase returns snake_case column names and ISO 8601 date strings.
/// This class owns the JSON deserialization so the domain model stays clean.
///
/// When fetching a budget with its categories, Supabase returns a nested
/// array under the key 'categories' (via a foreign table join). That's
/// why [categories] is included here with a default of empty list.
@freezed
class BudgetDto with _$BudgetDto {
  const factory BudgetDto({
    required String id,
    @JsonKey(name: 'user_id')    required String userId,
    required String month,       // ISO date string: "2024-03-01"
    @JsonKey(name: 'total_budget') required double totalBudget,
    @Default([]) List<CategoryDto> categories,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _BudgetDto;

  factory BudgetDto.fromJson(Map<String, dynamic> json) =>
      _$BudgetDtoFromJson(json);
}
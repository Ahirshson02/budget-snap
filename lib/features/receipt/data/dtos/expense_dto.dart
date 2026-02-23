import 'package:freezed_annotation/freezed_annotation.dart';
import 'expense_item_dto.dart';

part 'expense_dto.freezed.dart';
part 'expense_dto.g.dart';

@freezed
class ExpenseDto with _$ExpenseDto {
  const factory ExpenseDto({
    required String id,
    @JsonKey(name: 'user_id')     required String userId,
    @JsonKey(name: 'category_id') String? categoryId,
    String? merchant,
    required String date,
    required double total,
    String? comment,
    @Default([]) List<ExpenseItemDto> items,
    @JsonKey(name: 'created_at')  required String createdAt,
    @JsonKey(name: 'updated_at')  required String updatedAt,
  }) = _ExpenseDto;

  factory ExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseDtoFromJson(json);
}
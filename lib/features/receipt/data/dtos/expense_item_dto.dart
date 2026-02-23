import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_item_dto.freezed.dart';
part 'expense_item_dto.g.dart';

@freezed
class ExpenseItemDto with _$ExpenseItemDto {
  const factory ExpenseItemDto({
    required String id,
    @JsonKey(name: 'expense_id')  required String expenseId,
    @JsonKey(name: 'user_id')     required String userId,
    @JsonKey(name: 'category_id') String? categoryId,
    required String name,
    required double price,
    @JsonKey(name: 'created_at')  required String createdAt,
  }) = _ExpenseItemDto;

  factory ExpenseItemDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseItemDtoFromJson(json);
}
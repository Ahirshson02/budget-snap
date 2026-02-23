import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/category.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

@freezed
class CategoryDto with _$CategoryDto {
  const factory CategoryDto({
    required String id,
    @JsonKey(name: 'budget_id')        required String budgetId,
    @JsonKey(name: 'user_id')          required String userId,
    required String name,
    @JsonKey(name: 'allocated_amount') required double allocatedAmount,
    @JsonKey(name: 'color_hex')        String? colorHex,
    @JsonKey(name: 'created_at')       required String createdAt,
    @JsonKey(name: 'updated_at')       required String updatedAt,
  }) = _CategoryDto;

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);
}
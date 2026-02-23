import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// A spending category within a [Budget].
///
/// [colorHex] is optional — if null the UI assigns a color from
/// [AppColors.chartPalette] by index. Storing it allows users to
/// customize chart colors in a future iteration.
///
/// [isCustom] is a derived convenience flag: predefined categories
/// are seeded from [PredefinedCategory] values; user-created ones
/// are not. We do not store this in the DB — it's inferred from
/// whether the name matches a predefined value.
@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String budgetId,
    required String userId,
    required String name,
    required double allocatedAmount,
    String? colorHex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Category;

  bool get isCustom => !PredefinedCategory.names.contains(name);
}

/// Canonical list of predefined category names.
///
/// Stored as an enum so the compiler catches typos. The [label]
/// getter is what gets written to the database and shown in the UI.
enum PredefinedCategory {
  food,
  gas,
  insurance,
  utilities,
  rent,
  healthcare,
  entertainment,
  clothing,
  savings,
  transport,
  education,
  subscriptions;

  String get label => switch (this) {
        food          => 'Food',
        gas           => 'Gas',
        insurance     => 'Insurance',
        utilities     => 'Utilities',
        rent          => 'Rent',
        healthcare    => 'Healthcare',
        entertainment => 'Entertainment',
        clothing      => 'Clothing',
        savings       => 'Savings',
        transport     => 'Transport',
        education     => 'Education',
        subscriptions => 'Subscriptions',
      };

  /// The set of all predefined label strings.
  /// Used by [Category.isCustom] to detect user-created categories.
  static Set<String> get names =>
      PredefinedCategory.values.map((e) => e.label).toSet();
}
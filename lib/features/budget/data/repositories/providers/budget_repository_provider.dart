import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_provider.dart';
import '../../../domain/repositories/budget_repository.dart';
import '../../repositories/supabase_budget_repository.dart';

/// Provides the [BudgetRepository] implementation to the Riverpod tree.
///
/// To swap implementations (e.g. for testing), override this provider
/// in your test's ProviderScope:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     budgetRepositoryProvider.overrideWithValue(MockBudgetRepository()),
///   ],
/// )
/// ```
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseBudgetRepository(client);
});
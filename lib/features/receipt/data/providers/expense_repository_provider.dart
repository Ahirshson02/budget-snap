import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../domain/repositories/expense_repository.dart';
import '../repositories/supabase_expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseExpenseRepository(client);
});
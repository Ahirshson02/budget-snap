import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  // Must be called before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase once at app startup.
  // The client becomes available anywhere via Supabase.instance.client,
  // but we'll wrap it in a Riverpod provider so it's testable.
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    // ProviderScope is the Riverpod root — must wrap the entire app.
    const ProviderScope(
      child: BudgetSnap(),
    ),
  );
}

class BudgetSnap extends StatelessWidget {
  const BudgetSnap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Budget Snap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
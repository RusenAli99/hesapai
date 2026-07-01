import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'views/auth/login_view.dart';
import 'views/navigation/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Turkish locale date formatting
  await initializeDateFormatting('tr_TR', null);

  // Try initializing Firebase (will fall back to Offline Mode if configuration files are missing)
  try {
    await Firebase.initializeApp();
    AppConfig.firebaseInitialized = true;
    print("YazGeç: Firebase initialized successfully.");
  } catch (e) {
    AppConfig.firebaseInitialized = false;
    print("YazGeç: Running in Offline Mode. Firebase could not initialize: $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'YazGeç',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainNavigationView();
          }
          return const LoginView();
        },
        loading: () => const SplashView(),
        error: (err, stack) => const LoginView(),
      ),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

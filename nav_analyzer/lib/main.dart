import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/repositories/portfolio_repository.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: NavAnalyzerApp(),
    ),
  );
}

/// Root application widget.
class NavAnalyzerApp extends ConsumerStatefulWidget {
  const NavAnalyzerApp({super.key});

  @override
  ConsumerState<NavAnalyzerApp> createState() => _NavAnalyzerAppState();
}

class _NavAnalyzerAppState extends ConsumerState<NavAnalyzerApp> {
  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    final portfolioRepo = ref.read(portfolioRepositoryProvider);
    await portfolioRepo.init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(darkModeProvider);

    return MaterialApp(
      title: 'NAV Analyzer',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'RobotoMono',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.1),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}

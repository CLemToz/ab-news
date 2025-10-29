import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reels/reels_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final themeProvider = await ThemeProvider.create();
  runApp(NewsApp(themeProvider: themeProvider));
}

class NewsApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const NewsApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeProvider,
        builder: (context, themeMode, child) {
          return MaterialApp(
            title: 'DA News Plus',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: AuthWrapper(themeProvider: themeProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AuthWrapper({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return authProvider.isAuthenticated
        ? Shell(themeProvider: themeProvider)
        : const AuthScreen();
  }
}

class Shell extends StatefulWidget {
  final ThemeProvider themeProvider;

  const Shell({super.key, required this.themeProvider});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  late final _pages = [
    const HomeScreen(),
    const CategoriesScreen(),
    const ReelsScreen(),
    const SearchScreen(),
    SettingsScreen(themeProvider: widget.themeProvider),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Categories'),
          NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle),
              label: 'Reels'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

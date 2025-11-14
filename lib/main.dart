
import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // safe to keep if you use elsewhere

import 'features/auth/login_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reels/reels_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

// ⬇️ new: global app settings (font size + theme persistence)
import 'services/app_settings.dart';

// ⬇️ added Firebase core + push service
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';

void main() {
  // Run the app initialization widget
  runApp(const AppInitializer());
}

/// This is the new root widget. It handles all async initialization
/// and shows a loading screen or an error screen.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // Using a Future to track the initialization state
  Future<ThemeProvider>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Start the initialization process
    _initializationFuture = _initializeApp();
  }

  /// All startup logic is now here.
  Future<ThemeProvider> _initializeApp() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Check connectivity first.
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No Internet Connection');
      }

      // 2. Initialize Firebase.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 3. Initialize other services.
      await PushService.instance.init();
      await AppSettings.I.load();

      // 4. Create the theme provider.
      final themeProvider = await ThemeProvider.create();

      return themeProvider;
    } catch (e) {
      // If any step fails, we re-throw the error to be caught by the FutureBuilder.
      debugPrint("App initialization failed: $e");
      rethrow;
    }
  }

  /// This function is called when the user presses the 'Retry' button.
  void _retryInitialization() {
    setState(() {
      _initializationFuture = _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeProvider>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Case 1: An error occurred during initialization
        if (snapshot.hasError) {
          return MaterialApp(
            home: NoNetworkScreen(onRetry: _retryInitialization),
            debugShowCheckedModeBanner: false,
          );
        }

        // Case 2: Initialization was successful
        if (snapshot.connectionState == ConnectionState.done) {
          // Launch the main app
          return NewsApp(themeProvider: snapshot.data!);
        }

        // Case 3: Still initializing, show a loading spinner
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/DA News Plus.jpg',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DA News Plus',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class NewsApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const NewsApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever user changes font size or theme in Settings
    return AnimatedBuilder(
      animation: AppSettings.I,
      builder: (context, _) {
        return MaterialApp(
          title: 'DA News Plus',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppSettings.I.themeMode,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(AppSettings.I.fontScale),
              ),
              child: child!,
            );
          },
          // The main app shell is now the home
          home: Shell(themeProvider: themeProvider),
          debugShowCheckedModeBanner: false,
        );
      },
    );
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

  late final _pages = <Widget>[
    const HomeScreen(),
    const CategoriesScreen(),
    const ReelsScreen(),
    const SearchScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

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
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Reels',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// This screen is now used globally by the AppInitializer
class NoNetworkScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const NoNetworkScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'No Internet Connection',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

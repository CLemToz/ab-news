import 'package:ab_news/services/notification_service.dart';
import 'package:ab_news/widgets/login_popup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart'; // safe to keep if you use elsewhere
import 'package:shared_preferences/shared_preferences.dart';
import 'features/categories/categories_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reels/reels_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

// ⬇️ new: global app settings (font size + theme persistence)
import 'services/app_settings.dart';

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notification = message.notification;
  final android = message.notification?.android;
  if (notification != null && android != null) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'new_post_channel',
            'New Posts',
            channelDescription: 'Notifications for new posts.',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set the background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService().init();

  // keep your provider boot; harmless even if theme comes from AppSettings
  final themeProvider = await ThemeProvider.create();

  // load saved font scale + theme mode
  await AppSettings.I.load();

  runApp(NewsApp(themeProvider: themeProvider));
}

class NewsApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const NewsApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever user changes font size or theme in Settings
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return AnimatedBuilder(
          animation: AppSettings.I,
          builder: (context, _) {
            return MaterialApp(
              title: 'DA News Plus',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,

              // ⬇️ Use the theme selected in Settings (System/Light/Dark)
              // If you prefer your ThemeProvider sometimes, you can merge:
              // themeMode: AppSettings.I.themeMode == ThemeMode.system
              //     ? themeProvider.value
              //     : AppSettings.I.themeMode,
              themeMode: AppSettings.I.themeMode,

              // ⬇️ Apply global text scale from Settings (0.85–1.40)
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: TextScaler.linear(AppSettings.I.fontScale),
                  ),
                  child: child!,
                );
              },

              home: Shell(themeProvider: themeProvider),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      }
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
    // ⬇️ SettingsScreen no longer needs ThemeProvider
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool loginSkipped = prefs.getBool('loginSkipped') ?? false;

    if (!loginSkipped) {
      // It's the first launch, show the login popup.
      Future.microtask(() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const LoginPopup();
        },
      ));
    }
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

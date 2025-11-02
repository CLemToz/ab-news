import 'dart:io';
import 'package:flutter/material.dart';

// ===== YOUR EXISTING IMPORTS =====
import 'package:provider/provider.dart';
import 'features/categories/categories_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reels/reels_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

// ====== FCM + LOCAL NOTIFICATIONS ======
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


// For notification push
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/notifications_store.dart';
import 'features/category_news/wp_article_screen.dart';
import 'services/wp_api.dart';
import 'models/wp_post.dart';


/// Local notifications plugin + channel (Android)
final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel _newsChannel = AndroidNotificationChannel(
  'news_channel',
  'News',
  description: 'Breaking / recent news alerts',
  importance: Importance.high,
);

/// Initialize local notifications (big image support on Android)
Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const init = InitializationSettings(android: androidInit, iOS: iosInit);

  await _flnp.initialize(
    init,
    // If you want to deep-link later, read resp.payload here
    onDidReceiveNotificationResponse: (resp) {},
  );

  // Create channel on Android
  await _flnp
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_newsChannel);
}

Future<String> _downloadToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {}
  return '';
}

/// Show a rich notification from a RemoteMessage
Future<void> _showRich(RemoteMessage m) async {
  final String title = m.notification?.title ?? m.data['title'] ?? 'News';
  final String body = m.notification?.body ?? m.data['body'] ?? '';
  final String imageUrl =
      m.data['image'] ?? m.notification?.android?.imageUrl ?? '';

  AndroidBitmap<Object>? largeIcon;
  if (imageUrl.isNotEmpty) {
    final base64 = await _downloadToBase64(imageUrl);
    if (base64.isNotEmpty) {
      largeIcon = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }

  final android = AndroidNotificationDetails(
    _newsChannel.id,
    _newsChannel.name,
    channelDescription: _newsChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    largeIcon: largeIcon,
  );

  await _flnp.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(android: android),
    payload: m.data['postId'] ?? m.data['link'],
  );
}

/// Background handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _initLocalNotifications();
  await _showRich(message);
}

Future<void> _initFcm() async {
  // Ask permission (Android 13+/iOS)
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission(alert: true, badge: true, sound: true);

  // Subscribe all devices to a topic you’ll publish to from WordPress
  await fcm.subscribeToTopic('news');

  // Handle messages in foreground
  FirebaseMessaging.onMessage.listen((m) => _showRich(m));

  // When app is opened from a terminated state by tapping a notification
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    await _showRich(initial); // or deep-link instead
  }

  // Taps when app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((m) {
    // TODO: deep-link to article screen using m.data['postId'] or m.data['link']
  });

  // Background/terminated processing
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ======= ADD: Firebase + notifications bootstrap =======
  await Firebase.initializeApp();
  await _initLocalNotifications();
  await _initFcm();
  // =======================================================

  final themeProvider = await ThemeProvider.create();
  runApp(NewsApp(themeProvider: themeProvider));
}

class NewsApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const NewsApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeProvider,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'DA News Plus',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
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

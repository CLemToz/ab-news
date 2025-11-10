// lib/services/push_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_store.dart';
import '../models/app_notification.dart';
import '../services/wp_api.dart';
import '../models/wp_post.dart';
import '../features/category_news/wp_article_screen.dart';
import '../features/home/home_screen.dart'; // fallback

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  // Optional: foreground banner for in-app messages
  final fln.FlutterLocalNotificationsPlugin _local =
  fln.FlutterLocalNotificationsPlugin();

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // iOS/Android 13+ permission prompt
    await _fm.requestPermission(alert: true, badge: true, sound: true);

    // Android: init a default local channel for foreground banners
    const androidInit = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = fln.DarwinInitializationSettings();
    await _local.initialize(
      const fln.InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) async {
        // If you later show purely-local notifications with payloads, handle routing here.
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          // Not used in this setup.
        }
      },
    );

    // Subscribe to the topic your WP plugin targets
    await _fm.subscribeToTopic('all');

    // Foreground messages (while app is open)
    FirebaseMessaging.onMessage.listen((m) async {
      // Save so it appears in Notifications screen even if user ignores banner
      await _saveToInbox(m);
      // Optional: show local banner for foreground
      await _showForegroundBanner(m);
    });

    // Tray tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((m) async {
      await _saveToInbox(m);
      await _routeFromMessage(m);
    });

    // Tray tap when app cold-starts
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      // Give UI time to mount before routing (Navigator available)
      unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () async {
        await _saveToInbox(initial);
        await _routeFromMessage(initial);
      }));
    }
  }

  // ----- Helpers -----

  Future<void> _showForegroundBanner(RemoteMessage m) async {
    final title = m.notification?.title ?? m.data['title'] ?? 'DA News Plus';
    final body  = m.notification?.body  ?? m.data['body']  ?? '';

    const androidDetails = fln.AndroidNotificationDetails(
      'default',
      'Default',
      importance: fln.Importance.high,
      priority: fln.Priority.high,
    );
    const iosDetails = fln.DarwinNotificationDetails();

    await _local.show(
      DateTime.now().millisecondsSinceEpoch % 1000000,
      title,
      body,
      const fln.NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> _saveToInbox(RemoteMessage m) async {
    // Prefer DATA keys from your WP plugin (post_id, link, title, body, image)
    final d = m.data;

    // Use WP post_id as the stable record id if available; else fallback to FCM id / timestamp
    final postIdStr = (d['post_id'] ?? d['postId'] ?? '').toString();
    final fallbackId =
        m.messageId ?? '${DateTime.now().millisecondsSinceEpoch}';
    final notifId = postIdStr.isNotEmpty ? postIdStr : fallbackId;

    final title = (d['title'] ?? m.notification?.title ?? '').toString();
    final body  = (d['body']  ?? m.notification?.body  ?? '').toString();
    final image = (d['image'] ?? '').toString();
    final link  = (d['link']  ?? '').toString();

    final int? postId = int.tryParse(postIdStr);

    final n = AppNotification(
      id: notifId,
      title: title.isNotEmpty ? title : 'DA News Plus',
      body: body,
      image: image.isNotEmpty ? image : null,
      link: link.isNotEmpty ? link : null,
      postId: postId,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      read: false,
    );

    await NotificationStore.upsert(n);
  }

  Future<void> _routeFromMessage(RemoteMessage m) async {
    // We don’t have a BuildContext here. Use a global navigatorKey.
    final navigator = _rootNavigatorKey.currentState;
    if (navigator == null) return;

    final d = m.data;
    final postIdStr = (d['post_id'] ?? d['postId'] ?? '').toString();
    final link = (d['link'] ?? '').toString();

    // 1) Try to open in-app article by postId using single-post endpoint
    final int? postId = int.tryParse(postIdStr);
    if (postId != null && postId > 0) {
      try {
        final WPPost post = await WpApi.fetchPostById(postId);
        navigator.push(
          MaterialPageRoute(builder: (_) => WpArticleScreen(post: post)),
        );
        return;
      } catch (_) {
        // fall through to link
      }
    }

    // 2) Fallback: open the permalink in the browser
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 3) Last resort → land on Home
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (r) => false,
    );
  }
}

// A global navigatorKey so PushService can navigate without a BuildContext
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

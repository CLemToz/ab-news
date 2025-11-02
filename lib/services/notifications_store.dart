import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Local app notification model
class AppNotification {
  final String id;           // unique (FCM messageId or generated)
  final String title;
  final String body;
  final String? image;
  final String? link;        // permalink (prefer)
  final int? postId;         // WP post id (fallback)
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    this.link,
    this.postId,
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({bool? read}) =>
      AppNotification(
        id: id,
        title: title,
        body: body,
        image: image,
        link: link,
        postId: postId,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'image': image,
    'link': link,
    'postId': postId,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    title: (j['title'] ?? '') as String,
    body: (j['body'] ?? '') as String,
    image: j['image'] as String?,
    link: j['link'] as String?,
    postId: j['postId'] is int ? j['postId'] as int : int.tryParse('${j['postId']}'),
    createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
    read: j['read'] == true,
  );
}

class NotificationsStore {
  NotificationsStore._();
  static final instance = NotificationsStore._();

  static const _key = 'notifications_v1';
  final ValueNotifier<bool> hasUnread = ValueNotifier<bool>(false);

  List<AppNotification> _items = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    _items = raw
        .map((s) => AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _syncUnreadFlag();
  }

  List<AppNotification> all() => List.unmodifiable(_items);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _items.map((n) => jsonEncode(n.toJson())).toList(),
    );
    _syncUnreadFlag();
  }

  void _syncUnreadFlag() {
    hasUnread.value = _items.any((n) => !n.read);
  }

  Future<void> add(AppNotification n) async {
    // de-dupe by id
    _items.removeWhere((x) => x.id == n.id);
    _items.insert(0, n);
    await _persist();
  }

  /// Convenient helper for FCM messages
  Future<void> addFromRemoteMessage(RemoteMessage m) async {
    final data = m.data;
    await add(
      AppNotification(
        id: m.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: m.notification?.title ?? data['title'] ?? 'News',
        body: m.notification?.body ?? data['body'] ?? '',
        image: data['image'] ?? m.notification?.android?.imageUrl,
        link: data['link'],
        postId: data['postId'] != null ? int.tryParse('${data['postId']}') : null,
        read: false,
      ),
    );
  }

  Future<void> markAllRead() async {
    _items = _items.map((n) => n.copyWith(read: true)).toList();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((n) => n.id == id);
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    await _persist();
  }
}

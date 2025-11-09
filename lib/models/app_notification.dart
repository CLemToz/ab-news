import 'dart:convert';

/// AppNotification represents one push/entry shown in your Notifications screen.
class AppNotification {
  /// Unique id for this notification (use postId-timestamp or FCM messageId).
  final String id;

  final String title;
  final String body;

  /// Optional hero/featured image url from the post.
  final String? image;

  /// Link back to WP post or deep-link in app.
  final String? link;

  /// Optional WP post/category metadata (if provided by your server)
  final int? postId;
  final int? catId;
  final String? catName;

  /// Unix seconds or millis (both accepted). Stored normalized to seconds.
  final int timestampSec;

  /// Whether user has opened this notification in-app.
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    this.link,
    this.postId,
    this.catId,
    this.catName,
    required this.timestampSec,
    this.read = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? image,
    String? link,
    int? postId,
    int? catId,
    String? catName,
    int? timestampSec,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      image: image ?? this.image,
      link: link ?? this.link,
      postId: postId ?? this.postId,
      catId: catId ?? this.catId,
      catName: catName ?? this.catName,
      timestampSec: timestampSec ?? this.timestampSec,
      read: read ?? this.read,
    );
  }

  /// Accepts either seconds or milliseconds in input JSON and normalizes to seconds.
  static int _normTs(dynamic v) {
    if (v == null) return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final num n = (v is String) ? num.tryParse(v) ?? 0 : (v as num);
    if (n > 20000000000) return (n ~/ 1000); // ms -> s
    return n.toInt();
  }

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    body: (j['body'] ?? '').toString(),
    image: (j['image'] as String?)?.trim(),
    link: (j['link'] as String?)?.trim(),
    postId: j['post_id'] == null ? null : int.tryParse('${j['post_id']}'),
    catId: j['cat_id'] == null ? null : int.tryParse('${j['cat_id']}'),
    catName: (j['cat_name'] as String?)?.toString(),
    timestampSec: _normTs(j['timestamp']),
    read: j['read'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'image': image,
    'link': link,
    'post_id': postId,
    'cat_id': catId,
    'cat_name': catName,
    'timestamp': timestampSec,
    'read': read,
  };

  /// Helpers for storing as a string list in SharedPreferences
  static AppNotification fromJsonStr(String s) =>
      AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>);
  String toJsonStr() => jsonEncode(toJson());
}

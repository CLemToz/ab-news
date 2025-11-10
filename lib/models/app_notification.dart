import 'dart:convert';

class AppNotification {
  final String id;           // unique id (we use post_id if present)
  final String title;
  final String body;
  final String? image;       // optional image URL
  final String? link;        // optional web URL
  final int? postId;         // optional WP post id
  final int timestampSec;    // unix seconds
  final bool read;           // for UI badges if you want

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestampSec,
    this.image,
    this.link,
    this.postId,
    this.read = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? image,
    String? link,
    int? postId,
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
      timestampSec: timestampSec ?? this.timestampSec,
      read: read ?? this.read,
    );
  }

  // ---- JSON helpers your store expects ----
  static AppNotification fromJsonStr(String s) =>
      AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toJsonStr() => jsonEncode(toJson());

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    // accept both 'postId' and 'post_id' in saved JSON for flexibility
    int? parsedPostId;
    if (j['postId'] is int) {
      parsedPostId = j['postId'] as int;
    } else if (j['postId'] is String) {
      parsedPostId = int.tryParse(j['postId'] as String);
    } else if (j['post_id'] is int) {
      parsedPostId = j['post_id'] as int;
    } else if (j['post_id'] is String) {
      parsedPostId = int.tryParse(j['post_id'] as String);
    }

    final ts = j['timestampSec'] is int
        ? j['timestampSec'] as int
        : int.tryParse('${j['timestampSec']}') ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final imageStr = (j['image'] ?? '').toString().trim();
    final linkStr  = (j['link']  ?? '').toString().trim();

    return AppNotification(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      image: imageStr.isEmpty ? null : imageStr,
      link:  linkStr.isEmpty ? null : linkStr,
      postId: parsedPostId,
      timestampSec: ts,
      read: j['read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'image': image,
    'link': link,
    'postId': postId,         // keep camelCase consistently in app storage
    'timestampSec': timestampSec,
    'read': read,
  };
}

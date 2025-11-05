import 'package:intl/intl.dart';

class WPReel {
  final int id;
  final String titleRendered;
  final String excerptRendered;
  final DateTime dateGmt;
  final String link;

  // We keep this mutable so API can fill it after a /media/{id} lookup.
  String? coverImage;

  // Meta
  final String videoUrl;   // mp4 (preferred if set)
  final String hlsUrl;     // m3u8
  final int duration;      // seconds
  final int views;
  final int likes;

  // Store the raw media id so we can resolve image later if not embedded
  final int? featuredMediaId;

  WPReel({
    required this.id,
    required this.titleRendered,
    required this.excerptRendered,
    required this.dateGmt,
    required this.link,
    required this.coverImage,
    required this.videoUrl,
    required this.hlsUrl,
    required this.duration,
    required this.views,
    required this.likes,
    required this.featuredMediaId,
  });

  String get title   => _decodeHtml(_stripHtml(titleRendered));
  String get summary => _decodeHtml(_stripHtml(excerptRendered));
  String get imageUrl => coverImage ?? '';
  String get url => link;

  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(dateGmt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours   < 24) return '${diff.inHours} hours ago';
    return DateFormat('d MMM, yyyy • h:mm a').format(dateGmt.toLocal());
  }

  static WPReel fromJson(Map<String, dynamic> j) {
    String? cover;

    // Try _embedded['wp:featuredmedia'][0].media_details.sizes[…].source_url
    try {
      final media = j['_embedded']?['wp:featuredmedia'];
      if (media is List && media.isNotEmpty) {
        final m = media.first as Map<String, dynamic>;
        final md = m['media_details'];
        if (md is Map) {
          final sizes = md['sizes'];
          if (sizes is Map) {
            for (final key in ['medium_large', 'large', 'medium', 'full']) {
              final entry = sizes[key];
              if (entry is Map && entry['source_url'] != null) {
                cover = entry['source_url'].toString();
                break;
              }
            }
          }
        }
        cover ??= (m['source_url'] ?? '').toString();
      }
    } catch (_) {}

    // Date
    final dateStr = (j['date_gmt'] ?? j['date'] ?? '').toString();
    final dt = DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();

    // Meta bundle (set by plugin)
    final meta = (j['meta'] ?? {}) as Map<String, dynamic>;
    String _s(String k) => (meta[k] ?? '').toString();
    int _i(String k) {
      final v = meta[k];
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    // Raw featured_media id (so we can fetch via /media/{id} when needed)
    int? _fid;
    final rawF = j['featured_media'];
    if (rawF is int) {
      _fid = rawF;
    } else if (rawF != null) {
      _fid = int.tryParse('$rawF');
    }

    return WPReel(
      id: j['id'] ?? 0,
      titleRendered: (j['title']?['rendered'] ?? '').toString(),
      excerptRendered: (j['excerpt']?['rendered'] ?? '').toString(),
      dateGmt: dt,
      link: (j['link'] ?? '').toString(),
      coverImage: cover,
      videoUrl: _s('video_url'),
      hlsUrl: _s('hls_url'),
      duration: _i('duration'),
      views: _i('views'),
      likes: _i('likes'),
      featuredMediaId: _fid,
    );
  }

  // Helpers
  static String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

  static String _decodeHtml(String s) {
    var out = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    out = out.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    return out;
  }
}

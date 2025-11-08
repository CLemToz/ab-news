import 'package:intl/intl.dart';

class WPPost {
  final int id;
  final String titleRendered;
  final String excerptRendered; // HTML
  final String contentRendered; // HTML
  final DateTime date; // Use the site's local time from the 'date' field.
  final String link;
  final String? featuredImage;
  final List<String> categoriesNames;
  final List<int> categoriesIds;
  bool isRead;

  WPPost({
    required this.id,
    required this.titleRendered,
    required this.excerptRendered,
    required this.contentRendered,
    required this.date, // Changed from dateGmt
    required this.link,
    required this.featuredImage,
    required this.categoriesNames,
    required this.categoriesIds,
    this.isRead = false,
  });

  factory WPPost.fromWpV2(Map<String, dynamic> j) {
    String _rendered(Map? o, String k) =>
        (o != null && o[k] is String) ? (o[k] as String) : '';

    DateTime _parseDate() {
      // Prioritize the `date` field as requested.
      final dateStr = j['date']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          return DateTime.parse(dateStr);
        } catch (_) {}
      }
      // Fallback to `date_gmt` if `date` is not available.
      final dateGmtStr = j['date_gmt']?.toString();
      if (dateGmtStr != null && dateGmtStr.isNotEmpty) {
        try {
          return DateTime.parse('${dateGmtStr}Z').toLocal();
        } catch (_) {}
      }
      return DateTime.now();
    }

    String? _featuredFromEmbed() {
      try {
        final emb = j['_embedded'];
        if (emb is Map &&
            emb['wp:featuredmedia'] is List &&
            emb['wp:featuredmedia'].isNotEmpty) {
          final m = emb['wp:featuredmedia'][0];
          final srcUrl = m['source_url'];
          if (srcUrl is String && srcUrl.isNotEmpty) {
            return srcUrl;
          }
        }
      } catch (_) {}
      return null;
    }

    List<int> _categoryIds() {
      final raw = j['categories'];
      return (raw is List) ? raw.whereType<int>().toList() : const <int>[];
    }

    List<String> _categoryNamesFromEmbed() {
      try {
        final emb = j['_embedded'];
        if (emb is Map && emb['wp:term'] is List) {
          final terms = emb['wp:term'] as List;
          for (final tax in terms) {
            if (tax is List && tax.isNotEmpty) {
              final firstTerm = tax.first;
              if (firstTerm is Map && firstTerm['taxonomy'] == 'category') {
                return tax
                    .whereType<Map>()
                    .map((m) => (m['name'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
            }
          }
        }
      } catch (_) {}
      return const <String>[];
    }

    return WPPost(
      id: j['id'] ?? 0,
      titleRendered: _rendered(j['title'], 'rendered'),
      excerptRendered: _rendered(j['excerpt'], 'rendered'),
      contentRendered: _rendered(j['content'], 'rendered'),
      date: _parseDate(), // Correctly assign to `date`
      link: (j['link'] ?? '').toString(),
      featuredImage: _featuredFromEmbed(),
      categoriesNames: _categoryNamesFromEmbed(),
      categoriesIds: _categoryIds(),
    );
  }

  static List<WPPost> listFromWpV2(List<dynamic> arr) =>
      arr.whereType<Map<String, dynamic>>().map(WPPost.fromWpV2).toList();

  String get title => _decodeHtml(_stripHtml(titleRendered));
  String get summary => _decodeHtml(_stripHtml(excerptRendered));
  String get body => _decodeHtml(_stripHtml(contentRendered));
  String get imageUrl => featuredImage ?? '';
  String get url => link;
  String get category =>
      categoriesNames.isNotEmpty ? categoriesNames.first : 'News';
  bool get isVideo => false;
  String get videoDuration => '';

  String get timeAgo {
    // Perform the difference calculation in local time.
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) return 'Just now';
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat('d MMM, yyyy • h:mm a').format(date);
  }

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

  factory WPPost.fromJson(Map<String, dynamic> json) {
    return WPPost(
      id: json['id'] ?? 0,
      titleRendered: json['titleRendered'] ?? '',
      excerptRendered: json['excerptRendered'] ?? '',
      contentRendered: json['contentRendered'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      link: json['link'] ?? '',
      featuredImage: json['featuredImage'],
      categoriesNames: (json['categoriesNames'] as List?)?.cast<String>() ?? [],
      categoriesIds: (json['categoriesIds'] as List?)?.cast<int>() ?? [],
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleRendered': titleRendered,
    'excerptRendered': excerptRendered,
    'contentRendered': contentRendered,
    'date': date.toIso8601String(),
    'link': link,
    'featuredImage': featuredImage,
    'categoriesNames': categoriesNames,
    'categoriesIds': categoriesIds,
    'isRead': isRead,
  };
}

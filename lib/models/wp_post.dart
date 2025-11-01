import 'package:intl/intl.dart';

class WPPost {
  final int id;
  final String titleRendered;
  final String excerptRendered; // HTML
  final String contentRendered; // HTML
  final DateTime dateGmt;
  final String link;
  final String? featuredImage;
  final List<String> categoriesNames;
  final List<int> categoriesIds;

  WPPost({
    required this.id,
    required this.titleRendered,
    required this.excerptRendered,
    required this.contentRendered,
    required this.dateGmt,
    required this.link,
    required this.featuredImage,
    required this.categoriesNames,
    required this.categoriesIds,
  });

  // ---------------------------------------------------------------------------
  // NEW: Safe factory for WP REST v2 `/wp-json/wp/v2/posts?_embed=1`
  // ---------------------------------------------------------------------------
  factory WPPost.fromWpV2(Map<String, dynamic> j) {
    String _rendered(Map? o, String k) =>
        (o != null && o[k] is String) ? (o[k] as String) : '';

    DateTime _parseDate() {
      final d = (j['date_gmt'] ?? j['date'])?.toString();
      try {
        return DateTime.parse(d!).toUtc();
      } catch (_) {
        return DateTime.now().toUtc();
      }
    }

    String? _featuredFromEmbed() {
      try {
        final emb = j['_embedded'];
        if (emb is Map &&
            emb['wp:featuredmedia'] is List &&
            emb['wp:featuredmedia'].isNotEmpty) {
          final m = emb['wp:featuredmedia'][0];
          if (m is Map && m['source_url'] is String) {
            return m['source_url'] as String;
          }
        }
      } catch (_) {}
      return null;
    }

    List<int> _categoryIds() {
      final raw = j['categories'];
      if (raw is List) {
        return raw.whereType<int>().toList();
      }
      return const <int>[];
    }

    List<String> _categoryNamesFromEmbed() {
      try {
        final emb = j['_embedded'];
        if (emb is Map && emb['wp:term'] is List) {
          // wp:term is a list of tax arrays; categories are taxonomy 'category'
          final terms = emb['wp:term'] as List;
          for (final tax in terms) {
            if (tax is List && tax.isNotEmpty) {
              // find the category array
              if ((tax.first is Map) &&
                  ((tax.first as Map)['taxonomy'] == 'category')) {
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
      dateGmt: _parseDate(),
      link: (j['link'] ?? '').toString(),
      featuredImage: _featuredFromEmbed(),
      categoriesNames: _categoryNamesFromEmbed(),
      categoriesIds: _categoryIds(),
    );
  }

  /// Convenience to map a list response
  static List<WPPost> listFromWpV2(List<dynamic> arr) =>
      arr.whereType<Map<String, dynamic>>().map(WPPost.fromWpV2).toList();

  // ---- DISPLAY GETTERS (unchanged) ----
  String get title   => _decodeHtml(_stripHtml(titleRendered));
  String get summary => _decodeHtml(_stripHtml(excerptRendered));
  String get body    => _decodeHtml(_stripHtml(contentRendered));

  String get imageUrl => featuredImage ?? '';
  String get url => link;

  String get category =>
      categoriesNames.isNotEmpty ? categoriesNames.first : 'News';

  bool get isVideo => false;
  String get videoDuration => '';

  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(dateGmt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours   < 24) return '${diff.inHours} hours ago';
    return DateFormat('d MMM, yyyy • h:mm a').format(dateGmt.toLocal());
  }

  // ---- HELPERS (unchanged) ----
  static String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

  /// Decodes common named entities and numeric HTML entities (e.g. &#2325;)
  static String _decodeHtml(String s) {
    var out = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    // numeric: &#NNNN;  or hex: &#xNN;
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
      dateGmt: DateTime.tryParse(json['dateGmt'] ?? '') ?? DateTime.now(),
      link: json['link'] ?? '',
      featuredImage: json['featuredImage'],
      categoriesNames: (json['categoriesNames'] as List?)?.cast<String>() ?? [],
      categoriesIds: (json['categoriesIds'] as List?)?.cast<int>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleRendered': titleRendered,
    'excerptRendered': excerptRendered,
    'contentRendered': contentRendered,
    'dateGmt': dateGmt.toIso8601String(),
    'link': link,
    'featuredImage': featuredImage,
    'categoriesNames': categoriesNames,
    'categoriesIds': categoriesIds,
  };

}

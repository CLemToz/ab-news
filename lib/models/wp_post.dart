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

  // ---- DISPLAY GETTERS ----
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

  // ---- HELPERS ----
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
}

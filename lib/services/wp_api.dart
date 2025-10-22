import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/wp.dart';
import '../models/wp_post.dart';

class WpApi {
  static Uri _postsUri({int? categoryId, int page = 1, int perPage = 10}) {
    final base = '${WPConfig.baseUrl}/wp-json/wp/v2/posts';
    final qp = <String, String>{
      'per_page': '$perPage',
      'page': '$page',
      '_embed': '1',
      '_fields':
      'id,date_gmt,link,title,excerpt,content,_embedded,categories',
    };
    if (categoryId != null && categoryId > 0) {
      qp['categories'] = '$categoryId';
    }
    return Uri.parse(base).replace(queryParameters: qp);
  }

  static Future<List<WPPost>> fetchPosts({int? categoryId, int page = 1}) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }

    final res = await http.get(_postsUri(categoryId: categoryId, page: page));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final List data = jsonDecode(res.body);
    return data.map<WPPost>((j) => _mapPost(j)).toList();
  }

  static WPPost _mapPost(Map<String, dynamic> j) {
    String? featured;

    // ---- 1) Featured media (prefer a sized URL) ----
    try {
      final media = j['_embedded']?['wp:featuredmedia'];
      if (media is List && media.isNotEmpty) {
        final m = media.first as Map<String, dynamic>;
        final md = m['media_details'];
        if (md is Map) {
          final sizes = md['sizes'];
          if (sizes is Map) {
            // try medium_large / large / medium / full
            for (final key in ['medium_large', 'large', 'medium', 'full']) {
              final entry = sizes[key];
              if (entry is Map && entry['source_url'] != null) {
                featured = entry['source_url'].toString();
                break;
              }
            }
          }
        }
        // fallback to source_url if still empty
        featured ??= (m['source_url'] ?? '').toString();
      }
    } catch (_) {}

    // ---- 2) Fallback: first <img src="..."> inside content HTML ----
    if (featured == null || featured.isEmpty) {
      try {
        final html = (j['content']?['rendered'] ?? '').toString();
        final exp = RegExp(
          "<img[^>]+src=['\"]([^'\"]+)['\"]",
          caseSensitive: false,
        );
        final match = exp.firstMatch(html);
        if (match != null) {
          featured = match.group(1);
        }
      } catch (_) {}
    }

    // ---- 3) Category names from _embedded terms ----
    final catNames = <String>[];
    try {
      final terms = j['_embedded']?['wp:term'];
      if (terms is List && terms.isNotEmpty) {
        for (final group in terms) {
          if (group is List) {
            for (final t in group) {
              if (t is Map && (t['taxonomy'] ?? '') == 'category') {
                final n = (t['name'] ?? '').toString();
                if (n.isNotEmpty) catNames.add(n);
              }
            }
          }
        }
      }
    } catch (_) {}

    // ---- 4) Category IDs ----
    final catIds = <int>[];
    try {
      final list = j['categories'];
      if (list is List) {
        for (final id in list) {
          final x = (id is int) ? id : int.tryParse('$id');
          if (x != null) catIds.add(x);
        }
      }
    } catch (_) {}

    // ---- 5) Date ----
    final dateStr = (j['date_gmt'] ?? '').toString();
    final dt = DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();

// ---- 6) Fallback image ----
    featured ??= 'https://via.placeholder.com/600x400?text=No+Image';
    if (featured.isEmpty) {
      featured = 'https://via.placeholder.com/600x400?text=No+Image';
    }

    return WPPost(
      id: j['id'] ?? 0,
      titleRendered: (j['title']?['rendered'] ?? '').toString(),
      excerptRendered: (j['excerpt']?['rendered'] ?? '').toString(),
      contentRendered: (j['content']?['rendered'] ?? '').toString(),
      dateGmt: dt,
      link: (j['link'] ?? '').toString(),
      featuredImage: featured,
      categoriesNames: catNames,
      categoriesIds: catIds,
    );
  }
}

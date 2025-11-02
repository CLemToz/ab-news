// lib/services/wp_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/wp.dart';
import '../models/wp_post.dart';

class WpApi {
  // -------------------------------
  // Build posts URI
  // -------------------------------
  static Uri _postsUri({
    int? categoryId,
    int page = 1,
    int perPage = 10,
  }) {
    final base = '${WPConfig.baseUrl}/wp-json/wp/v2/posts';
    final qp = <String, String>{
      'per_page': '$perPage',
      'page': '$page',
      '_embed': '1', // <-- keep this to receive wp:featuredmedia + wp:term
      // IMPORTANT: do NOT include `_fields` here or you'll lose wp:term
    };
    if (categoryId != null && categoryId > 0) {
      qp['categories'] = '$categoryId';
    }
    return Uri.parse(base).replace(queryParameters: qp);
  }

  // -------------------------------
  // Fetch posts (optionally by category)
  // -------------------------------
  static Future<List<WPPost>> fetchPosts({
    int? categoryId,
    int page = 1,
    int perPage = 10,
  }) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }

    final uri = _postsUri(categoryId: categoryId, page: page, perPage: perPage);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final List data = jsonDecode(res.body) as List;
    return data.map<WPPost>((j) => _mapPost(j as Map<String, dynamic>)).toList();
  }

  // Newest site-wide (latest first)
  static Future<List<WPPost>> fetchRecent({
    int perPage = 10,
    int page = 1,
  }) =>
      fetchPosts(perPage: perPage, page: page);

  // -------------------------------
  // Category helpers
  // -------------------------------

  /// Returns a category ID for a given slug (e.g. 'breaking-news').
  /// Used by the slider when you don't want to hardcode the ID.
  static Future<int?> fetchCategoryIdBySlug(String slug) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }

    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/wp/v2/categories')
        .replace(queryParameters: {
      'slug': slug,
      'per_page': '1',
      '_fields': 'id,slug',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      debugPrint('fetchCategoryIdBySlug → HTTP ${res.statusCode}');
      return null;
    }

    try {
      final List data = jsonDecode(res.body) as List;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final id = first['id'];
      return (id is int) ? id : int.tryParse('$id');
    } catch (e) {
      debugPrint('fetchCategoryIdBySlug parse error: $e');
      return null;
    }
  }

  /// Backwards-compatible alias if some files call `getCategoryIdBySlug`.
  static Future<int?> getCategoryIdBySlug(String slug) =>
      fetchCategoryIdBySlug(slug);

  /// Fetch newest posts from the “Breaking” category.
  /// If you already know the category ID, pass [categoryIdOverride] to skip slug lookup.
  static Future<List<WPPost>> fetchBreaking({
    String slug = 'breaking-news',
    int perPage = 5,
    int? categoryIdOverride,
  }) async {
    int? catId = categoryIdOverride;
    catId ??= await fetchCategoryIdBySlug(slug);
    if (catId == null) return <WPPost>[];
    return fetchPosts(categoryId: catId, perPage: perPage, page: 1);
  }

  // -------------------------------
// Search posts by text
// -------------------------------
  static Future<List<WPPost>> searchPosts(
      String query, {
        int perPage = 20,
        int page = 1,
      }) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }

    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/wp/v2/posts').replace(
      queryParameters: {
        'search': query,
        'per_page': '$perPage',
        'page': '$page',
        '_embed': '1', // keep this so we get images + categories
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final List data = jsonDecode(res.body) as List;
    return data.map<WPPost>((j) => _mapPost(j as Map<String, dynamic>)).toList();
  }


  // -------------------------------
  // Map raw WP JSON → WPPost
  // -------------------------------
  static WPPost _mapPost(Map<String, dynamic> j) {
    String? featured;

    // 1) Featured media from _embedded
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
                featured = entry['source_url'].toString();
                break;
              }
            }
          }
        }
        featured ??= (m['source_url'] ?? '').toString();
      }
    } catch (_) {}

    // 2) Fallback: first <img> in content HTML
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

    // 3) Category names from _embedded → wp:term
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

    // 4) Category IDs (numeric)
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

    // 5) Date (UTC)
    final dateStr = (j['date_gmt'] ?? j['date'] ?? '').toString();
    final dt = DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();

    // 6) Fallback image
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

  /// Fetch a single post by ID (with _embed for image/categories).
  static Future<WPPost?> fetchPostById(int id) async {
    final uri = Uri.parse(
      '${WPConfig.baseUrl}/wp-json/wp/v2/posts/$id?_embed=1'
          '&_fields=id,date_gmt,link,title,excerpt,content,_embedded,categories',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final Map<String, dynamic> j = jsonDecode(res.body);
    return _mapPost(j);
  }

  /// Fetch a single post by its link (permalink). Tries to resolve via WP Search.
  static Future<WPPost?> fetchPostByLink(String link) async {
    try {
      // Use WP search endpoint by URL
      final uri = Uri.parse(
        '${WPConfig.baseUrl}/wp-json/wp/v2/search?_embed=1&search=${Uri.encodeQueryComponent(link)}&per_page=1',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final List list = jsonDecode(res.body);
      if (list.isEmpty) return null;
      final int? id = (list.first as Map)['id'] is int ? (list.first as Map)['id'] as int : null;
      if (id == null) return null;
      return fetchPostById(id);
    } catch (_) {
      return null;
    }
  }

}

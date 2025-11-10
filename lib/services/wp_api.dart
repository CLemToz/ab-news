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
      '_embed': '1',
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

  static Future<int?> getCategoryIdBySlug(String slug) =>
      fetchCategoryIdBySlug(slug);

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
  // Search posts
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
        '_embed': '1',
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
  // 🔹 Fetch single post by ID (used by Notifications)
  // -------------------------------
  static Future<WPPost> fetchPostById(int id) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }
    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/wp/v2/posts/$id?_embed=1');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
    final Map<String, dynamic> j = jsonDecode(res.body) as Map<String, dynamic>;
    return _mapPost(j);
  }

  // -------------------------------
  // Map raw WP JSON → WPPost
  // -------------------------------
  static WPPost _mapPost(Map<String, dynamic> j) {
    String? featured;

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

    if (featured == null || featured.isEmpty) {
      try {
        final html = (j['content']?['rendered'] ?? '').toString();
        final exp = RegExp("<img[^>]+src=['\"]([^'\"]+)['\"]", caseSensitive: false);
        final match = exp.firstMatch(html);
        if (match != null) {
          featured = match.group(1);
        }
      } catch (_) {}
    }

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

    final dateStr = (j['date'] ?? '').toString();
    final dt = DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();

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

  // Fetch specific posts by their IDs (order not guaranteed by WP)
  static Future<List<WPPost>> fetchPostsByIds(List<int> ids) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }
    if (ids.isEmpty) return <WPPost>[];

    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/wp/v2/posts').replace(
      queryParameters: {
        'include': ids.join(','),
        'per_page': '${ids.length}',
        '_embed': '1',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map<WPPost>((j) => _mapPost(j as Map<String, dynamic>)).toList();
  }
}

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
    // Use the robust factory method in the model to handle parsing.
    return WPPost.listFromWpV2(data);
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

  /// Backwards-compatible alias.
  static Future<int?> getCategoryIdBySlug(String slug) =>
      fetchCategoryIdBySlug(slug);

  /// Fetch newest posts from the “Breaking” category.
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
        '_embed': '1',
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final List data = jsonDecode(res.body) as List;
    // Use the robust factory method in the model to handle parsing.
    return WPPost.listFromWpV2(data);
  }
}

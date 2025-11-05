import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/wp.dart';
import '../models/wp_reel.dart';

class WpReelsApi {
  static Uri _reelsUri({
    int? categoryId,
    int page = 1,
    int perPage = 10,
  }) {
    final base = '${WPConfig.baseUrl}/wp-json/wp/v2/reels';
    final qp = <String, String>{
      'per_page': '$perPage',
      'page': '$page',
      '_embed': '1',
      // Ask for embedded block AND the raw featured_media id
      '_fields': 'id,date_gmt,link,title,excerpt,_embedded,meta,featured_media',
    };
    // If you ever filter by taxonomy, adjust the key here to your taxonomy.
    if (categoryId != null && categoryId > 0) {
      qp['reel_category'] = '$categoryId'; // <- keep your previous key if needed
    }
    return Uri.parse(base).replace(queryParameters: qp);
  }

  static Future<List<WPReel>> fetchReels({
    int? categoryId,
    int page = 1,
    int perPage = 10,
  }) async {
    if (WPConfig.baseUrl.isEmpty) {
      throw Exception('WPConfig.baseUrl is empty. Set it in lib/config/wp.dart');
    }

    final res = await http.get(
      _reelsUri(categoryId: categoryId, page: page, perPage: perPage),
    );
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final List data = jsonDecode(res.body);
    final reels = data
        .map<WPReel>((j) => WPReel.fromJson(j as Map<String, dynamic>))
        .toList();

    // Ensure featured image exists; if missing, fetch via /media/{id}
    await Future.wait(reels.map((r) async {
      if ((r.coverImage == null || r.coverImage!.isEmpty) &&
          r.featuredMediaId != null &&
          r.featuredMediaId! > 0) {
        final url = await _fetchMediaUrl(r.featuredMediaId!);
        if (url != null && url.isNotEmpty) {
          r.coverImage = url; // fill in
        }
      }
    }));

    return reels;
  }

  static Future<List<WPReel>> fetchRecent({int perPage = 20, int page = 1}) =>
      fetchReels(perPage: perPage, page: page);

  // --- Helpers --------------------------------------------------------------

  static Future<String?> _fetchMediaUrl(int mediaId) async {
    final uri = Uri.parse(
      '${WPConfig.baseUrl}/wp-json/wp/v2/media/$mediaId?_fields=source_url',
    );
    final r = await http.get(uri);
    if (r.statusCode != 200) return null;
    final m = jsonDecode(r.body) as Map<String, dynamic>;
    final url = (m['source_url'] ?? '').toString();
    return url.isEmpty ? null : url;
  }

  // Counters (plugin endpoints)
  static Future<int> incrementView(int id) async {
    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/abnews/v1/reels/$id/view');
    final r = await http.post(uri);
    if (r.statusCode != 200) return 0;
    final m = jsonDecode(r.body) as Map<String, dynamic>;
    return (m['views'] ?? 0) as int;
  }

  static Future<int> like(int id) async {
    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/abnews/v1/reels/$id/like');
    final r = await http.post(uri);
    if (r.statusCode != 200) return 0;
    final m = jsonDecode(r.body) as Map<String, dynamic>;
    return (m['likes'] ?? 0) as int;
  }

  static Future<int> unlike(int id) async {
    final uri = Uri.parse('${WPConfig.baseUrl}/wp-json/abnews/v1/reels/$id/unlike');
    final r = await http.post(uri);
    if (r.statusCode != 200) return 0;
    final m = jsonDecode(r.body) as Map<String, dynamic>;
    return (m['likes'] ?? 0) as int;
  }
}

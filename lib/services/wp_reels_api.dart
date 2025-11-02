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
      // We request meta via custom REST field + featured image + basics
      '_fields':
      'id,date_gmt,link,title,excerpt,_embedded,meta',
    };
    if (categoryId != null && categoryId > 0) {
      qp['app_reel_cat'] = '$categoryId';
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
    final res = await http.get(_reelsUri(categoryId: categoryId, page: page, perPage: perPage));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
    final List data = jsonDecode(res.body);
    return data.map<WPReel>((j) => WPReel.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<WPReel>> fetchRecent({int perPage = 20, int page = 1}) =>
      fetchReels(perPage: perPage, page: page);

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

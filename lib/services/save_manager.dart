import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wp_post.dart';

class SaveManager {
  static const _key = 'saved_posts';

  /// ✅ Get all saved posts
  static Future<List<WPPost>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((s) => WPPost.fromJson(jsonDecode(s))).toList();
  }

  /// ✅ Save a post
  static Future<void> save(WPPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final jsonStr = jsonEncode(post.toJson());
    if (!list.contains(jsonStr)) {
      list.add(jsonStr);
      await prefs.setStringList(_key, list);
    }
  }

  /// ✅ Remove a saved post
  static Future<void> remove(WPPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((s) {
      final obj = WPPost.fromJson(jsonDecode(s));
      return obj.id == post.id;
    });
    await prefs.setStringList(_key, list);
  }

  /// ✅ Check if a post is saved
  static Future<bool> isSaved(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    for (var s in list) {
      final obj = WPPost.fromJson(jsonDecode(s));
      if (obj.id == id) return true;
    }
    return false;
  }
}

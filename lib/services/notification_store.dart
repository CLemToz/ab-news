import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

/// Very lightweight local store for notifications using SharedPreferences.
/// Stores a list of JSON strings under a single key.
class NotificationStore {
  static const String _key = 'app_notifications';

  /// Return notifications sorted by timestamp desc (newest first).
  static Future<List<AppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    final items = list.map(AppNotification.fromJsonStr).toList();

    items.sort((a, b) => b.timestampSec.compareTo(a.timestampSec));
    return items;
    // NOTE: Keep as list to preserve order in UI.
  }

  /// Add/replace a notification. If id already exists, replace it (upsert).
  static Future<void> upsert(AppNotification n) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    int existing = list.indexWhere((s) {
      try {
        return AppNotification.fromJsonStr(s).id == n.id;
      } catch (_) {
        return false;
      }
    });

    if (existing >= 0) {
      list[existing] = n.toJsonStr();
    } else {
      // prepend to keep it “newest on top” in most UIs
      list.insert(0, n.toJsonStr());
    }
    await prefs.setStringList(_key, list);
  }

  /// Mark one notification read/unread
  static Future<void> markRead(String id, {bool read = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    for (int i = 0; i < list.length; i++) {
      try {
        final n = AppNotification.fromJsonStr(list[i]);
        if (n.id == id) {
          list[i] = n.copyWith(read: read).toJsonStr();
          break;
        }
      } catch (_) {}
    }
    await prefs.setStringList(_key, list);
  }

  /// Remove by id
  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.removeWhere((s) {
      try {
        return AppNotification.fromJsonStr(s).id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, list);
  }

  /// Clear all
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

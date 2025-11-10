import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationStore {
  static const String _key = 'app_notifications';

  static Future<List<AppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    final items = list.map(AppNotification.fromJsonStr).toList();
    items.sort((a, b) => b.timestampSec.compareTo(a.timestampSec));
    return items;
  }

  /// Insert newest-first; replace if same id exists.
  static Future<void> upsert(AppNotification n) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    final i = list.indexWhere((s) {
      try {
        return AppNotification.fromJsonStr(s).id == n.id;
      } catch (_) {
        return false;
      }
    });

    if (i >= 0) {
      list[i] = n.toJsonStr();
    } else {
      list.insert(0, n.toJsonStr());
    }
    await prefs.setStringList(_key, list);
  }

  static Future<void> markRead(String id, {bool read = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    for (var i = 0; i < list.length; i++) {
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

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

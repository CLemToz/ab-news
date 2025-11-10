import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/brand.dart';
import '../../models/app_notification.dart';
import '../../services/notification_store.dart';
import '../../services/wp_api.dart';
import '../../models/wp_post.dart';
import '../category_news/wp_article_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationStore.getAll();
    if (!mounted) return;
    setState(() => _items = list);
  }

  Future<void> _openArticleFromNotification(AppNotification n) async {
    if (n.postId == null && (n.link == null || n.link!.isEmpty)) return;

    // show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      WPPost? post;

      if (n.postId != null && n.postId! > 0) {
        post = await WpApi.fetchPostById(n.postId!);
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      if (post != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WpArticleScreen(post: post!)),
        );
      } else if (n.link != null && n.link!.isNotEmpty) {
        await launchUrl(Uri.parse(n.link!), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not available')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this article')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                await NotificationStore.clear();
                await _load();
              },
              tooltip: 'Clear all',
            )
        ],
      ),
      body: RefreshIndicator(
        color: Brand.red,
        onRefresh: _load,
        child: _items.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.notifications_off_outlined,
                size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = _items[i];
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete, color: cs.onErrorContainer),
              ),
              onDismissed: (_) async {
                await NotificationStore.remove(n.id);
                setState(() => _items.removeAt(i));
              },
              child: Material(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openArticleFromNotification(n),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (n.image?.isNotEmpty ?? false)
                              ? Image.network(
                            n.image!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 72,
                            height: 72,
                            color: cs.surfaceVariant,
                            child: Icon(Icons.image_outlined,
                                color: cs.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            await NotificationStore.remove(n.id);
                            await _load();
                          },
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

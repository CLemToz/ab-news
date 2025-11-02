import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/wp_post.dart';
import '../../services/wp_api.dart';
import '../../theme/brand.dart';
import '../category_news/wp_article_screen.dart';
import '../../services/notifications_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationsStore.instance.markAllRead();
  }

  Future<void> _openArticle({int? postId, String? link}) async {
    try {
      WPPost? post;
      if (postId != null) {
        post = await WpApi.fetchPostById(postId);
      } else if (link != null && link.isNotEmpty) {
        post = await WpApi.fetchPostByLink(link);
      }
      if (!mounted) return;
      if (post != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => WpArticleScreen(post: post!)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article not found')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open article')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = NotificationsStore.instance.all();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: () async {
                await NotificationsStore.instance.clear();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) {
          final n = items[i];
          final date = DateFormat('d MMM, yyyy • h:mm a').format(n.createdAt);
          return Dismissible(
            key: ValueKey(n.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) async {
              await NotificationsStore.instance.remove(n.id);
              if (mounted) setState(() {});
            },
            child: ListTile(
              leading: n.image != null && n.image!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(n.image!, width: 56, height: 56, fit: BoxFit.cover),
              )
                  : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications),
              ),
              title: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(date, style: Theme.of(context).textTheme.bodySmall),
              onTap: () => _openArticle(postId: n.postId, link: n.link),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: items.length,
      ),
    );
  }
}

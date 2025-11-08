import 'package:flutter/material.dart';
import '../services/wp_api.dart';
import '../models/wp_post.dart';
import 'breaking_news_carousel.dart';
import '../features/category_news/wp_article_screen.dart';

class BreakingNewsSection extends StatelessWidget {
  final int categoryId;   // numeric ID of "Breaking News"
  final int perPage;
  final void Function(WPPost post)? onPostTap;

  const BreakingNewsSection({
    super.key,
    required this.categoryId,
    this.perPage = 5,
    this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<WPPost>>(
      future: WpApi.fetchPosts(categoryId: categoryId, page: 1, perPage: perPage),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loading(cs);
        }
        if (snap.hasError) {
          return _error('Failed to load breaking news', cs);
        }
        final items = snap.data ?? const <WPPost>[];
        if (items.isEmpty) {
          return _error('No breaking news', cs);
        }
        return BreakingNewsCarousel(
          items: items, // WPPost works because it has title/summary/imageUrl
          onTap: (article) {
            if (onPostTap != null) {
              onPostTap!(article as WPPost);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WpArticleScreen(post: article as WPPost),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _loading(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    ),
  );

  Widget _error(String msg, ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ),
    ),
  );
}

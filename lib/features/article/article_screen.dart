import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../widgets/common.dart';
import '../category_news/category_news_screen.dart'; // ⬅ for navigation to category list

class ArticleScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Safe helpers in case some fields are null/empty
    String _v(String? s) => (s ?? '').trim();
    final String category = _v(article.category).isEmpty ? 'News' : _v(article.category);
    final String author   = _v(article.author).isEmpty ? 'DK News Plus' : _v(article.author);
    final String imageUrl = _v(article.imageUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Category chip (tap to open that category’s list) ──
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryNewsScreen(
                        category: category, // show the same category
                        // if you later pass a real WP categoryId, add it here
                        // categoryId: article.categoryId,
                      ),
                    ),
                  );
                },
                child: TagChip(text: category),
              ),
              const Spacer(),
              // 👇 Removed “views” icon & count (not supplied by WP)
            ],
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 12),

          // Featured image with graceful fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl.isEmpty
                ? _imageFallback(cs)
                : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(cs),
            ),
          ),

          const SizedBox(height: 12),

          // Author row (logo avatar + author + time info)
          Row(
            children: [
              // Replace avatar with DK News Plus logo asset (safe fallback)
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/faviconsize.jpg', // <- put your logo here
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.newspaper, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(author),
              const SizedBox(width: 10),
              Text(
                '•  ${article.timeAgo}  •  ${article.readTime}',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Body
          Text(
            article.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(ColorScheme cs) {
    return Container(
      height: 220,
      color: cs.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: cs.onSurfaceVariant),
    );
  }
}

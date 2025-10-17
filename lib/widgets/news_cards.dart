import 'package:flutter/material.dart';
import '../models/news_article.dart';

class NewsCardLarge extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;
  const NewsCardLarge({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AspectRatio(aspectRatio: 16 / 10, child: Image.network(article.imageUrl, fit: BoxFit.cover)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.center,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(article.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsCardSmall extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;
  const NewsCardSmall({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(article.imageUrl, width: 110, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(article.timeAgo, style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                Text('•', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                Text(article.readTime, style: TextStyle(color: cs.onSurfaceVariant)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

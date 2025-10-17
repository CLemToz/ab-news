import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../widgets/common.dart';

class ArticleScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.bookmark_border))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            TagChip(text: article.category),
            const Spacer(),
            Icon(Icons.visibility_outlined, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('2', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(article.imageUrl, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/80?img=12')),
            const SizedBox(width: 10),
            Text(article.author),
            const SizedBox(width: 10),
            Text('•  ${article.timeAgo}  •  ${article.readTime}', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 16),
          Text(article.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('Share')),
        ],
      ),
    );
  }
}

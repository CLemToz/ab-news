import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/wp_post.dart';
import '../../theme/brand.dart';
import '../../widgets/common.dart';

class WpArticleScreen extends StatelessWidget {
  final WPPost post;
  const WpArticleScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
          Row(
            children: [
              TagChip(text: post.category),
              const Spacer(),
              Icon(Icons.visibility_outlined, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('2', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: cs.surfaceVariant,
                  child: const Center(child: Icon(Icons.broken_image, size: 40)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://i.pravatar.cc/80?img=12'),
              ),
              const SizedBox(width: 10),
              Text(
                "DK News Plus",
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Text('•  ${post.timeAgo}', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _stripHtml(post.contentRendered),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Brand.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Share.share(post.url),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
}

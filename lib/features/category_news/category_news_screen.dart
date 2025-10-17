import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/news_cards.dart';
import '../article/article_screen.dart';

class CategoryNewsScreen extends StatelessWidget {
  final String category; // 'All' allowed
  const CategoryNewsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final filtered = category == 'All'
        ? articles
        : articles.where((a) => a.category == category).toList();

    return Scaffold(
      appBar: AppBar(title: Text(category == 'All' ? 'Recent News' : category)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => NewsCardSmall(
          article: filtered[i],
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ArticleScreen(article: filtered[i]),
          )),
        ),
      ),
    );
  }
}

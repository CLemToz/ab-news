import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/news_cards.dart';
import '../article/article_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String q = '';
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final results = q.isEmpty
        ? articles.take(8).toList()
        : articles.where((a) =>
    a.title.toLowerCase().contains(q.toLowerCase()) ||
        a.subtitle.toLowerCase().contains(q.toLowerCase()))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'Search news, topics, authors…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
            ),
            onChanged: (v) => setState(() => q = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => NewsCardSmall(
              article: results[i],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ArticleScreen(article: results[i]),
              )),
            ),
          ),
        ),
      ],
    );
  }
}

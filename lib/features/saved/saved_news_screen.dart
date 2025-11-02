import 'package:flutter/material.dart';
import '../../theme/brand.dart';
import '../../models/wp_post.dart';
import '../../services/save_manager.dart';
import '../category_news/wp_article_screen.dart';
import '../../widgets/recent_news_item.dart';

class SavedNewsScreen extends StatefulWidget {
  const SavedNewsScreen({super.key});

  @override
  State<SavedNewsScreen> createState() => _SavedNewsScreenState();
}

class _SavedNewsScreenState extends State<SavedNewsScreen> {
  List<WPPost> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SaveManager.getAll();
    setState(() {
      _saved = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _saved.isEmpty
          ? const Center(child: Text('No saved articles'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _saved.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final post = _saved[i];
            return RecentNewsItem(
              article: post,
              displayCategory: post.category,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WpArticleScreen(post: post),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

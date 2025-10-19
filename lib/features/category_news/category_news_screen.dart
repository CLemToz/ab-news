import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/recent_news_item.dart';
import '../article/article_screen.dart';
import '../../theme/brand.dart';
import '../../widgets/news_shimmers.dart'; // 👈 make sure this file exists (from home screen)

class CategoryNewsScreen extends StatefulWidget {
  final String category; // 'All' or specific category
  const CategoryNewsScreen({super.key, required this.category});

  @override
  State<CategoryNewsScreen> createState() => _CategoryNewsScreenState();
}

class _CategoryNewsScreenState extends State<CategoryNewsScreen> {
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2)); // mock API call
    if (mounted) setState(() => _loading = false);
  }

  void _openArticle(article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter news list based on category
    final list = widget.category == 'All'
        ? List.of(articles)
        : articles.where((a) => a.category == widget.category).toList();

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        centerTitle: false, // ⬅ left aligned
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            widget.category,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        elevation: 0,
      ),

      // ------- BODY -------
      body: RefreshIndicator(
        color: Brand.red,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            if (_loading)
              const SliverPadding(
                padding: EdgeInsets.only(top: 24, left: 16, right: 16),
                sliver: RecentListShimmer(), // <-- your shimmer returns a SliverList
              )
            else if (list.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.article_outlined,
                            size: 60, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No news available',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 12),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: RecentNewsItem(
                      article: list[i],
                      onTap: () => _openArticle(list[i]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

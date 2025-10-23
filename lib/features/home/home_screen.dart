import 'package:flutter/material.dart';

import '../../theme/brand.dart'; // Brand.red
import '../../data/mock_data.dart';
import '../../widgets/common.dart';
import '../../widgets/news_cards.dart';
import '../category_news/category_news_screen.dart';
import '../article/article_screen.dart';
import '../categories/categories_screen.dart';
import '../reels/reels_screen.dart';
import '../../widgets/video_section_shimmer.dart';
import '../../widgets/empty_videos_state.dart';
import '../../widgets/news_shimmers.dart';
import '../../widgets/portrait_video_thumb.dart';
import '../../widgets/recent_news_item.dart';

// 🔥 WP API + models
import '../../services/wp_api.dart';
import '../../models/wp_post.dart';
import '../category_news/wp_article_screen.dart';

// 🔥 Rounded, auto-playing slider fed by WP
import '../../widgets/breaking_news_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingVideos = false;
  bool _hasError = false;
  bool _isLoadingAll = false;

  // 👉 Change this to your real Breaking category ID
  static const int _breakingCategoryId = 398;

  Future<void> _refreshAll() async {
    setState(() {
      _isLoadingVideos = true;
      _isLoadingAll = true;
      _hasError = false;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLoadingVideos = false;
        _isLoadingAll = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingVideos = false;
        _isLoadingAll = false;
        _hasError = true;
      });
    }
  }

  void _openReel(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReelsScreen(initialIndex: index)),
    );
  }

  // Smart open: WP posts -> WpArticleScreen, mock articles -> ArticleScreen
  void _openArticle(BuildContext context, dynamic article) {
    if (article is WPPost) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WpArticleScreen(post: article)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recentsMock = articles.take(6).toList(); // still used in other areas if needed

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        slivers: [
          // -------- Header --------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bhilai', style: Theme.of(context).textTheme.headlineSmall),
                        Text("Here's your news feed", style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Row(children: [
                    Icon(Icons.wb_cloudy_outlined, color: Brand.red),
                    const SizedBox(width: 6),
                    Text('29°', style: Theme.of(context).textTheme.titleMedium),
                  ])
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: TickerStrip(text: tickerText)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: QuickReadCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // -------- BREAKING NEWS (API slider) --------
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'BREAKING NEWS',
              color: Brand.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryNewsScreen(
                    category: 'Breaking News',
                    categoryId: _breakingCategoryId,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BreakingNewsSection(
              categoryId: _breakingCategoryId,
              perPage: 5,
            ),
          ),

          // -------- VIDEOS (mock) --------
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'VIDEOS',
              color: Brand.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReelsScreen()));
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildVideoSection()),

          // -------- HIGHLIGHTED CATEGORIES (mock) --------
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'HIGHLIGHTED CATEGORIES',
              color: Brand.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
            ),
          ),
          if (_isLoadingAll)
            const SliverToBoxAdapter(child: CategoriesRailShimmer())
          else
            SliverToBoxAdapter(
              child: HorizontalCategoryList(
                items: highlightedCategories,
                onTap: (c) => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoryNewsScreen(category: c.name)),
                ),
              ),
            ),

          // -------- RECENT NEWS (API: 10 newest) --------
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'RECENT NEWS',
              color: Brand.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _RecentAllScreen()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<WPPost>>(
              future: WpApi.fetchRecent(perPage: 10),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final list = snap.data ?? const <WPPost>[];
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('No recent news'),
                  );
                }
                return Column(
                  children: List.generate(list.length, (i) {
                    final p = list[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: RecentNewsItem(
                        article: p,
                        onTap: () => _openArticle(context, p),
                        displayCategory: p.category, // chip stays correct
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 0)),
        ],
      ),
    );
  }

  // -------- Helper Functions --------
  Widget _buildVideoSection() {
    if (_hasError) return _buildErrorState();
    if (_isLoadingVideos) return const VideoSectionShimmer();
    if (reels.isEmpty) return const EmptyVideosState();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: reels.length.clamp(0, 10),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => PortraitVideoThumb(
          imageUrl: reels[i].coverImage,
          title: reels[i].title,
          onTap: () => _openReel(context, i),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text('Failed to load videos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _refreshAll, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

/// -------------------------------
/// View All screen for Recent News
/// -------------------------------
class _RecentAllScreen extends StatelessWidget {
  const _RecentAllScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent News'),
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: Brand.red,
        onRefresh: () async {},
        child: FutureBuilder<List<WPPost>>(
          future: WpApi.fetchRecent(perPage: 20),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? const <WPPost>[];
            if (list.isEmpty) {
              return Center(
                child: Text('No recent news', style: TextStyle(color: cs.onSurfaceVariant)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = list[i];
                return RecentNewsItem(
                  article: p,
                  displayCategory: p.category,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WpArticleScreen(post: p)),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

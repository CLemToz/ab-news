import 'package:flutter/material.dart';
import '../../theme/brand.dart'; // to use Brand.red
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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingVideos = false;
  bool _hasError = false;
  bool _isLoadingAll = false;

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
    } catch (e) {
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

  void _openArticle(BuildContext context, article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final breaking = articles.first;
    final recents = articles.take(6).toList();

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
                        Text('Sisodra', style: Theme.of(context).textTheme.headlineSmall),
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
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // -------- BREAKING NEWS --------
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'BREAKING NEWS',
              color: Brand.red, // red accent
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryNewsScreen(category: breaking.category)),
              ),
            ),
          ),
          if (_isLoadingAll)
            const SliverToBoxAdapter(child: BreakingNewsShimmer())
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: NewsCardLarge(article: breaking, onTap: () => _openArticle(context, breaking)),
              ),
            ),

          // -------- VIDEOS --------
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'VIDEOS',
              color: Brand.red, // red accent
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReelsScreen()));
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildVideoSection()),

          // -------- HIGHLIGHTED CATEGORIES --------
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'HIGHLIGHTED CATEGORIES',
              color: Brand.red, // red accent
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

          // -------- RECENT NEWS --------
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'RECENT NEWS',
              color: Brand.red, // red accent
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryNewsScreen(category: 'All')),
              ),
            ),
          ),
          if (_isLoadingAll)
            const RecentListShimmer()
          else
            SliverList.separated(
              itemCount: recents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              // inside SliverList.separated for Recent
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RecentNewsItem(
                  article: recents[i],
                  onTap: () => _openArticle(context, recents[i]),
                ),
              ),

            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

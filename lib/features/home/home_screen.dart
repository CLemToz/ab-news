import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // ✅ added for icons

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
import '../saved/saved_news_screen.dart';
import '../../services/wp_reels_api.dart';
import '../../models/wp_reel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/wp_categories_horizontal.dart';



// WP API + models
import '../../services/wp_api.dart';
import '../../models/wp_post.dart';
import '../category_news/wp_article_screen.dart';

// Rounded, auto-playing slider fed by WP
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

  // Your Breaking category ID
  static const int _breakingCategoryId = 398;

  Future<void> _refreshAll() async {
    setState(() {
      _isLoadingVideos = true;
      _isLoadingAll = true;
      _hasError = false;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVideos = false;
          _isLoadingAll = false;
        });
      }
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

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        slivers: [
          // -------- Header --------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ Left side: logo + name
                  Row(
                    children: [
                      Image.asset(
                        'assets/faviconsize.jpg', // ✅ your DA News logo
                        height: 40,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DA News Plus',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  // ✅ Right side: Notification + Saved icons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.bell),
                        onPressed: () {
                          // TODO: Add Notification screen navigation
                        },
                        color: Brand.red,
                      ),
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.bookmark),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SavedNewsScreen()),
                          );
                        },
                        color: Brand.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: TickerStrip(text: tickerText)),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ✅ Replaced QuickReadCard → TrendingNewsCard
          const SliverToBoxAdapter(child: TrendingNewsCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 2)),

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
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ReelsScreen()));
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildVideoSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: SectionHeader(
              label: 'HIGHLIGHTED CATEGORIES',
              color: Brand.red,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: WpCategoriesHorizontal(
              highlightedOnly: true, // 🔴 now driven by website toggle
              maxItems: 12,
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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: RecentNewsItem(
                        article: p,
                        onTap: () => _openArticle(context, p),
                        displayCategory: p.category, // chip shows post category
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
    return FutureBuilder<List<WPReel>>(
      future: WpReelsApi.fetchRecent(perPage: 5),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const VideoSectionShimmer();
        }
        if (snap.hasError) return _buildErrorState();

        final reels = snap.data ?? const <WPReel>[];
        if (reels.isEmpty) return const EmptyVideosState();

        return SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final r = reels[i];

              // ✅ Only use the field that exists in WPReel
              final cover = (r.coverImage?.isNotEmpty ?? false)
                  ? r.coverImage!
                  : 'https://via.placeholder.com/720x1280?text=Reel';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReelsScreen(initialReelId: r.id),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 220,
                        child: CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Theme.of(context).colorScheme.surfaceVariant),
                          errorWidget: (_, __, ___) =>
                              Container(color: Theme.of(context).colorScheme.surfaceVariant),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(.55), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(
                          r.titleRendered ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text('Failed to load videos',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _refreshAll, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

/// -------------------------------
/// Trending News Card (replacement)
/// -------------------------------
class TrendingNewsCard extends StatelessWidget {
  const TrendingNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Brand.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            FontAwesomeIcons.fireFlameCurved,
            color: Colors.redAccent,
          ),
        ),
        title: const Text(
          'Trending News',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: const Text(
          'Stay updated with top trending stories.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Brand.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            // ✅ Navigate to “ट्रेंडिंग News” category
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryNewsScreen(
                  category: 'Trending News',
                  categoryId: 63554,
                ),
              ),
            );
          },
          child: const Text(
            'See',
            style: TextStyle(color: Colors.white),
          ),
        ),
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
                child: Text('No recent news',
                    style: TextStyle(color: cs.onSurfaceVariant)),
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

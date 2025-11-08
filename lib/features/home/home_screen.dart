import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/brand.dart';
import '../../data/mock_data.dart';
import '../../widgets/common.dart';
import '../../widgets/news_cards.dart';
import '../category_news/category_news_screen.dart';
import '../article/article_screen.dart';
import '../categories/categories_screen.dart';
import '../reels/reels_screen.dart';
import '../../widgets/video_section_shimmer.dart';
import '../../widgets/empty_videos_state.dart';
import '../../widgets/recent_news_item.dart';
import '../saved/saved_news_screen.dart';
import '../../services/wp_reels_api.dart';
import '../../models/wp_reel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/wp_categories_horizontal.dart';

import '../../services/wp_api.dart';
import '../../models/wp_post.dart';
import '../category_news/wp_article_screen.dart';

import '../../widgets/breaking_news_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadCount = 0;
  List<WPPost> _unreadPosts = [];

  static const int _breakingCategoryId = 398;

  @override
  void initState() {
    super.initState();
    _checkForNewPosts();
    // Check for new posts periodically.
    Timer.periodic(const Duration(minutes: 2), (_) => _checkForNewPosts());
  }

  /// Checks for posts newer than the last time the user opened the unread screen.
  Future<void> _checkForNewPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadTimeStr = prefs.getString('lastReadTime');
      final lastReadTime = lastReadTimeStr != null
          ? DateTime.parse(lastReadTimeStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      final posts = await WpApi.fetchPosts(perPage: 20);
      if (mounted) {
        final newPosts = posts
            .where((p) => p.dateGmt.toUtc().isAfter(lastReadTime))
            .toList();
        setState(() {
          _unreadPosts = newPosts;
          _unreadCount = newPosts.length;
        });
      }
    } catch (e) {
      // Silently ignore errors, as this runs in the background.
    }
  }

  /// Navigates to the unread screen and, upon return, marks items as read.
  void _showUnreadNews() async {
    // Navigate and wait for the user to return.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _UnreadNewsScreen(posts: _unreadPosts),
      ),
    );

    // After returning, update the time and clear the unread count.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadTime', DateTime.now().toUtc().toIso8601String());

    if (mounted) {
      setState(() {
        _unreadCount = 0;
        _unreadPosts = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _checkForNewPosts,
      child: CustomScrollView(
        slivers: [
          _buildHeader(context),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: TickerStrip(text: tickerText)),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          const SliverToBoxAdapter(child: TrendingNewsCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 2)),
          _buildSectionHeader(context, 'BREAKING NEWS', _breakingCategoryId),
          SliverToBoxAdapter(
            child: BreakingNewsSection(
              categoryId: _breakingCategoryId,
              perPage: 5,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          _buildSectionHeader(context, 'VIDEOS', null, showReels: true),
          _buildVideoSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          _buildSectionHeader(context, 'HIGHLIGHTED CATEGORIES', null, showCategories: true),
          const SliverToBoxAdapter(
            child: WpCategoriesHorizontal(highlightedOnly: true, maxItems: 12),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          _buildSectionHeader(context, 'RECENT NEWS', null, showRecent: true),
          _buildRecentNews(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/faviconsize.jpg', height: 40),
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
            Row(
              children: [
                if (_unreadCount > 0)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.bell, color: Brand.red),
                        onPressed: _showUnreadNews, // <-- CORRECTED ACTION
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8, right: 6),
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                else
                  // Show a disabled (grey) bell when there are no new notifications.
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.solidBell, color: Colors.grey),
                    onPressed: () {},
                  ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.bookmark, color: Brand.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedNewsScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ... (other build methods remain the same) ...

  SliverToBoxAdapter _buildSectionHeader(BuildContext context, String label, int? categoryId, {bool showRecent = false, bool showCategories = false, bool showReels = false}) {
    return SliverToBoxAdapter(
      child: SectionHeader(
        label: label,
        color: Brand.red,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onViewAll: () {
          Widget screen = const SizedBox.shrink();
          if (categoryId != null) {
            screen = CategoryNewsScreen(category: label, categoryId: categoryId);
          } else if (showRecent) {
            screen = const _AllRecentNewsScreen(); // Dedicated screen for all recent news
          } else if (showCategories) {
            screen = const CategoriesScreen();
          } else if (showReels) {
            screen = const ReelsScreen();
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }

  Widget _buildVideoSection() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<WPReel>>(
        future: WpReelsApi.fetchRecent(perPage: 5),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const VideoSectionShimmer();
          if (snap.hasError || !snap.hasData || snap.data!.isEmpty) return const EmptyVideosState();
          final reels = snap.data!;
          return SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: reels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final r = reels[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReelsScreen(initialReelId: r.id))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack( // ... build reel item ...
                      children: [
                        SizedBox(
                          width: 150,
                          height: 220,
                          child: CachedNetworkImage(imageUrl: r.coverImage ?? '', fit: BoxFit.cover),
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
                        Positioned(left: 10, right: 10, bottom: 10, child: Text(r.titleRendered ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentNews() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<WPPost>>(
        future: WpApi.fetchRecent(perPage: 10),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError || !snap.hasData || snap.data!.isEmpty) return const Center(child: Text('No recent news'));
          final list = snap.data!;
          return Column(
            children: list.map((p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: RecentNewsItem(
                article: p,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WpArticleScreen(post: p))),
                displayCategory: p.category,
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}

/// Screen to display a list of unread news articles.
class _UnreadNewsScreen extends StatelessWidget {
  final List<WPPost> posts;
  const _UnreadNewsScreen({required this.posts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unread News'),
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
      ),
      body: posts.isEmpty
          ? const Center(child: Text('No unread articles.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final post = posts[i];
                return RecentNewsItem(
                  article: post,
                  displayCategory: post.category,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WpArticleScreen(post: post)),
                    );
                  },
                );
              },
            ),
    );
  }
}


/// Screen to display all recent news (used for 'View All').
class _AllRecentNewsScreen extends StatelessWidget {
  const _AllRecentNewsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent News'),
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<WPPost>>(
        future: WpApi.fetchRecent(perPage: 20),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('No recent news available.'));
          }
          final posts = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final post = posts[i];
              return RecentNewsItem(
                article: post,
                displayCategory: post.category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WpArticleScreen(post: post)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


class TrendingNewsCard extends StatelessWidget {
  const TrendingNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        leading: Container(
          height: 40, width: 40,
          decoration: BoxDecoration(color: Brand.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(FontAwesomeIcons.fireFlameCurved, color: Colors.redAccent),
        ),
        title: const Text('Trending News', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: const Text('Stay updated with top trending stories.', style: TextStyle(fontSize: 13, color: Colors.black54)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Brand.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryNewsScreen(category: 'Trending News', categoryId: 63554)),
            );
          },
          child: const Text('See', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
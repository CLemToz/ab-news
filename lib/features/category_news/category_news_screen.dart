import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/brand.dart';
import '../../services/wp_api.dart';
import '../../models/wp_post.dart';
import '../../config/wp.dart';
import '../../widgets/recent_news_item.dart';
import 'wp_article_screen.dart';

class CategoryNewsScreen extends StatefulWidget {
  final String category;
  final int? categoryId;
  const CategoryNewsScreen({super.key, required this.category, this.categoryId});

  @override
  State<CategoryNewsScreen> createState() => _CategoryNewsScreenState();
}

class _CategoryNewsScreenState extends State<CategoryNewsScreen> {
  bool _loading = true;
  bool _error = false;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  final List<WPPost> _posts = [];
  final ScrollController _sc = ScrollController();

  int? _resolvedCategoryId;

  @override
  void initState() {
    super.initState();
    _resolvedCategoryId = widget.categoryId;
    _fetch(initial: true);
    _sc.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<int?> _resolveCategoryIdByName(String name) async {
    if (WPConfig.baseUrl.isEmpty) return null;
    final uri = Uri.parse(
      '${WPConfig.baseUrl}/wp-json/wp/v2/categories?search=$name&per_page=100&_fields=id,name',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List;
    for (final m in list) {
      if ((m['name'] ?? '').toString().trim() == name.trim()) {
        return m['id'] as int?;
      }
    }
    if (list.isNotEmpty) return list.first['id'] as int?;
    return null;
  }

  Future<void> _fetch({bool initial = false, bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _posts.clear();
        _hasMore = true;
        _error = false;
      });
    }
    try {
      if (initial || _page == 1) {
        setState(() {
          _loading = true;
          _error = false;
        });
      } else {
        setState(() => _loadingMore = true);
      }

      if (_resolvedCategoryId == null && WPConfig.baseUrl.isNotEmpty) {
        _resolvedCategoryId = await _resolveCategoryIdByName(widget.category);
      }

      List<WPPost> batch;
      if (_resolvedCategoryId != null && _resolvedCategoryId! > 0) {
        batch = await WpApi.fetchPosts(categoryId: _resolvedCategoryId, page: _page);
      } else {
        batch = await WpApi.fetchPosts(page: _page);
        batch = batch.where((p) {
          final names = p.categoriesNames.map((e) => e.toLowerCase()).toList();
          return names.contains(widget.category.toLowerCase());
        }).toList();
      }

      setState(() {
        _posts.addAll(batch);
        _loading = false;
        _loadingMore = false;
        _hasMore = batch.isNotEmpty;
        _page += 1;
      });
    } catch (_) {
      setState(() {
        if (_page == 1) _loading = false;
        _loadingMore = false;
        _error = true;
      });
    }
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_sc.position.pixels > _sc.position.maxScrollExtent - 400) {
      _fetch();
    }
  }

  void _openArticle(WPPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WpArticleScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: Brand.red,
        onRefresh: () => _fetch(refresh: true),
        child: CustomScrollView(
          controller: _sc,
          slivers: [
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                sliver: SliverList.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, __) => _RecentSkeleton(cs: cs),
                ),
              )
            else if (_error)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.wifi_tethering_error_rounded,
                            size: 56, color: cs.error),
                        const SizedBox(height: 10),
                        const Text('Failed to load news'),
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _fetch(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 12),
                sliver: SliverList.separated(
                  itemCount: _posts.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    if (i >= _posts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final p = _posts[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: RecentNewsItem(
                        article: p,
                        displayCategory: _resolveCategoryName(p),
                        onTap: () => _openArticle(p),
                      ),
                    );
                  },
                ),
              ),

            // ✅ Add bottom padding spacer here
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCategoryName(WPPost post) {
    if (post.categoriesNames.isNotEmpty) {
      return post.categoriesNames.first;
    }
    if (post.categoriesIds.isNotEmpty) {
      final id = post.categoriesIds.first;
      final cached = _CategoryNameCache.get(id);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    return widget.category;
  }
}

class _RecentSkeleton extends StatelessWidget {
  final ColorScheme cs;
  const _RecentSkeleton({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(cs, w: 220, h: 16),
                    const SizedBox(height: 8),
                    _bar(cs, w: 180, h: 14),
                    const SizedBox(height: 8),
                    _bar(cs, w: 140, h: 14),
                    const Spacer(),
                    Row(
                      children: [
                        _chip(cs, w: 70),
                        const SizedBox(width: 8)
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 200,
              height: 500,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(ColorScheme cs, {double w = 100, double h = 12}) =>
      Container(width: w, height: h, decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8)));
  Widget _chip(ColorScheme cs, {double w = 60}) =>
      Container(width: w, height: 22, decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(12)));
  Widget _dot(ColorScheme cs) =>
      Container(width: 4, height: 4, decoration: BoxDecoration(color: cs.outline, shape: BoxShape.circle));
}

class _CategoryNameCache {
  static final Map<int, String> _map = {};
  static void set(int id, String name) => _map[id] = name;
  static String? get(int id) => _map[id];
}

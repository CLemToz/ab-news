import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/wp.dart';
import '../../theme/brand.dart';
import '../category_news/category_news_screen.dart';

/// WP Category (with optional imageUrl provided by your plugin)
class WPCategory {
  final int id;
  final String name;
  final String slug;
  final int count;
  final String? imageUrl;

  WPCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
    this.imageUrl,
  });

  /// Try many common plugin field names / structures
  static String? _extractImageUrl(Map<String, dynamic> j) {
    // Flat common keys
    for (final k in const [
      'image',
      'image_url',
      'thumbnail',
      'category_image',
      'category_thumbnail',
      'icon',
      'picture',
      'cover',
    ]) {
      final v = j[k];
      if (v is String && v.isNotEmpty) return v;
      if (v is Map && v['url'] is String && (v['url'] as String).isNotEmpty) {
        return v['url'];
      }
    }

    // ACF (Advanced Custom Fields)
    try {
      final acf = j['acf'];
      if (acf is Map) {
        final img = acf['image'];
        if (img is String && img.isNotEmpty) return img;
        if (img is Map && img['url'] is String && (img['url'] as String).isNotEmpty) {
          return img['url'];
        }
        // if you named it differently, add here (e.g. acf['category_icon'])
      }
    } catch (_) {}

    // meta[...] variants some plugins use
    try {
      final meta = j['meta'];
      if (meta is Map) {
        for (final k in const [
          'image',
          'image_url',
          'thumbnail',
          'category_image',
          'category_thumbnail',
          'icon'
        ]) {
          final v = meta[k];
          if (v is String && v.isNotEmpty) return v;
          if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
        }
      }
    } catch (_) {}

    // nothing found
    return null;
  }

  factory WPCategory.fromJson(Map<String, dynamic> j) => WPCategory(
    id: j['id'] ?? 0,
    name: (j['name'] ?? '').toString(),
    slug: (j['slug'] ?? '').toString(),
    count: j['count'] is int ? j['count'] : int.tryParse('${j['count']}') ?? 0,
    imageUrl: _extractImageUrl(j),
  );
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _search = TextEditingController();

  bool _loading = true;
  bool _error = false;
  List<WPCategory> _items = [];

  // Local fallback names (used when WP URL empty)
  static const List<String> _fallbackNames = [
    'Breaking News','More','अध्यात्म','ज्योतिष','इंटरनेशनल','एक्सप्लेनर','एजुकेशन',
    'ऑटो','क्रिकेट','नेशनल','नौकरी कॅरियर','न्यूज एंड पॉलिटिक्स','बिजनेस','बॉलीवुड',
    'ज्ञान','मौसम','राज्य खबर','क्राइम न्यूज','लाइफस्टाइल','वायरल','स्पेशल','स्पोर्ट',
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      if (WPConfig.baseUrl.isEmpty) {
        _items = _fallbackNames
            .map((n) => WPCategory(id: n.hashCode, name: n, slug: n, count: 0))
            .toList();
      } else {
        // TIP: Start WITHOUT _fields to see what your plugin returns.
        // After confirming keys in your JSON, you can re-add _fields for smaller payloads.
        final uri = Uri.parse(
            '${WPConfig.baseUrl}/wp-json/wp/v2/categories?per_page=100'
          // If you already know the fields your plugin returns, you can restrict:
          // '&_fields=id,name,slug,count,image,image_url,thumbnail,category_image,acf,meta'
        );
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List;
          _items = list.map((e) => WPCategory.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          throw Exception('HTTP ${res.statusCode}');
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _refresh() async => _fetch();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();

    final visible = _items.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) || c.slug.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 0),
          child: Text(
            'Categories',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: Brand.red,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Header: search + count
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(bottom: BorderSide(color: cs.outlineVariant, width: .5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SearchField(controller: _search),
                      const SizedBox(height: 10),
                      Text(
                        _loading ? 'Loading…' : '${visible.length} categories',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: _CategoriesGridSkeleton(),
              )
            else if (_error)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.wifi_tethering_error_rounded, size: 56, color: cs.error),
                        const SizedBox(height: 10),
                        Text('Failed to load categories',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Brand.red, foregroundColor: Colors.white),
                          onPressed: _fetch,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.18,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final c = visible[i];
                      return _CategoryTile(
                        title: c.name,
                        imageUrl: c.imageUrl, // ← uses plugin image if provided
                        badge: c.count > 0 ? '${c.count}' : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryNewsScreen(category: c.name),
                            ),
                          );
                        },
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search categories',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Brand.red, width: 1.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String? imageUrl; // now optional
  final String? badge;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.imageUrl,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with placeholder/error handling
            if ((imageUrl ?? '').isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: cs.surfaceVariant),
                errorWidget: (_, __, ___) =>
                    Container(color: cs.surfaceVariant, child: const Icon(Icons.image_outlined)),
              )
            else
              Container(color: cs.surfaceVariant),

            // gradient overlay for legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(.45), Colors.black.withOpacity(.0)],
                ),
              ),
            ),

            // Label + count badge
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(.4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Brand.red, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          badge!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton grid for categories (simple gray boxes)
class _CategoriesGridSkeleton extends StatelessWidget {
  const _CategoriesGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.18,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, i) => Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        childCount: 6,
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/wp.dart';
import '../theme/brand.dart';
import '../features/category_news/category_news_screen.dart';

/// Lightweight model (kept local to this widget to avoid cross-file deps)
class _WpCat {
  final int id;
  final String name;
  final String slug;
  final int count;
  final String? imageUrl;
  _WpCat({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
    this.imageUrl,
  });

  factory _WpCat.fromJson(Map<String, dynamic> j) => _WpCat(
    id: j['id'] ?? 0,
    name: (j['name'] ?? '').toString(),
    slug: (j['slug'] ?? '').toString(),
    count:
    j['count'] is int ? j['count'] : int.tryParse('${j['count']}') ?? 0,
    imageUrl: (() {
      // prefer plugin field
      final u = j['image_url'];
      if (u is String && u.isNotEmpty) return u;
      // fallback names if you ever switch plugins/ACF
      for (final k in const ['image', 'thumbnail', 'category_image']) {
        final v = j[k];
        if (v is String && v.isNotEmpty) return v;
        if (v is Map &&
            v['url'] is String &&
            (v['url'] as String).isNotEmpty) {
          return v['url'];
        }
      }
      // ACF fallback (if ACF field named "image")
      final acf = j['acf'];
      if (acf is Map) {
        final img = acf['image'];
        if (img is String && img.isNotEmpty) return img;
        if (img is Map &&
            img['url'] is String &&
            (img['url'] as String).isNotEmpty) {
          return img['url'];
        }
      }
      return null;
    })(),
  );
}

/// Horizontal list of categories with their images (from REST).
class WpCategoriesHorizontal extends StatefulWidget {
  /// Optionally limit how many categories to show
  final int maxItems;

  /// Optionally limit to these category IDs (e.g., highlighted ones)
  final List<int>? onlyIds;

  /// When true → fetch from /ab/v1/highlighted-categories
  final bool highlightedOnly;

  const WpCategoriesHorizontal({
    super.key,
    this.maxItems = 12,
    this.onlyIds,
    this.highlightedOnly = false,
  });

  @override
  State<WpCategoriesHorizontal> createState() => _WpCategoriesHorizontalState();
}

class _WpCategoriesHorizontalState extends State<WpCategoriesHorizontal> {
  bool _loading = true;
  bool _error = false;
  List<_WpCat> _items = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (WPConfig.baseUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final base = WPConfig.baseUrl;
      final path = widget.highlightedOnly
          ? '$base/wp-json/ab/v1/highlighted-categories'
          : '$base/wp-json/wp/v2/categories';
      final qs = widget.highlightedOnly
          ? '?per_page=100'
          : '?per_page=100&orderby=count&order=desc&_fields=id,name,slug,count,image_url,acf';
      final uri = Uri.parse('$path$qs');

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final list = (jsonDecode(res.body) as List)
          .map((e) => _WpCat.fromJson(e as Map<String, dynamic>))
          .toList();

      // Optional filter: show only selected IDs
      List<_WpCat> filtered = list;
      if (widget.onlyIds != null && widget.onlyIds!.isNotEmpty) {
        final set = widget.onlyIds!.toSet();
        filtered = list.where((c) => set.contains(c.id)).toList();
      }

      if (filtered.length > widget.maxItems) {
        filtered = filtered.take(widget.maxItems).toList();
      }

      if (!mounted) return;
      setState(() {
        _items = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (_, __) => Container(
            width: 220,
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: 4,
        ),
      );
    }

    if (_error || _items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'No categories',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = _items[i];
          return _CategoryCard(
            title: c.name,
            imageUrl: c.imageUrl,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryNewsScreen(
                    category: c.name,
                    categoryId: c.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 220,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if ((imageUrl ?? '').isNotEmpty)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: cs.surfaceVariant),
                )
              else
                Container(color: cs.surfaceVariant),

              // fade overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(.45),
                      Colors.transparent
                    ],
                  ),
                ),
              ),

              // title text
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

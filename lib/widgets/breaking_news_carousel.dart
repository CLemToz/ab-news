import 'dart:async';
import 'package:flutter/material.dart';

/// Minimal “dynamic article” contract used here:
/// item.title, item.excerpt/summary, item.imageUrl, item.thumbnail
typedef OnArticleTap = void Function(dynamic article);

class BreakingNewsCarousel extends StatefulWidget {
  final List<dynamic> items;
  final OnArticleTap onTap;

  const BreakingNewsCarousel({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  State<BreakingNewsCarousel> createState() => _BreakingNewsCarouselState();
}

class _BreakingNewsCarouselState extends State<BreakingNewsCarousel> {
  late final PageController _pc;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: .92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.items.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _index = (_index + 1) % widget.items.length;
      _pc.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant BreakingNewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _index = 0;
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  T? _get<T>(dynamic item, T? Function() read) {
    try { return read(); } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pc,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final a = widget.items[i];
              final title = _get<String>(a, () => a.title) ?? '';
              final sub   = _get<String>(a, () => a.summary) ??
                  _get<String>(a, () => a.excerpt) ?? '';
              final img   = _get<String>(a, () => a.imageUrl) ??
                  _get<String>(a, () => a.thumbnail) ?? '';

              return GestureDetector(
                onTap: () => widget.onTap(a),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (img.isNotEmpty)
                          Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: cs.surfaceVariant),
                          )
                        else
                          Container(color: cs.surfaceVariant),

                        // gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(.55),
                                Colors.black.withOpacity(.05),
                              ],
                            ),
                          ),
                        ),

                        // texts
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (sub.isNotEmpty)
                                Text(
                                  sub,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/category_item.dart';

class SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback onViewAll;
  final EdgeInsets padding;
  final Color? color; // NEW: highlight color

  const SectionHeader({
    super.key,
    required this.label,
    required this.onViewAll,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.color, // if null, falls back to theme.primary
  });

  @override
  Widget build(BuildContext context) {
    final highlight = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // subtle filled chip with thin border — minimal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: highlight.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: highlight.withOpacity(.90), width: 1.5),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: highlight,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onViewAll,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('View All', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}



class TagChip extends StatelessWidget {
  final String text;
  const TagChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 120, // ✅ Limit chip width
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // ✅ Truncate long text
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Auto-scrolling ticker (no extra packages)
class TickerStrip extends StatefulWidget {
  final String text;
  const TickerStrip({super.key, required this.text});

  @override
  State<TickerStrip> createState() => _TickerStripState();
}

class _TickerStripState extends State<TickerStrip> {
  late final ScrollController _sc;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _startScrolling() async {
    if (!mounted) return;
    // Define speed, e.g., 35 pixels per second
    const double pixelsPerSecond = 35.0;

    while (mounted) {
      // small delay between loops
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_sc.hasClients) return;

      final maxScroll = _sc.position.maxScrollExtent;
      final durationInSeconds = maxScroll / pixelsPerSecond;

      // don't animate if not overflowing
      if (durationInSeconds <= 0) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      
      if (!mounted) return;

      // Animate to end
      await _sc.animateTo(
        maxScroll,
        duration: Duration(seconds: durationInSeconds.round()),
        curve: Curves.linear,
      );

      // Wait a bit at the end before jumping
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_sc.hasClients) return;

      // Jump back to start for the loop
      _sc.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      color: cs.surfaceContainerHighest,
      child: ListView(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(width: 16),
          Center(child: Text(widget.text, style: TextStyle(color: cs.onSurfaceVariant))),
          const SizedBox(width: 32), // gap between repetitions
          Center(child: Text(widget.text, style: TextStyle(color: cs.onSurfaceVariant))),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

/// “Quick Read” promo card
class QuickReadCard extends StatelessWidget {
  const QuickReadCard({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 72, height: 72,
              child: Stack(children: [
                Positioned(top: 0, right: 0, child: _dot(cs.primary, 14)),
                Positioned(bottom: 4, left: 8, child: _dot(cs.tertiary, 18)),
                Positioned(top: 28, left: 22, child: _pill(cs.secondary)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick Read', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('In hurry? Read article like a pro.', style: TextStyle(color: cs.onSurfaceVariant)),
              ]),
            ),
            FilledButton(onPressed: () {}, child: const Text('Try')),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c, double s) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  Widget _pill(Color c) => Container(width: 10, height: 42, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)));
}


class HorizontalCategoryList extends StatelessWidget {
  final List<CategoryItem> items;
  final void Function(CategoryItem) onTap;
  const HorizontalCategoryList({super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = items[i];
          return InkWell(
            onTap: () => onTap(c),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // tile size
                  SizedBox(
                    width: 160,
                    height: 120,
                    child: Image.network(c.imageUrl, fit: BoxFit.cover),
                  ),
                  Positioned.fill(child: Container(color: Colors.black26)),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Category', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

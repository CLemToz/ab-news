import 'package:flutter/material.dart';

/// Tiny shimmer-like effect without extra packages.
/// (Same visual language as your existing VideoSectionShimmer)
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? radius;
  const _ShimmerBox({required this.height, required this.width, this.radius});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant;
    final hi   = base.withOpacity(.55);
    final lo   = base.withOpacity(.25);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeInOut,
      builder: (context, v, _) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: radius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2*v, 0),
              end: Alignment(1 + 2*v, 0),
              colors: [lo, hi, lo],
            ),
          ),
        );
      },
    );
  }
}

/// Breaking news big card placeholder
class BreakingNewsShimmer extends StatelessWidget {
  const BreakingNewsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            const _ShimmerBox(height: 210, width: double.infinity),
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBox(height: 14, width: 180),
                  SizedBox(height: 8),
                  _ShimmerBox(height: 12, width: 260),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal highlighted-categories skeleton
class CategoriesRailShimmer extends StatelessWidget {
  const CategoriesRailShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const _ShimmerBox(height: 120, width: 160),
      ),
    );
  }
}

/// Recent list skeleton (3 items)
class RecentListShimmer extends StatelessWidget {
  const RecentListShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: const [
            _ShimmerBox(height: 84, width: 120),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  _ShimmerBox(height: 12, width: 180),
                  SizedBox(height: 8),
                  _ShimmerBox(height: 12, width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

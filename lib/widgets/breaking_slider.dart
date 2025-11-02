import 'package:flutter/material.dart';
import '../services/wp_api.dart';
import '../models/wp_post.dart';
import '../theme/brand.dart';
import '../features/category_news/wp_article_screen.dart';

/// API-driven slider for a specific WP category by numeric ID.
/// Usage:
///   BreakingSlider(categoryId: 123, perPage: 5)
class BreakingSlider extends StatelessWidget {
  final int categoryId;
  final int perPage;

  const BreakingSlider({
    super.key,
    required this.categoryId,
    this.perPage = 5,
  }) : assert(perPage > 0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<WPPost>>(
      future: WpApi.fetchPosts(categoryId: categoryId, page: 1, perPage: perPage),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loading(cs);
        }
        if (snap.hasError) {
          return _error('Failed to load breaking news', cs);
        }
        final list = snap.data ?? const <WPPost>[];
        if (list.isEmpty) {
          return _error('No breaking news', cs);
        }
        return _Slider(list: list);
      },
    );
  }

  Widget _loading(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _error(String msg, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

class _Slider extends StatefulWidget {
  final List<WPPost> list;
  const _Slider({required this.list});

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  final _page = PageController(viewportFraction: 1.0);
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = widget.list;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final p = items[i];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WpArticleScreen(post: p)),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // image
                        if (p.imageUrl.isNotEmpty)
                          Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: cs.surfaceVariant),
                          )
                        else
                          Container(color: cs.surfaceVariant),

                        // gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // title
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Text(
                            p.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // dots
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: active ? 16 : 6,
                      decoration: BoxDecoration(
                        color: active ? Brand.red : Colors.white70,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/mock_data.dart'; // your articles source
import 'common.dart'; // TagChip
import '../models/wp_post.dart';
import 'save_toggle_button.dart';

class RecentNewsItem extends StatefulWidget {
  final dynamic article; // NewsArticle from mock_data.dart
  final VoidCallback? onTap;
  final bool initiallySaved;

  /// When provided, this text is shown in the chip
  /// (use the screen's category so it always matches the section).
  final String? displayCategory;

  const RecentNewsItem({
    super.key,
    required this.article,
    this.onTap,
    this.initiallySaved = false,
    this.displayCategory,
  });

  @override
  State<RecentNewsItem> createState() => _RecentNewsItemState();
}

class _RecentNewsItemState extends State<RecentNewsItem> {
  bool _saved = false;

  // Tune these to make the image a bit larger
  static const double _thumbW = 120; // wider image
  static const double _thumbH = 120; // square-ish with round corners

  String _dateOnly(String s) {
    if (s.isEmpty) return s;

    // If there's a time like "9:05 AM", cut everything from there
    final m = RegExp(r'\d{1,2}:\d{2}\s*(AM|PM|am|pm)?').firstMatch(s);
    if (m != null) {
      s = s.substring(0, m.start).trim();
    }

    // Clean trailing separators (•, ·, |, -, ,)
    s = s.replaceAll(RegExp(r'[•·\|\-,]\s*$'), '').trim();
    return s;
  }

  @override
  void initState() {
    super.initState();
    _saved = widget.initiallySaved;
  }

  /// Safe getter to avoid NoSuchMethodError on dynamic
  T? _get<T>(T? Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareOnWhatsApp() async {
    // Safe getter
    String _s(String? Function() r) {
      try {
        final v = r();
        return (v ?? '').trim();
      } catch (_) {
        return '';
      }
    }

    // --- Extract post fields ---
    final title = _s(() => widget.article.title);
    final summary0 = _s(() => widget.article.summary).isNotEmpty
        ? _s(() => widget.article.summary)
        : (_s(() => widget.article.excerpt).isNotEmpty
              ? _s(() => widget.article.excerpt)
              : _s(() => widget.article.subtitle));
    final postUrl = (() {
      final u1 = _s(() => widget.article.url);
      final u2 = _s(() => widget.article.link);
      return u1.isNotEmpty ? u1 : u2;
    })();

    // --- Text cleanup ---
    String _stripHtml(String s) => s
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    String _truncate(String s, int max) =>
        s.length <= max ? s : (s.substring(0, max).trimRight() + '…');

    final desc = _truncate(_stripHtml(summary0), 160);

    // --- ✨ Build WhatsApp message with emojis + bold title ---
    final parts = <String>[
      if (title.isNotEmpty) "📰 *$title*", // <-- bold title
      if (desc.isNotEmpty) "🗞️ $desc",
      if (postUrl.isNotEmpty) "👉 $postUrl", // clean single link
      "\n📱 Read this story on DK News Plus App!",
    ];

    final message = parts.join('\n\n');
    final encoded = Uri.encodeComponent(message);

    final deepLink = Uri.parse('whatsapp://send?text=$encoded');
    final webLink = Uri.parse('https://wa.me/?text=$encoded');

    try {
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink);
      } else {
        await launchUrl(webLink, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final cs = Theme.of(context).colorScheme;

    final title = _get<String>(() => a.title) ?? '';
    final desc =
        _get<String>(() => a.summary) ??
        _get<String>(() => a.subtitle) ??
        _get<String>(() => a.excerpt) ??
        '';
    final image =
        _get<String>(() => a.imageUrl) ?? _get<String>(() => a.thumbnail) ?? '';
    final categoryFromPost = _get<String>(() => a.category) ?? 'General';
    final category = (widget.displayCategory?.trim().isNotEmpty ?? false)
        ? widget.displayCategory!.trim()
        : categoryFromPost;

    final dateText =
        _get<String>(() => a.timeAgo) ??
        _get<String>(() => a.publishedAtString) ??
        _get<String>(() => a.published) ??
        _get<String>(() => a.dateString) ??
        '';
    final displayDate = _dateOnly(dateText);

    final isVideo = _get<bool>(() => a.isVideo) ?? false;
    final duration = _get<String>(() => a.videoDuration) ?? '';

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ------- Title/desc + bigger thumbnail -------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: title + description
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title (2 lines)
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            // Description (3 lines)
                            Text(
                              desc,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Right: bigger thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: cs.surfaceVariant,
                          width: _thumbW,
                          height: _thumbH,
                          child: image.isEmpty
                              ? _thumbPlaceholder(cs)
                              : Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _thumbPlaceholder(cs),
                                ),
                        ),
                        if (isVideo)
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white70,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        if (duration.isNotEmpty)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ------- Meta & actions (time moved to its own line) -------
              Row(
                children: [
                  TagChip(text: category),

                  // Full-width time (NO truncation)
                  if (displayDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          displayDate, // <-- was dateText
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  _iconBtn(
                    onPressed: _shareOnWhatsApp,
                    tooltip: 'Share on WhatsApp',
                    child: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366),
                      size: 20,
                    ),
                  ),
                  _iconBtn(
                    onPressed: () => setState(() => _saved = !_saved),
                    tooltip: _saved ? 'Saved' : 'Save',
                    child: Icon(
                      _saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // subtle divider for card separation
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact icon button to avoid overflow
  Widget _iconBtn({
    required Widget child,
    String? tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: child,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _thumbPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceVariant,
      child: Icon(Icons.image_outlined, color: cs.outline, size: 26),
    );
  }
}

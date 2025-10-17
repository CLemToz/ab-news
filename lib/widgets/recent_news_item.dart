import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/mock_data.dart'; // your articles source
import 'common.dart';            // TagChip

class RecentNewsItem extends StatefulWidget {
  final dynamic article; // NewsArticle from mock_data.dart
  final VoidCallback? onTap;
  final bool initiallySaved;

  const RecentNewsItem({
    super.key,
    required this.article,
    this.onTap,
    this.initiallySaved = false,
  });

  @override
  State<RecentNewsItem> createState() => _RecentNewsItemState();
}

class _RecentNewsItemState extends State<RecentNewsItem> {
  bool _saved = false;

  // Tune these to make the image a bit larger
  static const double _thumbW = 160; // wider image
  static const double _thumbH = 100; // ~16:10 look with round corners

  @override
  void initState() {
    super.initState();
    _saved = widget.initiallySaved;
  }

  /// Safe getter to avoid NoSuchMethodError on dynamic
  T? _get<T>(T? Function() read) {
    try { return read(); } catch (_) { return null; }
  }

  Future<void> _shareOnWhatsApp() async {
    final title = _get<String>(() => widget.article.title) ?? '';
    final url   = _get<String>(() => widget.article.url) ?? '';
    final text  = Uri.encodeComponent('$title ${url.isNotEmpty ? url : ''}');
    final uri   = Uri.parse('whatsapp://send?text=$text');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final web = Uri.parse('https://wa.me/?text=$text');
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share on WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a  = widget.article;
    final cs = Theme.of(context).colorScheme;

    final title = _get<String>(() => a.title) ?? '';
    final desc  = _get<String>(() => a.summary) ??
        _get<String>(() => a.subtitle) ??
        _get<String>(() => a.excerpt) ??
        '';
    final image = _get<String>(() => a.imageUrl) ??
        _get<String>(() => a.thumbnail) ?? '';
    final category = _get<String>(() => a.category) ?? 'General';
    final dateText = _get<String>(() => a.timeAgo) ??
        _get<String>(() => a.publishedAtString) ??
        _get<String>(() => a.published) ??
        _get<String>(() => a.dateString) ?? '•';
    final isVideo  = _get<bool>(() => a.isVideo) ?? false;
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            errorBuilder: (_, __, ___) => _thumbPlaceholder(cs),
                          ),
                        ),
                        if (isVideo)
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 1),
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          ),
                        if (duration.isNotEmpty)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

              // ------- Meta row (left) + actions (right) -------
              Row(
                children: [
                  // Meta
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TagChip(text: category),
                        const SizedBox(width: 8),
                        Icon(Icons.circle, size: 4, color: cs.outline),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dateText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),

                  const Spacer(),

                  // Actions
                  _iconBtn(
                    onPressed: _shareOnWhatsApp,
                    tooltip: 'Share on WhatsApp',
                    child: const FaIcon(FontAwesomeIcons.whatsapp,
                        color: Color(0xFF25D366), size: 20),
                  ),
                  _iconBtn(
                    onPressed: () => setState(() => _saved = !_saved),
                    tooltip: _saved ? 'Saved' : 'Save',
                    child: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, size: 22),
                  ),
                ],
              ),

              // subtle divider for card separation
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Divider(height: 1, color: cs.outlineVariant.withOpacity(.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact icon button to avoid overflow
  Widget _iconBtn({required Widget child, String? tooltip, VoidCallback? onPressed}) {
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

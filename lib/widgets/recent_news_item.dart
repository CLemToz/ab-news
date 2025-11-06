import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/mock_data.dart'; // safe to keep
import 'common.dart';            // TagChip
import '../models/wp_post.dart';
import '../services/save_manager.dart'; // ✅ your SaveManager

class RecentNewsItem extends StatefulWidget {
  final dynamic article; // WPPost or mock
  final VoidCallback? onTap;
  final bool initiallySaved;
  final String? displayCategory;
  final void Function(bool isSaved)? onSavedChanged;

  const RecentNewsItem({
    super.key,
    required this.article,
    this.onTap,
    this.initiallySaved = false,
    this.displayCategory,
    this.onSavedChanged,
  });

  @override
  State<RecentNewsItem> createState() => _RecentNewsItemState();
}

class _RecentNewsItemState extends State<RecentNewsItem> {
  bool _saved = false;

  static const double _thumbW = 120;
  static const double _thumbH = 120;

  @override
  void initState() {
    super.initState();
    _saved = widget.initiallySaved;
    _initSavedIfWP();
  }

  Future<void> _initSavedIfWP() async {
    if (widget.article is WPPost) {
      final wp = widget.article as WPPost;
      final ok = await SaveManager.isSaved(wp.id ?? 0);
      if (mounted) setState(() => _saved = ok);
    }
  }

  T? _get<T>(T? Function() read) {
    try { return read(); } catch (_) { return null; }
  }

  String _dateOnly(String s) {
    if (s.isEmpty) return s;
    final m = RegExp(r'\d{1,2}:\d{2}\s*(AM|PM|am|pm)?').firstMatch(s);
    if (m != null) s = s.substring(0, m.start).trim();
    s = s.replaceAll(RegExp(r'[•·\|\-,]\s*$'), '').trim();
    return s;
  }

  Future<void> _shareOnWhatsApp() async {
    String _s(String? Function() r) {
      try { final v = r(); return (v ?? '').trim(); } catch (_) { return ''; }
    }
    final a = widget.article;
    final title   = _s(() => _get<String>(() => a.title));
    final summary = _s(() => _get<String>(() => a.summary));
    final subtitle= _s(() => _get<String>(() => a.subtitle));
    final excerpt = _s(() => _get<String>(() => a.excerpt));
    final postUrl = (() {
      final u1 = _s(() => _get<String>(() => a.url));
      final u2 = _s(() => _get<String>(() => a.link));
      return u1.isNotEmpty ? u1 : u2;
    })();

    String _stripHtml(String s) => s
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String _truncate(String s, int max) =>
        s.length <= max ? s : (s.substring(0, max).trimRight() + '…');

    final rawDesc = summary.isNotEmpty ? summary : (excerpt.isNotEmpty ? excerpt : subtitle);
    final desc = _truncate(_stripHtml(rawDesc), 160);

    final encoded = Uri.encodeComponent([
      if (title.isNotEmpty) "📰 *$title*",
      if (desc.isNotEmpty)  "🗞️ $desc",
      if (postUrl.isNotEmpty) "👉 $postUrl",
      "\n📱 Read this on DA News Plus App!",
    ].join('\n\n'));

    final deepLink = Uri.parse('whatsapp://send?text=$encoded');
    final webLink  = Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink);
      } else {
        await launchUrl(webLink, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp')));
    }
  }

  Future<void> _toggleSave() async {
    if (widget.article is! WPPost) {
      // Mock article: show hint (no persistence)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving works for website news posts')),
      );
      return;
    }
    final wp = widget.article as WPPost;
    final already = await SaveManager.isSaved(wp.id ?? -1);
    if (already) {
      await SaveManager.remove(wp);
      if (mounted) setState(() => _saved = false);
      widget.onSavedChanged?.call(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Saved')),
      );
    } else {
      await SaveManager.save(wp);
      if (mounted) setState(() => _saved = true);
      widget.onSavedChanged?.call(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
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
        _get<String>(() => a.excerpt) ?? '';
    final image = _get<String>(() => a.imageUrl) ??
        _get<String>(() => a.thumbnail) ?? '';
    final categoryFromPost = _get<String>(() => a.category) ?? 'General';
    final category = (widget.displayCategory?.trim().isNotEmpty ?? false)
        ? widget.displayCategory!.trim()
        : categoryFromPost;

    final dateText = _get<String>(() => a.timeAgo) ??
        _get<String>(() => a.publishedAtString) ??
        _get<String>(() => a.published) ??
        _get<String>(() => a.dateString) ?? '';
    final displayDate = _dateOnly(dateText);

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800, height: 1.25),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant, height: 1.25),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // image
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
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 1),
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          ),
                        if (duration.isNotEmpty)
                          Positioned(
                            right: 6, bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87, borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                duration,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // meta + actions
              Row(
                children: [
                  TagChip(text: category),
                  if (displayDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        displayDate,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const Spacer(),
                  _iconBtn(
                    onPressed: _shareOnWhatsApp,
                    tooltip: 'Share on WhatsApp',
                    child: const FaIcon(
                        FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 20),
                  ),
                  _iconBtn(
                    onPressed: _toggleSave,
                    tooltip: _saved ? 'Saved' : 'Save',
                    child: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, size: 22, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 6),

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

  Widget _iconBtn({
    required Widget child,
    String? tooltip,
    VoidCallback? onPressed,
  }) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: child,
    padding: const EdgeInsets.symmetric(horizontal: 2),
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    visualDensity: VisualDensity.compact,
  );

  Widget _thumbPlaceholder(ColorScheme cs) => Container(
    color: cs.surfaceVariant,
    child: Icon(Icons.image_outlined, color: cs.outline, size: 26),
  );
}

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// HTML rendering packages (no fwfh_webview here)
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_cached_network_image/fwfh_cached_network_image.dart';
import 'package:fwfh_svg/fwfh_svg.dart';
import 'package:fwfh_chewie/fwfh_chewie.dart' as fwfh_chewie;

import '../../models/wp_post.dart';
import '../../theme/brand.dart';
import '../../widgets/common.dart';

class WpArticleScreen extends StatelessWidget {
  final WPPost post;
  const WpArticleScreen({super.key, required this.post});

  // --- WhatsApp Share ---
  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final title = post.title.isNotEmpty ? "📰 *${post.title.trim()}*" : '';
    final link = post.url.isNotEmpty ? "\n👉 ${post.url}" : '';
    final message = Uri.encodeComponent("$title$link\n\n📱 Read this on DK News Plus App!");

    final deepLink = Uri.parse('whatsapp://send?text=$message');
    final webLink  = Uri.parse('https://wa.me/?text=$message');

    try {
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink);
      } else {
        await launchUrl(webLink, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Top row: category chip + WA share (replaces views)
          Row(
            children: [
              TagChip(text: post.category.isNotEmpty ? post.category : 'News'),
              const Spacer(),
              IconButton(
                tooltip: 'Share on WhatsApp',
                onPressed: () => _shareOnWhatsApp(context),
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Featured image (graceful fallback)
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(cs),
              ),
            ),

          const SizedBox(height: 12),

          // Author & time
          Row(
            children: [
              // You can switch this to an AssetImage if you’ve added your logo to assets
              const CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/faviconsize.jpg'),
              ),
              const SizedBox(width: 10),
              Text(
                "DK News Plus",
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Text('•  ${post.timeAgo}', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),

          const SizedBox(height: 16),

          // FULL HTML body (images, <video>, svg, links; iframe opens externally)
          _ArticleHtml(html: post.contentRendered),

          const SizedBox(height: 16),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(0, 0, 0, 8), // avoids nav bar / notches
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Share.share(post.url),
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(ColorScheme cs) => Container(
    height: 200,
    color: cs.surfaceVariant,
    child: const Center(child: Icon(Icons.broken_image, size: 40)),
  );
}

//
// HTML renderer widget (no fwfh_webview; iframes open externally)
//
class _ArticleHtml extends StatelessWidget {
  final String html;
  const _ArticleHtml({required this.html});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6);

    return HtmlWidget(
      html,
      factoryBuilder: () => _WPHtmlFactory(),
      textStyle: textStyle,
      renderMode: RenderMode.column,

      // Convert <iframe src="..."> to a tappable card that opens externally
      customWidgetBuilder: (element) {
        if (element.localName == 'iframe') {
          final src = element.attributes['src'] ?? '';
          if (src.isEmpty) return null;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => launchUrl(Uri.parse(src), mode: LaunchMode.externalApplication),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0x11000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Open video',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }
        return null;
      },

      // Normalize margins to remove big empty gaps
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'p':
          case 'ul':
          case 'ol':
          case 'blockquote':
          case 'h1':
          case 'h2':
          case 'h3':
          case 'h4':
          case 'h5':
          case 'h6':
            return {'margin': '0 0 12px 0'};
        }
        return null;
      },

      // Make links open externally
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
        return false;
      },
    );
  }
}

//
// Factory: handles <img>, <video>, SVGs (no WebView mixin)
//
class _WPHtmlFactory extends WidgetFactory
    with
        CachedNetworkImageFactory,     // <img> with caching
        fwfh_chewie.ChewieFactory,     // <video> with Chewie/VideoPlayer
        SvgFactory {}                  // inline SVGs

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/brand.dart';
import '../../services/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Color get _red => Brand.red;                // your theme red
  Color get _blue => Colors.blue;             // theme blue (use your Brand.blue if you have it)

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _LoginCard(accentRed: _red, accentBlue: _blue),

          const SizedBox(height: 16),
          _SectionTitle('General'),

          const SizedBox(height: 8),
          _InviteTile(accent: _blue),

          const SizedBox(height: 8),
          const _FontSizeTile(),   // global font size

          const SizedBox(height: 8),
          const _ThemeModeTile(),  // nicer light/dark toggle

          const SizedBox(height: 20),
          _SectionTitle('Watch our channel'),

          const SizedBox(height: 8),
          _ChannelButtons(
            red: _red,
            items: const [
              _ChannelLink(
                name: 'Airtel Xstream',
                subtitle: 'Open on Airtel Xstream',
                url: 'https://open.airtelxstream.in/o8OEPcoYxXb',
                icon: Icons.play_circle_fill_rounded,
              ),
              _ChannelLink(
                name: 'JioTV',
                subtitle: 'Open on JioTV',
                url: 'https://l.tv.jio/fc6dc245',
                icon: Icons.live_tv_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: .2,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final Color accentRed;
  final Color accentBlue;
  const _LoginCard({required this.accentRed, required this.accentBlue});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentRed.withOpacity(.95), accentBlue.withOpacity(.95)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log in to sync your saved news & preferences across devices.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              // TODO: hook your auth flow here later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login coming soon')),
              );
            },
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final Color accent;
  const _InviteTile({required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: accent.withOpacity(.08),
      leading: CircleAvatar(
        backgroundColor: accent.withOpacity(.15),
        child: const Icon(Icons.send_rounded),
      ),
      title: const Text('Invite friends'),
      subtitle: const Text('Share the app with your friends & family'),
      trailing: FilledButton.tonalIcon(
        onPressed: () {
          Share.share(
            'Hey! Check out DA News Plus app — fast local news & reels.\n'
                'Download: https://example.com/app', // replace with your link
          );
        },
        icon: const Icon(Icons.ios_share_rounded),
        label: const Text('Invite'),
      ),
    );
  }
}

/// Global font-size control (persists & updates app via AppSettings)
class _FontSizeTile extends StatefulWidget {
  const _FontSizeTile();

  @override
  State<_FontSizeTile> createState() => _FontSizeTileState();
}

class _FontSizeTileState extends State<_FontSizeTile> {
  double _value = AppSettings.I.fontScale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields_rounded),
              const SizedBox(width: 10),
              const Text('Font size'),
              const Spacer(),
              Text('${(_value * 100).round()}%'),
            ],
          ),
          Slider(
            value: _value,
            min: 0.85,
            max: 1.4,
            divisions: 11,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => AppSettings.I.setFontScale(v),
          ),
        ],
      ),
    );
  }
}

/// Pretty theme toggle (System / Light / Dark)
class _ThemeModeTile extends StatefulWidget {
  const _ThemeModeTile();

  @override
  State<_ThemeModeTile> createState() => _ThemeModeTileState();
}

class _ThemeModeTileState extends State<_ThemeModeTile> {
  ThemeMode _mode = AppSettings.I.themeMode;

  Widget _chip(String label, IconData icon, ThemeMode mode, ColorScheme cs) {
    final selected = _mode == mode;
    return ChoiceChip(
      selected: selected,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : cs.primary),
      label: Text(label),
      selectedColor: cs.primary,
      onSelected: (_) {
        setState(() => _mode = mode);
        AppSettings.I.setThemeMode(mode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.dark_mode_rounded),
            SizedBox(width: 10),
            Text('Appearance'),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('System', Icons.phone_iphone_rounded, ThemeMode.system, cs),
              _chip('Light',  Icons.wb_sunny_rounded,   ThemeMode.light,  cs),
              _chip('Dark',   Icons.dark_mode_rounded,  ThemeMode.dark,   cs),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelLink {
  final String name;
  final String subtitle;
  final String url;
  final IconData icon;
  const _ChannelLink({
    required this.name,
    required this.subtitle,
    required this.url,
    required this.icon,
  });
}

class _ChannelButtons extends StatelessWidget {
  final List<_ChannelLink> items;
  final Color red;
  const _ChannelButtons({required this.items, required this.red});

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'failed';
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: items.map((e) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10).copyWith(right: e == items.last ? 0 : 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(e.icon, size: 28, color: red),
                const SizedBox(height: 10),
                Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(e.subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () => _open(e.url, context),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

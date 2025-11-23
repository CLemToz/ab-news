import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/app_settings.dart';
import '../../services/auth_service.dart';
import '../../theme/brand.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Color get _red => Brand.red;
  Color get _blue => Colors.blue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
          const _FontSizeTile(),
          const SizedBox(height: 8),
          const _ThemeModeTile(),
          const SizedBox(height: 20),
          _SectionTitle('Watch our channels'),
          const SizedBox(height: 10),
          const _ChannelButtons(), // new logo cards
          const SizedBox(height: 20),
          _SectionTitle('Follow us'),
          const SizedBox(height: 10),
          const _SocialMediaLinks(),
          const SizedBox(height: 30),
          Center(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://amigonex.com/'),
                  mode: LaunchMode.externalApplication),
              child: const Text(
                'Developed by AmigoNex',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
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
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .2),
  );
}

class _LoginCard extends StatefulWidget {
  final Color accentRed;
  final Color accentBlue;

  const _LoginCard({required this.accentRed, required this.accentBlue});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final AuthService _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return _buildLoggedInCard(user, cs);
        } else {
          return _buildLoggedOutCard(cs);
        }
      },
    );
  }

  Widget _buildLoggedOutCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentRed.withOpacity(.95),
            widget.accentBlue.withOpacity(.95)
          ],
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
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Log in to sync your saved news & preferences across devices.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const LoginScreen(),
                fullscreenDialog: true,
              ));
            },
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInCard(User user, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentRed.withOpacity(.95),
            widget.accentBlue.withOpacity(.95)
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.displayName ?? 'User'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
  Widget build(BuildContext context) => ListTile(
    shape:
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    tileColor: accent.withOpacity(.08),
    leading: CircleAvatar(
      backgroundColor: accent.withOpacity(.15),
      child: const Icon(Icons.send_rounded),
    ),
    title: const Text('Invite friends'),
    subtitle: const Text('Share the app with your friends & family'),
    trailing: FilledButton.tonalIcon(
      onPressed: () => Share.share(
          'Hey! Check out DA News Plus app — fast local news & reels.\n'
              'Download: https://example.com/app'),
      icon: const Icon(Icons.ios_share_rounded),
      label: const Text('Invite'),
    ),
  );
}

/// Global font-size control
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

/// Pretty theme toggle without tick marks
class _ThemeModeTile extends StatefulWidget {
  const _ThemeModeTile();

  @override
  State<_ThemeModeTile> createState() => _ThemeModeTileState();
}

class _ThemeModeTileState extends State<_ThemeModeTile> {
  ThemeMode _mode = AppSettings.I.themeMode;

  Widget _chip(String label, IconData icon, ThemeMode mode, ColorScheme cs) {
    final selected = _mode == mode;
    final bg = selected ? cs.primary.withOpacity(0.15) : cs.surface;
    final borderColor =
    selected ? cs.primary : cs.outlineVariant.withOpacity(0.4);
    final textColor =
    selected ? cs.primary : cs.onSurfaceVariant.withOpacity(0.9);

    return GestureDetector(
      onTap: () {
        setState(() => _mode = mode);
        AppSettings.I.setThemeMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Text(label,
              style:
              TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        ]),
      ),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip('System', Icons.phone_iphone_rounded,
                  ThemeMode.system, cs),
              _chip('Light', Icons.wb_sunny_rounded, ThemeMode.light, cs),
              _chip('Dark', Icons.dark_mode_rounded, ThemeMode.dark, cs),
            ],
          ),
        ],
      ),
    );
  }
}

/// Airtel & Jio cards with real logos
class _ChannelButtons extends StatelessWidget {
  const _ChannelButtons();

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'failed';
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final red = Brand.red;

    Widget card(String asset, String title, String subtitle, String url) {
      return Expanded(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(asset, height: 30, fit: BoxFit.contain),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _open(url, context),
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card('assets/brands/jiotv.png', 'JioTV',
            'Open on JioTV',
            'https://l.tv.jio/48f87208'),
        card('assets/brands/airtel_xstream.png', 'Airtel Xstream', 'Open on Airtel Xstream',
            'https://open.airtelxstream.in/o8OEPcoYxXb'),
      ],
    );
  }
}

class _SocialMediaLinks extends StatelessWidget {
  const _SocialMediaLinks();

  Future<void> _launch(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link')));
    }
  }

  Widget _iconBtn(IconData icon, Color color, String url, BuildContext context) {
    return IconButton(
      icon: FaIcon(icon, color: color, size: 28),
      onPressed: () => _launch(url, context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconBtn(FontAwesomeIcons.instagram, Colors.pink,
              'https://www.instagram.com/danewsplus_news?igsh=YmR6dXB3NnhsZ3Jp', context),
          _iconBtn(FontAwesomeIcons.youtube, Colors.red,
              'https://youtube.com/@danewsplusmpcg?si=HyTaQxXY5qn2BBo7', context),
          _iconBtn(FontAwesomeIcons.facebook, Colors.blue,
              'https://www.facebook.com/share/1CwYoLxpgd/', context),
          _iconBtn(FontAwesomeIcons.squareXTwitter, isDark ? Colors.white : Colors.black,
              'https://x.com/press98783?t=9vzKk-UgThVxu_1E4Jg-Aw&s=08', context),
        ],
      ),
    );
  }
}

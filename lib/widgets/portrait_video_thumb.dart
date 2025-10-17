import 'package:flutter/material.dart';

class PortraitVideoThumb extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback onTap;

  static const int _maxLen = 26; // increased from 20

  const PortraitVideoThumb({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.onTap,
  });

  String _cap(String t) => t.length <= _maxLen ? t : '${t.substring(0, _maxLen - 3)}...';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 9 / 16, // portrait
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(.55), Colors.transparent],
                  ),
                ),
                child: Text(
                  _cap(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

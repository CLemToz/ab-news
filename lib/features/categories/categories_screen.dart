import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../category_news/category_news_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Category'), pinned: true),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                final c = categories[i];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryNewsScreen(category: c.name),
                  )),
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(c.imageUrl, fit: BoxFit.cover),
                      Container(color: Colors.black26),
                      Center(
                        child: Text(c.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
                      ),
                    ]),
                  ),
                );
              },
              childCount: categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1,
            ),
          ),
        ),
      ],
    );
  }
}

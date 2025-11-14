import '../models/news_article.dart';
import '../models/category_item.dart';
import '../models/reel_item.dart';

const tickerText =
    'Best News App of Chhattisgarh • Breaking News, Local Stories, Live Alerts • News You Can Trust छत्तीसगढ़ का सबसे भरोसेमंद न्यूज़ ऐप • ब्रेकिंग न्यूज़, लोकल कहानियाँ • एक ही जगह, पूरी ख़बर';

const _img = 'https://picsum.photos/seed/';

const lorem =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent vel dui ac neque facilisis volutpat. "
    "Sed dictum, tortor ut commodo rhoncus, lorem risus posuere leo, non efficitur enim nisl sit amet elit. "
    "Curabitur egestas, augue id hendrerit pretium, augue justo faucibus erat, sed mattis enim justo sit amet odio. "
    "Suspendisse potenti. Integer at sapien vitae mi pulvinar pharetra.";


final siteCategories = <CategoryItem>[
  // English + Hindi (order can be changed any time)
  CategoryItem('Breaking News',        '${_img}breaking-cat/400/300'),
  CategoryItem('More',                 '${_img}more/400/300'),
  CategoryItem('अध्यात्म',             '${_img}adhyatm/400/300'),
  CategoryItem('ज्योतिष',              '${_img}jyotish/400/300'),
  CategoryItem('इंटरनेशनल',            '${_img}international/400/300'),
  CategoryItem('एक्सप्लेनर',            '${_img}explainer/400/300'),
  CategoryItem('एजुकेशन',              '${_img}education/400/300'),
  CategoryItem('ऑटो',                  '${_img}auto/400/300'),
  CategoryItem('क्रिकेट',               '${_img}cricket/400/300'),
  CategoryItem('नेशनल',                '${_img}national/400/300'),
  CategoryItem('नौकरी कॅरियर',         '${_img}career/400/300'),
  CategoryItem('न्यूज एंड पॉलिटिक्स',  '${_img}politics/400/300'),
  CategoryItem('बिजनेस',               '${_img}business/400/300'),
  CategoryItem('बॉलीवुड',               '${_img}bollywood/400/300'),
  CategoryItem('ज्ञान',                 '${_img}gyaan/400/300'),
  CategoryItem('मौसम',                 '${_img}weather1/400/300'),
  CategoryItem('मौसम-मौसम',            '${_img}weather2/400/300'),
  CategoryItem('राज्य खबर',             '${_img}state/400/300'),
  CategoryItem('क्राइम न्यूज',          '${_img}crime/400/300'),
  CategoryItem('लाइफस्टाइल',           '${_img}lifestyle/400/300'),
  CategoryItem('वायरल',                 '${_img}viral/400/300'),
  CategoryItem('स्पेशल',                '${_img}special/400/300'),
  CategoryItem('स्पोर्ट',               '${_img}sports2/400/300'),
];

// ----- NEW: a few highlighted ones to show on Home (edit freely) -----
final highlightedCategories = <CategoryItem>[
  CategoryItem('राज्य खबर',            '${_img}state-hi/400/300'),   // e.g., Chhattisgarh hub lives here
  CategoryItem('क्रिकेट',               '${_img}cricket-hi/400/300'),
  CategoryItem('बिजनेस',               '${_img}biz-hi/400/300'),
  CategoryItem('इंटरनेशनल',            '${_img}intl-hi/400/300'),
  CategoryItem('लाइफस्टाइल',           '${_img}life-hi/400/300'),
  CategoryItem('क्राइम न्यूज',          '${_img}crime-hi/400/300'),
];

// keep your existing `categories`, `articles`, `reels`, etc.



final categories = <CategoryItem>[
  const CategoryItem('World', '${_img}world/400/300'),
  const CategoryItem('India', '${_img}india/400/300'),
  const CategoryItem('Business', '${_img}biz/400/300'),
  const CategoryItem('Sports', '${_img}sports/400/300'),
  const CategoryItem('Tech', '${_img}tech/400/300'),
  const CategoryItem('Entertainment', '${_img}ent/400/300'),
  const CategoryItem('Health', '${_img}health/400/300'),
  const CategoryItem('Science', '${_img}science/400/300'),
];

final articles = <NewsArticle>[
  NewsArticle(
    id: '1',
    title: 'FBI opens investigation into China every 10 hrs, says director',
    subtitle: "Wray's comments came during a US Senate hearing.",
    body: lorem,
    imageUrl: '${_img}breaking/900/600',
    category: 'World',
    author: 'David',
    timeAgo: '1h ago',
    readTime: '3 min read',
  ),
  NewsArticle(
    id: '2',
    title: "’B’day and Xmas came together’: Experts hail RCB spinner’s 3-wkt spell",
    subtitle: 'IPL analysis and reactions across the board.',
    body: lorem,
    imageUrl: '${_img}ipl/900/600',
    category: 'Sports',
    author: 'Anita',
    timeAgo: '18 hours ago',
    readTime: '2 min read',
  ),
  NewsArticle(
    id: '3',
    title: 'Excited to be part of KKR journey, says Harbhajan Singh',
    subtitle: 'Veteran speaks about the new season.',
    body: lorem,
    imageUrl: '${_img}kkr/900/600',
    category: 'Sports',
    author: 'Ravi',
    timeAgo: '18 hours ago',
    readTime: '1 min read',
  ),
  NewsArticle(
    id: '4',
    title: 'Monsoon likely to arrive early; IMD issues advisory for 6 states',
    subtitle: 'Weather department’s latest bulletin.',
    body: lorem,
    imageUrl: '${_img}weather/900/600',
    category: 'India',
    author: 'Priya',
    timeAgo: '20 hours ago',
    readTime: '4 min read',
  ),
  NewsArticle(
    id: '5',
    title: 'OnePlus Watch may get Always-On Display via OTA update soon',
    subtitle: 'New firmware spotted in testing.',
    body: lorem,
    imageUrl: '${_img}watch/900/600',
    category: 'Tech',
    author: 'Karan',
    timeAgo: '5 days ago',
    readTime: '2 min read',
  ),
  NewsArticle(
    id: '6',
    title: 'Redmi 20X could launch as a rebranded Note 10 5G',
    subtitle: 'Price and specs tipped ahead of debut.',
    body: lorem,
    imageUrl: '${_img}redmi/900/600',
    category: 'Tech',
    author: 'Meera',
    timeAgo: '5 days ago',
    readTime: '2 min read',
  ),
  NewsArticle(
    id: '7',
    title: 'Healthy habits that actually work, according to new study',
    subtitle: 'Simple routines linked to better outcomes.',
    body: lorem,
    imageUrl: '${_img}health/900/600',
    category: 'Health',
    author: 'Dr. Neel',
    timeAgo: '4 days ago',
    readTime: '3 min read',
  ),
];

final reels = <ReelItem>[
  const ReelItem(
    id: 'r1',
    title: 'Morning briefing: Top 5 stories',
    subtitle: 'Get updated in under a minute.',
    category: 'General',
    videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    coverImage: 'https://picsum.photos/seed/reel1/1080/1920',
  ),
  const ReelItem(
    id: 'r2',
    title: 'Markets open higher on tech rally',
    subtitle: 'Nifty & Sensex in green.',
    category: 'Business',
    videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    coverImage: 'https://picsum.photos/seed/reel2/1080/1920',
  ),
  const ReelItem(
    id: 'r3',
    title: 'Kolkata seals playoff berth',
    subtitle: 'Post-match reactions.',
    category: 'Sports',
    videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    coverImage: 'https://picsum.photos/seed/reel3/1080/1920',
  ),
];

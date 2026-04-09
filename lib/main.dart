import 'dart:convert'; // For turning web data into JSON
import 'package:flutter/material.dart'; // The core UI kit
import 'package:http/http.dart' as http; // For web requests
import 'package:google_fonts/google_fonts.dart'; // Typography
import 'package:url_launcher/url_launcher.dart'; // Browser links
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Icons
import 'package:intl/intl.dart'; // Date formatting
import 'package:shared_preferences/shared_preferences.dart'; // Browser memory

/// ===========================================================================
/// 1. CENTRALIZED COLOR PALETTE (MODULAR)
/// ===========================================================================
class AppColors {
  static const Color appBackground = Color(0xFF0e0e0e); 
  static const Color appSurface = Color(0xFF131313); 
  static const Color tileBackground = Color(0xFF151515); // NEW: Tile color for articles
  static const Color borderSubtle = Colors.white10; 
  static const Color glassOverlay = Color(0xCC0E0E0E); 
  static const Color highlightOverlay = Color(0x0DFFFFFF); 

  static const Color textMain = Colors.white; 
  static const Color textMuted = Colors.white54; 
  static const Color textSubtle = Colors.white38; 

  static const Color themeAmber = Color(0xFFf59e0b);
  static const Color themeRose = Color(0xFFf43f5e);
  static const Color themeViolet = Color(0xFF8b5cf6);
  static const Color themeIndigo = Color(0xFF6366f1);
  static const Color themeBlue = Color(0xFF3b82f6);
  static const Color themeEmerald = Color(0xFF10b981);

  static const List<Color> allThemes = [
    themeAmber, themeRose, themeViolet, themeIndigo, themeBlue, themeEmerald
  ];
}

void main() {
  runApp(const TheRadicalApp());
}

/// ===========================================================================
/// 2. THE ROOT WIDGET
/// ===========================================================================
class TheRadicalApp extends StatefulWidget {
  const TheRadicalApp({super.key});

  @override
  State<TheRadicalApp> createState() => _TheRadicalAppState();
}

class _TheRadicalAppState extends State<TheRadicalApp> {
  Color primaryColor = AppColors.themeAmber; 

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) {
        setState(() => primaryColor = Color(colorValue));
      }
    } catch (e) {
      debugPrint("Memory load error: $e");
    }
  }

  void updateTheme(Color newColor) async {
    setState(() => primaryColor = newColor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', newColor.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Radical | News Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.appBackground,
        primaryColor: primaryColor,
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      ),
      home: NewsDashboard(
        primaryColor: primaryColor,
        onThemeChanged: updateTheme,
      ),
    );
  }
}

/// ===========================================================================
/// 3. ARTICLE DATA BLUEPRINT
/// ===========================================================================
class Article {
  final String title;
  final String link;
  final String pubDate;
  final String description; 
  final String source;
  final String thumbnail;
  final List<String> topics;

  Article({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    required this.source,
    required this.thumbnail,
    required this.topics,
  });

  factory Article.fromJson(Map<String, dynamic> json, String sourceName, List<String> detectedTopics) {
    return Article(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      pubDate: json['pubDate'] ?? '',
      description: (json['description'] as String).replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      source: sourceName,
      thumbnail: json['thumbnail'] ?? '',
      topics: detectedTopics,
    );
  }
}

/// ===========================================================================
/// 4. SOURCE CONFIGURATIONS
/// ===========================================================================
const Map<String, String> coreSources = {
  "https://ancomfed.org/picket-line/feed": "PICKET LINE",
  "https://www.greenleft.org.au/rss.xml": "GREEN LEFT",
  "https://redflag.org.au/rss/": "RED FLAG",
  "https://red-spark.org/tag/australia/feed": "RED SPARK",
  "https://socialismtoday.au/feed": "SOCIALISM TODAY",
  "https://solidarity.net.au/feed": "SOLIDARITY",
  "https://labortribune.net.au/feed": "LABOR TRIBUNE",
  "https://www.wsws.org/en/topics/country/australia/rss.xml": "WORLD SOCIALIST WEB SITE",
  "https://melbacg.au/category/anvil/rss": "THE ANVIL",
  "https://vanguard-cpaml.blogspot.com/rss.xml": "VANGUARD",
  "https://partisanmagazine.org/feed/": "PARTISAN!",
  "https://redantcollective.org/feed": "RED ANT",
  "https://www.theguardian.com/australia-news/australian-trade-unions/rss": "THE GUARDIAN",
  "https://temokalati.wordpress.com/feed": "TEMOKALATI",
  "https://www.thenews.coop/country/oceania/feed": "CO-OP NEWS",
  "https://seqldiww.org/category/australia/feed": "IWW (SOUTH EAST QUEENSLAND)"
};

const Map<String, String> globalSources = {
  "https://jacobin.com/feed": "JACOBIN",
};

const Map<String, String> extendedSources = {
  "https://michaelwest.com.au/category/latest-posts/feed/": "MICHAEL WEST",
  "http://feeds.feedburner.com/IndependentAustralia": "INDEPENDENT AUSTRALIA"
};

const List<String> australianKeywords = [
  "australia", "australian", "sydney", "melbourne", "brisbane", "perth", 
  "adelaide", "canberra", "hobart", "darwin", "victoria", "queensland", 
  "tasmania", "albanese", "dutton", "nsw", "vic", "qld", "western australia"
];

const Map<String, List<String>> topicConfig = {
  "Labour": ["strike", "union", "worker", "picket", "wage", "industrial", "cfmeu", "workplace", "unemployment", "labour", "fair work"],
  "Middle East": ["gaza", "palestine", "israel", "occupation", "zionism", "rafah", "genocide", "iran", "tehran", "lebanon", "beirut", "yemen", "houthi"],
  "Climate": ["climate", "environment", "warming", "coal", "gas", "emission", "green", "renewables"],
  "International": ["imperialism", "china", "usa", "nato", "ukraine", "russia", "global", "war", "united states", "biden", "trump", "europe"],
  "Anti-Fascism": ["fascism", "far-right", "nazi", "racism", "protest", "police", "surveillance"]
};

/// ===========================================================================
/// 5. MAIN DASHBOARD LOGIC
/// ===========================================================================
class NewsDashboard extends StatefulWidget {
  final Color primaryColor;
  final Function(Color) onThemeChanged;

  const NewsDashboard({super.key, required this.primaryColor, required this.onThemeChanged});

  @override
  State<NewsDashboard> createState() => _NewsDashboardState();
}

class _NewsDashboardState extends State<NewsDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Article> masterArticles = []; 
  List<Article> filteredArticles = []; 
  bool isLoading = true; 
  bool isExtendedCoverageEnabled = false; 
  String currentFilter = "ALL"; 
  final TextEditingController _searchController = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  void _startApp() async {
    loadNews();
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isExtendedCoverageEnabled = prefs.getBool('extended_coverage') ?? false;
      });
    } catch (e) {
      debugPrint("Toggle load error: $e");
    }
  }

  Future<void> _toggleExtendedCoverage(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('extended_coverage', val);
    setState(() {
      isExtendedCoverageEnabled = val;
      isLoading = true;
    });
    loadNews();
  }

  Future<void> loadNews() async {
    List<Article> allFetched = [];
    Map<String, String> activeSources = Map.from(coreSources);
    activeSources.addAll(globalSources); 
    
    if (isExtendedCoverageEnabled) {
      activeSources.addAll(extendedSources);
    }

    for (var entry in activeSources.entries) {
      try {
        final response = await http.get(Uri.parse(
            'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(entry.key)}'
        ));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'ok') {
            for (var item in data['items']) {
              String contentToSearch = ((item['title'] ?? "") + " " + (item['description'] ?? "")).toLowerCase();
              
              bool isGlobal = globalSources.containsValue(entry.value);
              if (isGlobal) {
                bool containsAuKeywords = australianKeywords.any((keyword) => contentToSearch.contains(keyword));
                if (!containsAuKeywords) continue; 
              }

              List<String> topics = [];
              topicConfig.forEach((key, keywords) {
                if (keywords.any((kw) => contentToSearch.contains(kw))) topics.add(key);
              });
              
              allFetched.add(Article.fromJson(item, entry.value, topics));
            }
          }
        }
      } catch (e) {
        debugPrint("Skipping ${entry.value}: $e");
      }
    }

    allFetched.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    if (mounted) {
      setState(() {
        masterArticles = allFetched;
        filteredArticles = allFetched;
        isLoading = false; 
        applyFilter(currentFilter);
      });
    }
  }

  String getFormattedArticleDate(String dateStr) {
    try {
      DateTime postDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      Duration diff = now.difference(postDate);
      String dateOnly = DateFormat('dd/MM/yyyy').format(postDate);

      if (diff.inDays <= 3) {
        String relative;
        if (diff.inMinutes < 60) relative = "${diff.inMinutes}m ago";
        else if (diff.inHours < 24) relative = "${diff.inHours}h ago";
        else relative = "${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago";
        return "$relative ($dateOnly)";
      }
      return dateOnly;
    } catch (e) { return "Recent"; }
  }

  void applyFilter(String topic) {
    setState(() {
      currentFilter = topic;
      if (topic == "ALL") {
        filteredArticles = masterArticles;
      } else {
        filteredArticles = masterArticles.where((a) => a.topics.contains(topic)).toList();
      }
    });
  }

  void handleSearch(String query) {
    setState(() {
      filteredArticles = masterArticles.where((a) {
        final q = query.toLowerCase();
        return a.title.toLowerCase().contains(q) || a.source.toLowerCase().contains(q);
      }).toList();
    });
  }

  /// ===========================================================================
  /// 6. USER INTERFACE (BUILD)
  /// ===========================================================================
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

    return Scaffold(
      key: _scaffoldKey, 
      endDrawer: _buildSidebar(), 
      // STICKY HEADER IMPLEMENTATION:
      // We separate the 'Fixed' elements from the 'Scrollable' elements.
      body: Column(
        children: [
          // FIXED AREA (Does not scroll)
          _buildBetaBanner(), 
          _buildHeaderWrapper(screenWidth), 
          
          // SCROLLABLE AREA
          Expanded(
            child: ListView(
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1800),
                    child: isLoading 
                      ? SizedBox(height: 500, child: _buildLoader())
                      : (masterArticles.isEmpty ? _buildEmptyState() : _buildContent(screenWidth, crossAxisCount)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetaBanner() {
    return Container(
      width: double.infinity,
      color: widget.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        "THIS WEBSITE IS STILL IN BETA — DEVELOPMENT IN PROGRESS",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.appBackground, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }

  Widget _buildHeaderWrapper(double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.appBackground, // Solid background so news doesn't show through
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1800),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => applyFilter("ALL"),
                child: Text(
                  screenWidth > 500 ? "THE RADICAL" : "TR",
                  style: GoogleFonts.spaceGrotesk(color: widget.primaryColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextField(
                    controller: _searchController,
                    onChanged: handleSearch,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: "Search articles...",
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.highlightOverlay,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.highlightOverlay,
                  foregroundColor: AppColors.textMain,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth > 700 ? 20 : 12, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (screenWidth > 700) ...[
                      const Text("SETTINGS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(width: 10),
                    ],
                    Icon(FontAwesomeIcons.sliders, size: 12, color: widget.primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: widget.primaryColor),
          const SizedBox(height: 16),
          Text("FETCHING ARTICLES...", style: TextStyle(color: widget.primaryColor, letterSpacing: 4, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 100),
          const Icon(FontAwesomeIcons.circleExclamation, size: 40, color: AppColors.textSubtle),
          const SizedBox(height: 20),
          const Text("NO ARTICLES FOUND", style: TextStyle(letterSpacing: 2, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          TextButton(onPressed: loadNews, child: Text("RETRY", style: TextStyle(color: widget.primaryColor)))
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth, int crossAxisCount) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  "RECENT NEWS",
                  style: GoogleFonts.spaceGrotesk(fontSize: screenWidth > 600 ? 60 : 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, letterSpacing: -2, color: AppColors.textMain),
                ),
              ),
              if (screenWidth > 600)
                Text("REFRESHED: ${DateFormat('HH:mm').format(DateTime.now())}", style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
            ],
          ),
        ),
        if (filteredArticles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildHero(filteredArticles[0]),
          ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: GridView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 30, // Space between tiles
              mainAxisSpacing: 30,  // Space between rows
              childAspectRatio: 0.85, 
            ),
            itemCount: filteredArticles.length > 1 ? filteredArticles.length - 1 : 0,
            itemBuilder: (context, index) => _buildArticleCard(filteredArticles[index + 1]),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(Article art) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(art.link)),
      child: Container(
        height: 450,
        decoration: BoxDecoration(color: AppColors.tileBackground, border: Border.all(color: AppColors.borderSubtle)),
        child: Stack(
          children: [
            art.thumbnail.isNotEmpty
                ? Positioned.fill(child: Image.network(art.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: AppColors.appBackground)))
                : Container(color: AppColors.textSubtle),
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.appBackground])))),
            Positioned(
              top: 20, left: 20,
              child: Wrap(
                spacing: 8,
                children: [
                  _badge("LATEST NEWS", widget.primaryColor, AppColors.appBackground),
                  ...art.topics.map((t) => _badge(t, AppColors.textMain, AppColors.appBackground)),
                ],
              ),
            ),
            Positioned(bottom: 40, left: 40, right: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Text(art.source.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  const Icon(FontAwesomeIcons.solidCalendarDays, size: 8, color: AppColors.textSubtle),
                  const SizedBox(width: 6),
                  Text(getFormattedArticleDate(art.pubDate).toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(art.title, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, fontStyle: FontStyle.italic, color: AppColors.textMain)),
            ])),
          ],
        ),
      ),
    );
  }

  /// UI: REGULAR ARTICLE TILE
  Widget _buildArticleCard(Article art) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(art.link)),
      child: Container(
        // NEW: Tile styling
        decoration: BoxDecoration(
          color: AppColors.tileBackground, // The #333333 color
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black26,
                child: art.thumbnail.isNotEmpty 
                  ? Image.network(art.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(FontAwesomeIcons.satelliteDish, color: AppColors.textSubtle))
                  : const Center(child: Icon(FontAwesomeIcons.satelliteDish, color: AppColors.textSubtle)),
              ),
            ),
            // Internal Padding for the text inside the tile
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.calendarDay, size: 9, color: widget.primaryColor.withAlpha(150)),
                      const SizedBox(width: 8),
                      Text(
                        getFormattedArticleDate(art.pubDate).toUpperCase(),
                        style: const TextStyle(fontSize: 9, color: AppColors.textSubtle, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(art.source, style: TextStyle(color: widget.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: Text(art.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3, color: AppColors.textMain)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40, 
                    child: Text(
                      art.description.isEmpty ? "No summary available." : art.description, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg),
      child: Text(text.toUpperCase(), style: TextStyle(color: textCol, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: AppColors.appSurface,
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(children: [Icon(FontAwesomeIcons.gear, size: 14, color: widget.primaryColor), const SizedBox(width: 12), Text("CONTROL PANEL", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textMain))]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildExtendedToggle(),
                const SizedBox(height: 40),
                _sidebarSectionTitle(FontAwesomeIcons.palette, "THEME PALETTE"),
                const SizedBox(height: 16),
                _buildThemePicker(),
                const SizedBox(height: 40),
                _sidebarSectionTitle(FontAwesomeIcons.layerGroup, "FILTERS"),
                const SizedBox(height: 16),
                _buildTopicFilters(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.borderSubtle), color: AppColors.highlightOverlay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EXTENDED COVERAGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textMain)),
              Switch(
                value: isExtendedCoverageEnabled,
                activeThumbColor: widget.primaryColor,
                onChanged: (val) => _toggleExtendedCoverage(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Broaden the signal to include independent investigative reporting and broad-perspective analysis.", style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _sidebarSectionTitle(IconData icon, String title) {
    return Row(children: [Icon(icon, size: 10, color: AppColors.textSubtle), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSubtle))]);
  }

  Widget _buildThemePicker() {
    return Wrap(
      spacing: 10, runSpacing: 10, 
      children: AppColors.allThemes.map((color) => GestureDetector(
        onTap: () => widget.onThemeChanged(color), 
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, border: Border.all(color: widget.primaryColor == color ? AppColors.textMain : Colors.transparent, width: 2)))
      )).toList()
    );
  }

  Widget _buildTopicFilters() {
    List<String> topics = ["ALL", ...topicConfig.keys];
    return Column(children: topics.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: SizedBox(width: double.infinity, child: TextButton(onPressed: () => applyFilter(t), style: TextButton.styleFrom(alignment: Alignment.centerLeft, backgroundColor: currentFilter == t ? widget.primaryColor : Colors.transparent, shape: const RoundedRectangleBorder(), side: BorderSide(color: currentFilter == t ? widget.primaryColor : AppColors.borderSubtle), padding: const EdgeInsets.all(16)), child: Text(t.toUpperCase(), style: TextStyle(color: currentFilter == t ? AppColors.appBackground : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)))))).toList());
  }
}
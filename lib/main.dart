import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1. ENTRY POINT
void main() {
  runApp(const TheRadicalApp());
}

/// 2. THE ROOT WIDGET
class TheRadicalApp extends StatefulWidget {
  const TheRadicalApp({super.key});

  @override
  State<TheRadicalApp> createState() => _TheRadicalAppState();
}

class _TheRadicalAppState extends State<TheRadicalApp> {
  // We keep the theme color here at the top level
  Color primaryColor = const Color(0xFFf59e0b);

  @override
  void initState() {
    super.initState();
    _loadSavedTheme(); // Load saved color from browser memory
  }

  /// MEMORY: Check browser for saved color
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) {
        setState(() {
          primaryColor = Color(colorValue);
        });
      }
    } catch (e) {
      debugPrint("Memory error: $e"); // If browser blocks memory, app still runs
    }
  }

  /// MEMORY: Save color when changed
  void updateTheme(Color newColor) async {
    setState(() {
      primaryColor = newColor;
    });
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
        scaffoldBackgroundColor: const Color(0xFF0e0e0e),
        primaryColor: primaryColor,
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      ),
      // Here we implement the Max-Width and Centering
      home: Scaffold(
        backgroundColor: const Color(0xFF000000), // Background for wide screens
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1800), // Max Width Limit
            decoration: const BoxDecoration(color: Color(0xFF0e0e0e)),
            child: NewsDashboard(
              primaryColor: primaryColor,
              onThemeChanged: updateTheme,
            ),
          ),
        ),
      ),
    );
  }
}

/// 3. ARTICLE DATA MODEL
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
      description: (json['description'] as String).replaceAll(RegExp(r'<[^>]*>'), ''),
      source: sourceName,
      thumbnail: json['thumbnail'] ?? '',
      topics: detectedTopics,
    );
  }
}

/// 4. SOURCE CONFIGURATIONS
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
  "https://www.theguardian.com/australia-news/australian-trade-unions/rss": "THE GUARDIAN"
};

const Map<String, String> extendedSources = {
  "https://www.michaelwest.com.au/feed/": "MICHAEL WEST",
  "https://independentaustralia.net/rss.xml": "INDEPENDENT AUSTRALIA",
};

const Map<String, List<String>> topicConfig = {
  "Labour": ["strike", "union", "worker", "picket", "wage", "industrial", "cfmeu", "workplace", "unemployment", "labour", "fair work"],
  "Middle East": ["gaza", "palestine", "israel", "occupation", "zionism", "rafah", "genocide", "iran", "tehran", "lebanon", "beirut", "yemen", "houthi"],
  "Climate": ["climate", "environment", "warming", "coal", "gas", "emission", "green", "renewables"],
  "International": ["imperialism", "china", "usa", "nato", "ukraine", "russia", "global", "war", "united states", "biden", "trump", "europe"],
  "Anti-Fascism": ["fascism", "far-right", "nazi", "racism", "protest", "police", "surveillance"]
};

/// 5. MAIN DASHBOARD LOGIC
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

  /// STARTUP SEQUENCE: Fetch news immediately, load memory settings in background
  void _startApp() async {
    // 1. Fetch news immediately (Standard working logic)
    loadNews();
    
    // 2. Load IA/Michael West toggle setting from memory afterward
    try {
      final prefs = await SharedPreferences.getInstance();
      bool savedToggle = prefs.getBool('extended_coverage') ?? false;
      if (savedToggle != isExtendedCoverageEnabled) {
        setState(() {
          isExtendedCoverageEnabled = savedToggle;
          isLoading = true;
        });
        loadNews(); // Refresh news if toggle was meant to be ON
      }
    } catch (e) {
      debugPrint("Memory toggle error: $e");
    }
  }

  /// MEMORY: Save the Extended News toggle
  Future<void> _toggleExtendedCoverage(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('extended_coverage', val);
    setState(() {
      isExtendedCoverageEnabled = val;
      isLoading = true;
    });
    loadNews();
  }

  /// STABLE NEWS LOADER (Matches the logic that worked in your original code)
  Future<void> loadNews() async {
    List<Article> allFetched = [];
    
    // Determine which sources to loop through
    Map<String, String> activeSources = Map.from(coreSources);
    if (isExtendedCoverageEnabled) {
      activeSources.addAll(extendedSources);
    }

    // THE LOOP: Fetches one by one (The most stable way to avoid browser blocking)
    for (var entry in activeSources.entries) {
      try {
        final response = await http.get(Uri.parse(
            'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(entry.key)}'
        ));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'ok') {
            for (var item in data['items']) {
              // Tag topics based on words found in title/summary
              String content = (item['title'] + (item['description'] ?? "")).toLowerCase();
              List<String> topics = [];
              topicConfig.forEach((key, keywords) {
                if (keywords.any((kw) => content.contains(kw))) topics.add(key);
              });
              
              allFetched.add(Article.fromJson(item, entry.value, topics));
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching ${entry.value}: $e");
      }
    }

    // Sort by newest date
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

  /// SEARCH & FILTER
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

  String timeAgo(String dateStr) {
    try {
      DateTime d = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (e) { return "Recent"; }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildSidebar(),
      body: Column(
        children: [
          _buildBetaBanner(),
          _buildHeader(screenWidth),
          Expanded(
            child: isLoading 
              ? _buildLoader() 
              : (masterArticles.isEmpty ? _buildEmptyState() : _buildContent(screenWidth, crossAxisCount)),
          ),
        ],
      ),
    );
  }

  /// UI: Gold Top Banner
  Widget _buildBetaBanner() {
    return Container(
      width: double.infinity,
      color: widget.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        "THIS WEBSITE IS STILL IN BETA — DEVELOPMENT IN PROGRESS",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }

  /// UI: Navigation Header
  Widget _buildHeader(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0e0e0e).withAlpha(204),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
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
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search articles...",
                  prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 12),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
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
              backgroundColor: Colors.white.withAlpha(13),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 700 ? 20 : 12, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              side: const BorderSide(color: Colors.white10),
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
    );
  }

  /// UI: Loading Screen
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

  /// UI: Nothing found screen
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FontAwesomeIcons.circleExclamation, size: 40, color: Colors.white24),
          const SizedBox(height: 20),
          const Text("NO ARTICLES FOUND", style: TextStyle(letterSpacing: 2, color: Colors.white54)),
          const SizedBox(height: 10),
          TextButton(onPressed: loadNews, child: Text("RETRY", style: TextStyle(color: widget.primaryColor)))
        ],
      ),
    );
  }

  /// UI: The actual news layout
  Widget _buildContent(double screenWidth, int crossAxisCount) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    "RECENT NEWS",
                    style: GoogleFonts.spaceGrotesk(fontSize: screenWidth > 600 ? 60 : 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, letterSpacing: -2),
                  ),
                ),
                if (screenWidth > 600)
                  Text("REFRESHED: ${DateFormat('HH:mm').format(DateTime.now())}", style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2)),
              ],
            ),
          ),
        ),
        if (filteredArticles.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverToBoxAdapter(child: _buildHero(filteredArticles[0])),
          ),
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 40,
              mainAxisSpacing: 60,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index + 1 >= filteredArticles.length) return null;
                return _buildArticleCard(filteredArticles[index + 1]);
              },
              childCount: filteredArticles.length > 1 ? filteredArticles.length - 1 : 0,
            ),
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
        decoration: BoxDecoration(color: const Color(0xFF131313), border: Border.all(color: Colors.white10)),
        child: Stack(
          children: [
            art.thumbnail.isNotEmpty
                ? Positioned.fill(child: Image.network(art.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black)))
                : Container(color: Colors.black26),
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF0e0e0e)])))),
            Positioned(
              top: 20,
              left: 20,
              child: Wrap(
                spacing: 8,
                children: [
                  _badge("LATEST NEWS", widget.primaryColor, Colors.black),
                  ...art.topics.map((t) => _badge(t, Colors.white, Colors.black)),
                ],
              ),
            ),
            Positioned(bottom: 40, left: 40, right: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${art.source}  •  ${timeAgo(art.pubDate).toUpperCase()}", style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(art.title, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, fontStyle: FontStyle.italic)),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Article art) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(art.link)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF131313), border: Border.all(color: Colors.white10)),
            child: art.thumbnail.isNotEmpty 
              ? Image.network(art.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(FontAwesomeIcons.satelliteDish))
              : const Center(child: Icon(FontAwesomeIcons.satelliteDish)),
          ),
        ),
        const SizedBox(height: 16),
        Text(art.source, style: TextStyle(color: widget.primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(art.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg),
      child: Text(text.toUpperCase(), style: TextStyle(color: textCol, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  /// UI: Sidebar Settings Drawer
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF131313),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(children: [Icon(FontAwesomeIcons.gear, size: 14, color: widget.primaryColor), const SizedBox(width: 12), Text("CONTROL PANEL", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 2))]),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.white10), color: Colors.white.withAlpha(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EXTENDED COVERAGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Switch(
                value: isExtendedCoverageEnabled,
                activeThumbColor: widget.primaryColor,
                onChanged: (val) => _toggleExtendedCoverage(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Broaden the signal to include independent investigative reporting and broad-perspective analysis.",
            style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sidebarSectionTitle(IconData icon, String title) {
    return Row(children: [Icon(icon, size: 10, color: Colors.white38), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white38))]);
  }

  Widget _buildThemePicker() {
    List<Color> themes = [const Color(0xFFf59e0b), const Color(0xFFf43f5e), const Color(0xFF8b5cf6), const Color(0xFF6366f1), const Color(0xFF3b82f6), const Color(0xFF10b981)];
    return Wrap(
      spacing: 10, runSpacing: 10, 
      children: themes.map((color) => GestureDetector(
        onTap: () => widget.onThemeChanged(color), 
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, border: Border.all(color: widget.primaryColor == color ? Colors.white : Colors.transparent, width: 2)))
      )).toList()
    );
  }

  Widget _buildTopicFilters() {
    List<String> topics = ["ALL", ...topicConfig.keys];
    return Column(children: topics.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: SizedBox(width: double.infinity, child: TextButton(onPressed: () => applyFilter(t), style: TextButton.styleFrom(alignment: Alignment.centerLeft, backgroundColor: currentFilter == t ? widget.primaryColor : Colors.transparent, shape: const RoundedRectangleBorder(), side: BorderSide(color: currentFilter == t ? widget.primaryColor : Colors.white10), padding: const EdgeInsets.all(16)), child: Text(t.toUpperCase(), style: TextStyle(color: currentFilter == t ? Colors.black : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)))))).toList());
  }
}
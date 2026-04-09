import 'dart:convert'; // Required for translating raw web data into JSON format
import 'package:flutter/material.dart'; // The core UI toolkit for Flutter
import 'package:http/http.dart' as http; // For making web requests to news feeds
import 'package:google_fonts/google_fonts.dart'; // For Space Grotesk and Manrope fonts
import 'package:url_launcher/url_launcher.dart'; // To open news links in a browser
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For the sliders icon
import 'package:intl/intl.dart'; // For formatting dates
import 'package:shared_preferences/shared_preferences.dart'; // To remember settings in the browser

/// ===========================================================================
/// 1. CENTRALIZED COLOR PALETTE
/// ===========================================================================
/// By keeping all our colors here, we can change the design of the entire 
/// website by just changing a hex code in one place.
class AppColors {
  // Backgrounds
  static const Color appBackground = Color(0xFF0e0e0e); // The main dark background
  static const Color appSurface = Color(0xFF131313); // Slightly lighter background for cards/menus
  static const Color pureBlack = Color(0xFF000000); // Used for the "void" outside the 1800px max-width
  
  // Borders & Overlays
  static const Color borderSubtle = Colors.white10; // Very faint white line for borders
  static const Color glassOverlay = Color(0xCC0E0E0E); // Semi-transparent background for the sticky header
  static const Color highlightOverlay = Color(0x0DFFFFFF); // Faint white highlight for text boxes/buttons

  // Text Colors
  static const Color textMain = Colors.white; // Pure white for titles
  static const Color textMuted = Colors.white54; // Dimmed white for paragraph text/descriptions
  static const Color textSubtle = Colors.white38; // Very dimmed white for dates and small icons

  // The 6 Theme Choices for the Control Panel
  static const Color themeAmber = Color(0xFFf59e0b);
  static const Color themeRose = Color(0xFFf43f5e);
  static const Color themeViolet = Color(0xFF8b5cf6);
  static const Color themeIndigo = Color(0xFF6366f1);
  static const Color themeBlue = Color(0xFF3b82f6);
  static const Color themeEmerald = Color(0xFF10b981);

  // List of all themes for the Settings generator
  static const List<Color> allThemes = [
    themeAmber, themeRose, themeViolet, themeIndigo, themeBlue, themeEmerald
  ];
}

/// ===========================================================================
/// 2. ENTRY POINT
/// ===========================================================================
void main() {
  runApp(const TheRadicalApp());
}

/// ===========================================================================
/// 3. THE ROOT WIDGET
/// ===========================================================================
/// Handles the high-level setup: Theme, Memory, and the 1800px Max-Width.
class TheRadicalApp extends StatefulWidget {
  const TheRadicalApp({super.key});

  @override
  State<TheRadicalApp> createState() => _TheRadicalAppState();
}

class _TheRadicalAppState extends State<TheRadicalApp> {
  // Dynamic primary color that changes based on user preference. Defaults to Amber.
  Color primaryColor = AppColors.themeAmber; 

  @override
  void initState() {
    super.initState();
    _loadSavedSettings(); // Check browser memory as soon as the app starts.
  }

  /// MEMORY: Load the saved color from browser storage
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) {
        setState(() {
          primaryColor = Color(colorValue); // Apply saved color to the app
        });
      }
    } catch (e) {
      debugPrint("Memory load error: $e");
    }
  }

  /// MEMORY: Save the color when changed in settings
  void updateTheme(Color newColor) async {
    setState(() {
      primaryColor = newColor; // Update screen instantly
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', newColor.toARGB32()); // Save to memory
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
      home: Scaffold(
        backgroundColor: AppColors.pureBlack, // Background for ultra-wide screens
        body: Center(
          child: Container(
            // MAX WIDTH: Centered website layout maxed at 1800px wide
            constraints: const BoxConstraints(maxWidth: 1800),
            decoration: const BoxDecoration(color: AppColors.appBackground),
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

/// ===========================================================================
/// 4. ARTICLE DATA BLUEPRINT
/// ===========================================================================
class Article {
  final String title;
  final String link;
  final String pubDate;
  final String description; // The summary text
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

  // Factory converts raw web JSON into this structured class
  factory Article.fromJson(Map<String, dynamic> json, String sourceName, List<String> detectedTopics) {
    return Article(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      pubDate: json['pubDate'] ?? '',
      // .replaceAll removes HTML code (like <p> or <img>) from the article summary
      description: (json['description'] as String).replaceAll(RegExp(r'<[^>]*>'), ''),
      source: sourceName,
      thumbnail: json['thumbnail'] ?? '',
      topics: detectedTopics,
    );
  }
}

/// ===========================================================================
/// 5. SOURCE CONFIGURATIONS & GEO-FILTERING
/// ===========================================================================
/// Category A: Local sources (Always shown)
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
  "https://bccm.coop/latest-news/feed": "BCCM",
  "https://temokalati.wordpress.com/feed": "TEMOKALATI",
  "https://www.thenews.coop/country/oceania/feed": "CO-OP NEWS",
};

/// Category B: Global sources (Only shown if they contain Australian keywords)
const Map<String, String> globalSources = {
  "https://jacobin.com/feed": "JACOBIN",
};

/// Category C: Extended sources (Toggled via Settings)
const Map<String, String> extendedSources = {
  "https://michaelwest.com.au/category/latest-posts/feed/": "MICHAEL WEST",
  "http://feeds.feedburner.com/IndependentAustralia": "INDEPENDENT AUSTRALIA"
};

/// GEO-FILTERING: Words that a 'Global' article MUST have to be shown
const List<String> australianKeywords = [
  "australia", "australian", "sydney", "melbourne", "brisbane", "perth", 
  "adelaide", "canberra", "hobart", "darwin", "victoria", "queensland", 
  "tasmania", "albanese", "dutton", "nsw", "vic", "qld", "western australia"
];

/// TOPIC TAGGING: Keywords used to automatically assign topics
const Map<String, List<String>> topicConfig = {
  "Labour": ["strike", "union", "worker", "picket", "wage", "industrial", "cfmeu", "workplace", "unemployment", "labour", "fair work"],
  "Middle East": ["gaza", "palestine", "israel", "occupation", "zionism", "rafah", "genocide", "iran", "tehran", "lebanon", "beirut", "yemen", "houthi"],
  "Climate": ["climate", "environment", "warming", "coal", "gas", "emission", "green", "renewables"],
  "International": ["imperialism", "china", "usa", "nato", "ukraine", "russia", "global", "war", "united states", "biden", "trump", "europe"],
  "Anti-Fascism": ["fascism", "far-right", "nazi", "racism", "protest", "police", "surveillance"]
};

/// ===========================================================================
/// 6. MAIN DASHBOARD LOGIC
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
  
  List<Article> masterArticles = []; // Complete news list
  List<Article> filteredArticles = []; // List shown on screen
  bool isLoading = true; // Tracks if data is downloading
  bool isExtendedCoverageEnabled = false; // Toggle state
  String currentFilter = "ALL"; // Topic tab selected
  final TextEditingController _searchController = TextEditingController(); // Search bar logic

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  /// STARTUP SEQUENCE
  void _startApp() async {
    loadNews(); // Download the news articles immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isExtendedCoverageEnabled = prefs.getBool('extended_coverage') ?? false;
      });
    } catch (e) {
      debugPrint("Toggle load error: $e");
    }
  }

  /// MEMORY: Save the "Extended Coverage" toggle
  Future<void> _toggleExtendedCoverage(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('extended_coverage', val);
    setState(() {
      isExtendedCoverageEnabled = val;
      isLoading = true; // Show loading screen while we update the list
    });
    loadNews();
  }

  /// THE LOADER: Downloads feeds, filters global news, and assigns topics
  Future<void> loadNews() async {
    List<Article> allFetched = [];
    
    // Combine local + global sources
    Map<String, String> activeSources = Map.from(coreSources);
    activeSources.addAll(globalSources); 
    
    // Add extended sources if toggle is ON
    if (isExtendedCoverageEnabled) {
      activeSources.addAll(extendedSources);
    }

    // Loop through each source and download data
    for (var entry in activeSources.entries) {
      try {
        final response = await http.get(Uri.parse(
            'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(entry.key)}'
        ));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'ok') {
            for (var item in data['items']) {
              String content = (item['title'] + (item['description'] ?? "")).toLowerCase();
              
              // GLOBAL FILTER: If it's a Global source, require Australian keywords
              bool isGlobal = globalSources.containsValue(entry.value);
              if (isGlobal) {
                bool hasAuKeyword = australianKeywords.any((keyword) => content.contains(keyword));
                if (!hasAuKeyword) continue; // Skip articles without local relevance
              }

              // Apply topic categories
              List<String> topics = [];
              topicConfig.forEach((key, keywords) {
                if (keywords.any((kw) => content.contains(kw))) topics.add(key);
              });
              
              allFetched.add(Article.fromJson(item, entry.value, topics));
            }
          }
        }
      } catch (e) {
        debugPrint("Skipping source ${entry.value} due to error: $e");
      }
    }

    // Sort: Newest articles at the top
    allFetched.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    if (mounted) {
      setState(() {
        masterArticles = allFetched;
        filteredArticles = allFetched;
        isLoading = false; 
        applyFilter(currentFilter); // Re-apply current topic tab filter
      });
    }
  }

  /// DATE LOGIC: Creates modern date strings (e.g. "2 days ago (07/04/2026)")
  String getFormattedArticleDate(String dateStr) {
    try {
      DateTime postDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      Duration diff = now.difference(postDate);

      // Standard date format: dd/MM/yyyy
      String dateOnly = DateFormat('dd/MM/yyyy').format(postDate);

      // If the article is 3 days old or newer, add the "Time Ago" prefix
      if (diff.inDays <= 3) {
        String relative;
        if (diff.inMinutes < 60) {
          relative = "${diff.inMinutes}m ago";
        } else if (diff.inHours < 24) {
          relative = "${diff.inHours}h ago";
        } else {
          relative = "${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago";
        }
        return "$relative ($dateOnly)";
      } else {
        // If older than 3 days, just show the date
        return dateOnly;
      }
    } catch (e) {
      return "Recent";
    }
  }

  /// UI LOGIC: Filter list by topic tab
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

  /// UI LOGIC: Search list by typing
  void handleSearch(String query) {
    setState(() {
      filteredArticles = masterArticles.where((a) {
        final q = query.toLowerCase();
        return a.title.toLowerCase().contains(q) || a.source.toLowerCase().contains(q);
      }).toList();
    });
  }

  /// ===========================================================================
  /// 7. USER INTERFACE (BUILD)
  /// ===========================================================================
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Responsive columns: 3 for desktop, 2 for tablet, 1 for phone
    int crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

    return Scaffold(
      key: _scaffoldKey, // Link to sidebar controller
      endDrawer: _buildSidebar(), // The Settings Sidebar
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

  /// UI: Top Gold Banner
  Widget _buildBetaBanner() {
    return Container(
      width: double.infinity,
      color: widget.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        "THIS WEBSITE IS STILL IN BETA — DEVELOPMENT IN PROGRESS",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.pureBlack, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }

  /// UI: Logo and Search area
  Widget _buildHeader(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.glassOverlay,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
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
    );
  }

  /// UI: Spinner
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

  /// UI: Error state if nothing found
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FontAwesomeIcons.circleExclamation, size: 40, color: AppColors.textSubtle),
          const SizedBox(height: 20),
          const Text("NO ARTICLES FOUND", style: TextStyle(letterSpacing: 2, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          TextButton(onPressed: loadNews, child: Text("RETRY", style: TextStyle(color: widget.primaryColor)))
        ],
      ),
    );
  }

  /// UI: Article Grid Layout
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
                    style: GoogleFonts.spaceGrotesk(fontSize: screenWidth > 600 ? 60 : 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, letterSpacing: -2, color: AppColors.textMain),
                  ),
                ),
                if (screenWidth > 600)
                  Text("REFRESHED: ${DateFormat('HH:mm').format(DateTime.now())}", style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
              ],
            ),
          ),
        ),
        // Headline feature
        if (filteredArticles.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverToBoxAdapter(child: _buildHero(filteredArticles[0])),
          ),
        // Grid of articles
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 40,
              mainAxisSpacing: 60,
              // Lowered aspect ratio slightly to fit description text properly
              childAspectRatio: 0.72, 
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

  /// UI: Featured Headline Widget
  Widget _buildHero(Article art) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(art.link)),
      child: Container(
        height: 450,
        decoration: BoxDecoration(color: AppColors.appSurface, border: Border.all(color: AppColors.borderSubtle)),
        child: Stack(
          children: [
            art.thumbnail.isNotEmpty
                ? Positioned.fill(child: Image.network(art.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: AppColors.pureBlack)))
                : Container(color: AppColors.textSubtle),
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.appBackground])))),
            Positioned(
              top: 20,
              left: 20,
              child: Wrap(
                spacing: 8,
                children: [
                  _badge("LATEST NEWS", widget.primaryColor, AppColors.pureBlack),
                  ...art.topics.map((t) => _badge(t, AppColors.textMain, AppColors.pureBlack)),
                ],
              ),
            ),
            Positioned(bottom: 40, left: 40, right: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // HERO DATE ROW
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

  /// UI: Standard Article Card Widget
  Widget _buildArticleCard(Article art) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(art.link)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(color: AppColors.appSurface, border: Border.all(color: AppColors.borderSubtle)),
            child: art.thumbnail.isNotEmpty 
              ? Image.network(art.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(FontAwesomeIcons.satelliteDish, color: AppColors.textSubtle))
              : const Center(child: Icon(FontAwesomeIcons.satelliteDish, color: AppColors.textSubtle)),
          ),
        ),
        const SizedBox(height: 16),
        // CARD DATE ROW
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
        Text(art.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3, color: AppColors.textMain)),
        const SizedBox(height: 8),
        // THIS IS THE RESTORED SUMMARY TEXT!
        Text(art.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  /// UI: Label helper
  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg),
      child: Text(text.toUpperCase(), style: TextStyle(color: textCol, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  /// UI: Settings Drawer
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

  /// UI: Extended coverage toggle
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
          const Text(
            "Broaden the signal to include independent investigative reporting and broad-perspective analysis.",
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sidebarSectionTitle(IconData icon, String title) {
    return Row(children: [Icon(icon, size: 10, color: AppColors.textSubtle), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSubtle))]);
  }

  /// UI: Theme palette selection
  Widget _buildThemePicker() {
    return Wrap(
      spacing: 10, runSpacing: 10, 
      // Loops through our new Centralized AppColors list
      children: AppColors.allThemes.map((color) => GestureDetector(
        onTap: () => widget.onThemeChanged(color), 
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, border: Border.all(color: widget.primaryColor == color ? AppColors.textMain : Colors.transparent, width: 2)))
      )).toList()
    );
  }

  /// UI: Topic filter tabs
  Widget _buildTopicFilters() {
    List<String> topics = ["ALL", ...topicConfig.keys];
    return Column(children: topics.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: SizedBox(width: double.infinity, child: TextButton(onPressed: () => applyFilter(t), style: TextButton.styleFrom(alignment: Alignment.centerLeft, backgroundColor: currentFilter == t ? widget.primaryColor : Colors.transparent, shape: const RoundedRectangleBorder(), side: BorderSide(color: currentFilter == t ? widget.primaryColor : AppColors.borderSubtle), padding: const EdgeInsets.all(16)), child: Text(t.toUpperCase(), style: TextStyle(color: currentFilter == t ? AppColors.pureBlack : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)))))).toList());
  }
}
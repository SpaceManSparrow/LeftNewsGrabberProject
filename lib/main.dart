import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===========================================================================
/// 1. DESIGN SYSTEM
/// ===========================================================================
class AppColors {
  static const Color appBackground = Color(0xFF0e0e0e); 
  static const Color appSurface = Color(0xFF131313); 
  static const Color tileBackground = Color(0xFF151515); 
  static const Color borderSubtle = Colors.white10; 
  static const Color highlightOverlay = Color(0x0DFFFFFF); 

  static const Color textMain = Colors.white; 
  static const Color textMuted = Colors.white54; 
  static const Color textSubtle = Colors.white38; 

  static const List<Color> themeChoices = [
    Color(0xFFf59e0b), Color(0xFFf43f5e), Color(0xFF8b5cf6), 
    Color(0xFF6366f1), Color(0xFF3b82f6), Color(0xFF10b981)
  ];
}

/// ===========================================================================
/// 2. APP CONFIGURATION
/// ===========================================================================
class AppConfig {
  static const Map<String, String> coreSources = {
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
    "https://temokalati.wordpress.com/feed": "TEMOKALATI",
    "https://www.thenews.coop/country/oceania/feed": "CO-OP NEWS",
    "https://seqldiww.org/category/australia/feed": "IWW (SOUTH EAST QUEENSLAND)"
  };

  static const Map<String, String> globalSources = { "https://jacobin.com/feed": "JACOBIN" };

  static const Map<String, String> extendedSources = {
    "https://michaelwest.com.au/category/latest-posts/feed/": "MICHAEL WEST",
    "http://feeds.feedburner.com/IndependentAustralia": "INDEPENDENT AUSTRALIA",
    "https://theconversation.com/topics/australia-64/articles.atom": "THE CONVERSATION",
    "https://www.theguardian.com/australia-news/australian-trade-unions/rss": "THE GUARDIAN"
  };

  static const List<String> auKeywords = [
    "australia", "australian", "sydney", "melbourne", "brisbane", "perth", 
    "adelaide", "canberra", "hobart", "darwin", "victoria", "queensland", 
    "tasmania", "nsw", "vic", "qld", "western australia"
  ];

  static const Map<String, List<String>> topics = {
    "ECONOMY": ["economy", "economic", "inflation", "tax", "wealth", "budget"],
    "ENVIRONMENT": ["climate", "environment", "warming", "emissions", "coal", "gas"],
    "FIRST NATIONS": ["first nations", "indigenous", "aboriginal", "treaty", "voice"],
    "INTERNATIONAL": ["international", "global", "war", "imperialism", "nato", "ukraine"],
    "LABOUR": ["labour", "worker", "union", "strike", "industrial", "wage", "cfmeu"],
    "MUTUAL AID": ["mutual aid", "solidarity", "community", "co-op", "cooperative"],
    "PARLIAMENT": ["parliament", "government", "senate", "election", "albanese", "dutton"],
    "PRAXIS": ["praxis", "protest", "activism", "organizing", "demonstration"],
    "TECHNOLOGY": ["technology", "AI", "artificial intelligence", "surveillance", "privacy"]
  };
}

void main() => runApp(const TheRadicalApp());

/// ===========================================================================
/// 3. ROOT WIDGET
/// ===========================================================================
class TheRadicalApp extends StatefulWidget {
  const TheRadicalApp({super.key});
  @override
  State<TheRadicalApp> createState() => _TheRadicalAppState();
}

class _TheRadicalAppState extends State<TheRadicalApp> {
  Color primaryColor = AppColors.themeChoices[0];

  Future<void> _initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) primaryColor = Color(colorValue);
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  void updateTheme(Color newColor) async {
    setState(() => primaryColor = newColor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', newColor.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: AppColors.appBackground);
        }
        return MaterialApp(
          title: 'The Radical',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.appBackground,
            primaryColor: primaryColor,
            colorScheme: ColorScheme.dark(primary: primaryColor),
            textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
          ),
          home: NewsDashboard(primaryColor: primaryColor, onThemeChanged: updateTheme),
        );
      }
    );
  }
}

/// ===========================================================================
/// 4. ARTICLE DATA MODEL & PARSING ENGINE
/// ===========================================================================
class Article {
  final String title, link, description, source, thumbnail;
  final DateTime parsedDate;
  final List<String> topics;

  Article({
    required this.title, required this.link, required this.parsedDate,
    required this.description, required this.source,
    required this.thumbnail, required this.topics,
  });

  /// SMART DATE PARSER: Handles RFC 822 (RSS) and ISO 8601 (Atom)
  static DateTime parseRssDate(String dateString) {
    if (dateString.isEmpty) return DateTime.now();
    DateTime? result = DateTime.tryParse(dateString);
    if (result != null) return result;

    try {
      // Strips timezone offset (+0000) which DateFormat struggles with
      String cleaned = dateString.split(' +').first.split(' -').first;
      return DateFormat("E, d MMM yyyy HH:mm:ss").parse(cleaned);
    } catch (_) {
      try {
        return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  static String wrapProxy(String url) {
    if (url.isEmpty) return "";
    if (!kIsWeb) return url;
    if (url.startsWith('https://images.weserv.nl')) return url;
    String clean = url;
    if (clean.contains("i0.wp.com/")) {
      clean = "https://" + clean.split("i0.wp.com/").last.split("?").first;
    }
    clean = Uri.decodeFull(clean);
    return "https://images.weserv.nl/?url=${Uri.encodeComponent(clean)}&w=1200&fit=cover&output=webp";
  }

  static String cleanHtml(String html) {
    return html.replaceAll(RegExp(r'<img[^>]*>'), '').replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  static String scrapeImage(String html) {
    RegExp imgExp = RegExp(r'<img[^>]+src="([^">]+)"');
    var matches = imgExp.allMatches(html);
    return matches.isNotEmpty ? matches.first.group(1) ?? '' : '';
  }
}

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
  final PageController _heroController = PageController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Article> _allArticles = [];
  List<Article> _displayList = [];
  bool _isLoading = true;
  bool _extendedMode = false;
  String _activeFilter = "ALL";
  int _heroIndex = 0;
  Timer? _autoScrollTimer;

  int _totalSources = 0;
  int _completedSources = 0;
  String _statusMessage = "Ready";

  @override
  void initState() {
    super.initState();
    _bootSequence();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootSequence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _extendedMode = prefs.getBool('extended_coverage') ?? false);
    } catch (e) { debugPrint("Pref error: $e"); }
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _completedSources = 0;
      _allArticles = [];
      _statusMessage = kIsWeb ? "Deploying Bridge..." : "Direct Link Established...";
    });

    final sources = Map.from(AppConfig.coreSources)..addAll(AppConfig.globalSources);
    if (_extendedMode) sources.addAll(AppConfig.extendedSources);

    _totalSources = sources.length;
    List<Article> results = [];
    Set<String> seenLinks = {};

    int stagger = 0;
    List<Future<void>> tasks = sources.entries.map((entry) async {
      stagger += kIsWeb ? 200 : 50; 
      await Future.delayed(Duration(milliseconds: stagger));
      
      try {
        String finalUrl = kIsWeb ? 'https://api.allorigins.win/get?url=${Uri.encodeComponent(entry.key)}' : entry.key;
        final response = await http.get(Uri.parse(finalUrl)).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          String rawXml = kIsWeb ? json.decode(response.body)['contents'] : response.body;
          final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
          final atomRegex = RegExp(r'<entry>(.*?)</entry>', dotAll: true);
          
          Iterable<RegExpMatch> items = itemRegex.allMatches(rawXml);
          if (items.isEmpty) items = atomRegex.allMatches(rawXml);

          for (var match in items) {
            final content = match.group(1) ?? '';
            String title = RegExp(r'<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>', dotAll: true).firstMatch(content)?.group(1) ?? 'Untitled';
            String link = RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true).firstMatch(content)?.group(1) ?? '';
            String pubDateStr = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(content)?.group(1) ?? 
                                RegExp(r'<published>(.*?)</published>', dotAll: true).firstMatch(content)?.group(1) ?? '';
            String desc = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(content)?.group(1) ?? 
                          RegExp(r'<content.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</content>', dotAll: true).firstMatch(content)?.group(1) ?? '';

            if (seenLinks.contains(link) || link.isEmpty) continue;
            seenLinks.add(link);

            String searchable = "$title $desc".toLowerCase();
            if (AppConfig.globalSources.containsValue(entry.value) && !AppConfig.auKeywords.any((k) => searchable.contains(k))) continue;

            List<String> tags = [];
            AppConfig.topics.forEach((name, keywords) { if (keywords.any((k) => searchable.contains(k))) { if (!tags.contains(name)) tags.add(name); } });

            String thumb = Article.scrapeImage(desc);
            if (thumb.isEmpty) thumb = RegExp(r'<media:content[^>]+url="(.*?)"').firstMatch(content)?.group(1) ?? '';

            results.add(Article(
              title: title, link: link, source: entry.value, topics: tags,
              description: Article.cleanHtml(desc),
              thumbnail: Article.wrapProxy(thumb),
              parsedDate: Article.parseRssDate(pubDateStr),
            ));
          }
        }
      } catch (e) { debugPrint("Failure for ${entry.value}: $e"); }
      finally { if (mounted) setState(() { _completedSources++; _statusMessage = "Receiving: ${entry.value}"; }); }
    }).toList();

    await Future.wait(tasks);
    results.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
    
    if (mounted) setState(() { _allArticles = results; _displayList = results; _isLoading = false; _applyLogic(); _startCarousel(); });
  }

  void _applyLogic() {
    setState(() { _displayList = (_activeFilter == "ALL") ? _allArticles : _allArticles.where((a) => a.topics.contains(_activeFilter)).toList(); });
  }

  void _handleSearch(String q) {
    setState(() { _displayList = _allArticles.where((a) => a.title.toLowerCase().contains(q.toLowerCase()) || a.source.toLowerCase().contains(q.toLowerCase())).toList(); });
  }

  void _startCarousel() {
    _autoScrollTimer?.cancel();
    if (_displayList.length < 3) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (t) { if (_heroController.hasClients) { int next = (_heroIndex + 1) % 3; _heroController.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut); } });
  }

  String _formatDate(DateTime postDate) {
    try {
      Duration diff = DateTime.now().difference(postDate);
      String formatted = DateFormat('dd/MM/yyyy').format(postDate);
      if (diff.inDays <= 3 && !diff.isNegative) {
        if (diff.inMinutes < 60) return "${diff.inMinutes}m ago ($formatted)";
        if (diff.inHours < 24) return "${diff.inHours}h ago ($formatted)";
        return "${diff.inDays}d ago ($formatted)";
      }
      return formatted;
    } catch (e) { return "Recent"; }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey, endDrawer: _buildSidebar(),
      body: Column( children: [ _fixedTopSection(width), Expanded(child: _isLoading ? _loader() : (_allArticles.isEmpty ? _emptyState() : _mainScrollArea(width))), ], ),
    );
  }

  Widget _fixedTopSection(double width) {
    return Column( children: [
        Container( width: double.infinity, color: widget.primaryColor, padding: const EdgeInsets.symmetric(vertical: 6), child: const Text("THIS WEBSITE IS STILL IN BETA — DEVELOPMENT IN PROGRESS", textAlign: TextAlign.center, style: TextStyle(color: AppColors.appBackground, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)), ),
        Container( width: double.infinity, decoration: const BoxDecoration(color: AppColors.appBackground, border: Border(bottom: BorderSide(color: AppColors.borderSubtle))), child: Center( child: Container( constraints: const BoxConstraints(maxWidth: 1800), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Row( children: [ GestureDetector(onTap: () { setState(() => _activeFilter = "ALL"); _applyLogic(); }, child: Text(width > 500 ? "THE RADICAL" : "TR", style: GoogleFonts.spaceGrotesk(color: widget.primaryColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1))), const SizedBox(width: 20), Expanded(child: _searchBar()), const SizedBox(width: 20), _settingsButton(width), ], ), ), ), ),
      ], );
  }

  Widget _searchBar() {
    return Container( constraints: const BoxConstraints(maxWidth: 600), child: TextField( controller: _searchController, onChanged: _handleSearch, style: const TextStyle(fontSize: 13, color: AppColors.textMain), decoration: InputDecoration( hintText: "Search articles...", hintStyle: const TextStyle(color: AppColors.textMuted), prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 12, color: AppColors.textMuted), filled: true, fillColor: AppColors.highlightOverlay, contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none), ), ), );
  }

  Widget _settingsButton(double width) {
    return ElevatedButton( onPressed: () => _scaffoldKey.currentState?.openEndDrawer(), style: ElevatedButton.styleFrom(backgroundColor: AppColors.highlightOverlay, foregroundColor: AppColors.textMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)), side: const BorderSide(color: AppColors.borderSubtle)), child: Row(children: [if (width > 700) ...[const Text("SETTINGS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(width: 10)], Icon(FontAwesomeIcons.sliders, size: 12, color: widget.primaryColor)]), );
  }

  Widget _mainScrollArea(double width) {
    int cols = width > 1200 ? 3 : (width > 800 ? 2 : 1);
    return ListView( children: [ Center( child: Container( constraints: const BoxConstraints(maxWidth: 1800), child: Column( children: [ _sectionHeader(width), if (_displayList.isNotEmpty) _buildHeroCarousel(width), _grid(cols), ], ), ), ), ], );
  }

  Widget _sectionHeader(double width) {
    return Padding( padding: const EdgeInsets.all(32), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [ Expanded(child: Text("RECENT NEWS", style: GoogleFonts.spaceGrotesk(fontSize: width > 600 ? 60 : 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: AppColors.textMain))), if (width > 600) Text("REFRESHED: ${DateFormat('HH:mm').format(DateTime.now())}", style: const TextStyle(fontSize: 10, color: AppColors.textMuted)), ], ), );
  }

  Widget _buildHeroCarousel(double width) {
    final items = _displayList.take(3).toList();
    return Padding( padding: const EdgeInsets.symmetric(horizontal: 32), child: Stack( alignment: Alignment.center, children: [ SizedBox( height: 450, child: PageView.builder( controller: _heroController, onPageChanged: (i) => setState(() => _heroIndex = i), itemCount: items.length, itemBuilder: (c, i) => _heroTile(items[i]), ), ), if (width > 1000) ...[ Positioned(left: 15, child: _arrow(FontAwesomeIcons.chevronLeft, () => _heroController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.ease))), Positioned(right: 15, child: _arrow(FontAwesomeIcons.chevronRight, () => _heroController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease))), ], ], ), );
  }

  Widget _heroTile(Article a) {
    return InkWell( onTap: () => launchUrl(Uri.parse(a.link)), child: Container( decoration: BoxDecoration(color: AppColors.tileBackground, border: Border.all(color: AppColors.borderSubtle)), child: Stack( children: [ if (a.thumbnail.isNotEmpty) Positioned.fill(child: Image.network(a.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container())), Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.appBackground])))), Positioned(top: 20, left: 20, child: Wrap(spacing: 8, children: [_badge("LATEST", widget.primaryColor, AppColors.appBackground), ...a.topics.map((t) => _badge(t, AppColors.textMain, AppColors.appBackground))])), Positioned(bottom: 40, left: 40, right: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("${a.source} • ${_formatDate(a.parsedDate)}".toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(a.title, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)), ])), ], ), ), );
  }

  Widget _grid(int cols) {
    return Padding( padding: const EdgeInsets.all(32), child: GridView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 30, mainAxisSpacing: 40, childAspectRatio: 0.85), itemCount: _displayList.length > 3 ? _displayList.length - 3 : 0, itemBuilder: (c, i) => _articleCard(_displayList[i + 3]), ), );
  }

  Widget _articleCard(Article a) {
    return InkWell( onTap: () => launchUrl(Uri.parse(a.link)), child: Container( decoration: BoxDecoration(color: AppColors.tileBackground, border: Border.all(color: AppColors.borderSubtle)), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ AspectRatio(aspectRatio: 16 / 9, child: Container(color: Colors.black26, child: a.thumbnail.isNotEmpty ? Image.network(a.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(FontAwesomeIcons.satelliteDish, color: AppColors.textSubtle)) : const Icon(FontAwesomeIcons.satelliteDish, color: AppColors.textSubtle))), Padding( padding: const EdgeInsets.all(16), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(_formatDate(a.parsedDate).toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.textSubtle, fontWeight: FontWeight.bold)), const SizedBox(height: 8), if (a.topics.isNotEmpty) ...[Wrap(spacing: 4, runSpacing: 4, children: a.topics.map((t) => _badge(t, AppColors.highlightOverlay, AppColors.textMain)).toList()), const SizedBox(height: 8)], Text(a.source, style: TextStyle(color: widget.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 8), SizedBox(height: 48, child: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold))), const SizedBox(height: 8), SizedBox(height: 40, child: Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))), ], ), ) ], ), ), );
  }

  Widget _buildSidebar() {
    return Drawer( backgroundColor: AppColors.appSurface, child: ListView( padding: const EdgeInsets.all(24), children: [ const SizedBox(height: 60), Row(children: [Icon(FontAwesomeIcons.gear, color: widget.primaryColor), const SizedBox(width: 12), const Text("CONTROL PANEL", style: TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 30), _coverageToggle(), const SizedBox(height: 40), const Text("THEME PALETTE", style: TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.bold)), const SizedBox(height: 10), _themePicker(), const SizedBox(height: 40), const Text("TOPIC FILTERS", style: TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.bold)), const SizedBox(height: 10), _topicList(), ], ), );
  }

  Widget _coverageToggle() {
    return SwitchListTile( title: const Text("EXTENDED COVERAGE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), subtitle: const Text("Include broader independent sources.", style: TextStyle(fontSize: 10)), value: _extendedMode, activeThumbColor: widget.primaryColor, onChanged: (v) async { try { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('extended_coverage', v); } catch (e) { debugPrint("Save failed: $e"); } setState(() => _extendedMode = v); _fetchNews(); }, );
  }

  Widget _themePicker() {
    return Wrap(spacing: 10, runSpacing: 10, children: AppColors.themeChoices.map((c) => GestureDetector(onTap: () => widget.onThemeChanged(c), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: c, border: Border.all(color: widget.primaryColor == c ? Colors.white : Colors.transparent, width: 2))))).toList());
  }

  Widget _topicList() {
    final t = ["ALL", ...AppConfig.topics.keys];
    return Column(children: t.map((name) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: TextButton(onPressed: () { setState(() => _activeFilter = name); _applyLogic(); Navigator.pop(context); }, style: TextButton.styleFrom(backgroundColor: _activeFilter == name ? widget.primaryColor : Colors.transparent, alignment: Alignment.centerLeft, side: BorderSide(color: _activeFilter == name ? widget.primaryColor : AppColors.borderSubtle)), child: Text(name, style: TextStyle(color: _activeFilter == name ? Colors.black : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)))))).toList());
  }

  Widget _badge(String t, Color bg, Color tc) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: bg, child: Text(t, style: TextStyle(color: tc, fontSize: 9, fontWeight: FontWeight.bold)));
  Widget _arrow(IconData i, VoidCallback o) => GestureDetector(onTap: o, child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: Icon(i, size: 16)));
  
  Widget _loader() {
    double progress = _totalSources > 0 ? _completedSources / _totalSources : 0;
    return Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ CircularProgressIndicator(value: (progress == 0) ? null : progress, color: widget.primaryColor, strokeWidth: 6), const SizedBox(height: 30), Text("${(progress * 100).toInt()}%", style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("RECEIVING SIGNALS...", style: TextStyle(color: widget.primaryColor, fontSize: 10, letterSpacing: 4)), const SizedBox(height: 20), Text(_statusMessage.toUpperCase(), style: const TextStyle(color: AppColors.textSubtle, fontSize: 9, letterSpacing: 1)), ], ), );
  }

  Widget _emptyState() => const Center(child: Text("NO SIGNALS FOUND"));
}
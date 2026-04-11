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

import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../models/article.dart';
import '../services/feed_parser.dart';

class NewsDashboard extends StatefulWidget {
  final Color primaryColor;
  final Function(Color) onThemeChanged;
  const NewsDashboard({
    super.key,
    required this.primaryColor,
    required this.onThemeChanged,
  });

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootSequence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _extendedMode = prefs.getBool('extended_coverage') ?? false);
    } catch (e) {
      debugPrint("Preference load error: $e");
    }
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _completedSources = 0;
      _allArticles = [];
      _statusMessage = kIsWeb ? "Securing Bridge..." : "Connecting Direct...";
    });

    final sources = Map.from(AppConfig.coreSources)..addAll(AppConfig.globalSources);
    if (_extendedMode) sources.addAll(AppConfig.extendedSources);

    _totalSources = sources.length;
    List<Article> results = [];
    Set<String> seenLinks = {};

    for (var entry in sources.entries) {
      if (!mounted) break;
      setState(() => _statusMessage = "Receiving: ${entry.value}");
      try {
        String finalUrl = kIsWeb ? 'https://corsproxy.io/?${Uri.encodeComponent(entry.key)}' : entry.key;
        final response = await http.get(Uri.parse(finalUrl)).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          String rawXml = utf8.decode(response.bodyBytes, allowMalformed: true);

          // Delegate parsing to FeedParser Service
          final List<Article> parsedArticles = FeedParser.parse(rawXml, entry.value);

          for (var article in parsedArticles) {
            if (seenLinks.contains(article.link) || article.link.isEmpty) continue;

            // Global Filter Logic
            if (AppConfig.globalSources.containsValue(entry.value)) {
              String searchable = "${article.title} ${article.description}".toLowerCase();
              if (!AppConfig.auKeywords.any((k) => searchable.contains(k))) continue;
            }

            seenLinks.add(article.link);
            results.add(article);
          }
        }
      } catch (e) {
        debugPrint("Link failure for ${entry.value}: $e");
      } finally {
        if (mounted) setState(() => _completedSources++);
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    results.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));

    if (mounted) {
      setState(() {
        _allArticles = results;
        _displayList = results;
        _isLoading = false;
        _applyLogic();
        _startCarousel();
      });
    }
  }

  void _applyLogic() {
    setState(() {
      _displayList = (_activeFilter == "ALL")
      ? _allArticles
      : _allArticles.where((a) => a.topics.contains(_activeFilter)).toList();
    });
  }

  void _handleSearch(String q) {
    setState(() {
      _displayList = _allArticles
      .where((a) => a.title.toLowerCase().contains(q.toLowerCase()) ||
      a.source.toLowerCase().contains(q.toLowerCase()))
      .toList();
    });
  }

  void _startCarousel() {
    _autoScrollTimer?.cancel();
    if (_displayList.length < 3) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (_heroController.hasClients) {
        int next = (_heroIndex + 1) % 3;
        _heroController.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
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
      key: _scaffoldKey,
      endDrawer: _buildSidebar(),
      body: Column(
        children: [
          _fixedTopSection(width),
          Expanded(
            child: _isLoading ? _loader() : (_allArticles.isEmpty ? _emptyState() : _mainScrollArea(width)),
          ),
        ],
      ),
    );
  }

  Widget _fixedTopSection(double width) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: widget.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: const Text(
            "THIS WEBSITE IS STILL IN BETA — DEVELOPMENT IN PROGRESS",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.appBackground, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: AppColors.appBackground, border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1800),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { setState(() => _activeFilter = "ALL"); _applyLogic(); },
                    child: Text(width > 500 ? "THE RADICAL" : "TR", style: GoogleFonts.spaceGrotesk(color: widget.primaryColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: _searchBar()),
                  const SizedBox(width: 20),
                  _settingsButton(width),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearch,
        style: const TextStyle(fontSize: 13, color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: "Search articles...",
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 12, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.highlightOverlay,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _settingsButton(double width) {
    return ElevatedButton(
      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.highlightOverlay,
        foregroundColor: AppColors.textMain,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          if (width > 700) ...[const Text("SETTINGS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(width: 10)],
            Icon(FontAwesomeIcons.sliders, size: 12, color: widget.primaryColor)
        ],
      ),
    );
  }

  Widget _mainScrollArea(double width) {
    const double articleGap = 30.0; // Centralized gap variable

    return ListView(
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1754), 
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                _sectionHeader(width),
                if (_displayList.isNotEmpty) _buildHeroCarousel(width),
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    spacing: articleGap,     // Same horizontal gap
                    runSpacing: articleGap,  // Same vertical gap
                    alignment: WrapAlignment.center,
                    children: _displayList.length > 3 
                        ? _displayList.skip(3).map((a) => _articleCard(a)).toList() 
                        : [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(double width) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text("RECENT NEWS", style: GoogleFonts.spaceGrotesk(fontSize: width > 600 ? 60 : 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: AppColors.textMain))),
          if (width > 600) Text("REFRESHED: ${DateFormat('HH:mm').format(DateTime.now())}", style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(double width) {
    final items = _displayList.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: width > 700 ? 2.1 : 1.0,
            child: PageView.builder(
              controller: _heroController,
              onPageChanged: (i) => setState(() => _heroIndex = i),
              itemCount: items.length,
              itemBuilder: (c, i) => _heroTile(items[i]),
            ),
          ),
          if (width > 1000) ...[
            Positioned(left: 15, child: _arrow(FontAwesomeIcons.chevronLeft, () => _heroController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.ease))),
            Positioned(right: 15, child: _arrow(FontAwesomeIcons.chevronRight, () => _heroController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease))),
          ],
        ],
      ),
    );
  }

  Widget _heroTile(Article a) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(a.link)),
      child: Container(
        decoration: BoxDecoration(color: AppColors.tileBackground, border: Border.all(color: AppColors.borderSubtle)),
        child: Stack(
          children: [
            if (a.thumbnail.isNotEmpty) Positioned.fill(child: Image.network(a.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container())),
              Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.appBackground])))),
              Positioned(top: 20, left: 20, child: Wrap(spacing: 8, children: [_badge("LATEST", widget.primaryColor, AppColors.appBackground), ...a.topics.map((t) => _badge(t, AppColors.textMain, AppColors.appBackground))])),
              Positioned(bottom: 40, left: 40, right: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${a.source} • ${_formatDate(a.parsedDate)}".toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(a.title, style: GoogleFonts.spaceGrotesk(fontSize: 42, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))])),
          ],
        ),
      ),
    );
  }

  Widget _articleCard(Article a) {
    // SURGICAL TRIMMING LOGIC
    const int charLimit = 85; 
    String text = a.description.length > charLimit ? a.description.substring(0, charLimit) : a.description;
    text = text.trimRight();
    
    if (text.endsWith('.')) {
      // Remove dot, word, and space
      String temp = text.substring(0, text.length - 1).trimRight();
      int lastSpace = temp.lastIndexOf(' ');
      text = lastSpace != -1 ? temp.substring(0, lastSpace) : temp;
    } else if (RegExp(r'[,;:\-!?]$').hasMatch(text)) {
      // Remove specific grammar
      text = text.substring(0, text.length - 1);
    }
    text = text.trimRight();

    return Container(
      width: 400, // Hard locked width
      height: 580, // Hard locked height
      color: Colors.transparent,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(a.link)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5, 
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.tileBackground,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Stack(
                  children: [
                    if (a.thumbnail.isNotEmpty) 
                      Positioned.fill(child: Image.network(a.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(FontAwesomeIcons.satelliteDish, color: Colors.white10)))),
                    Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])))),
                    Positioned(top: 12, left: 12, child: Wrap(spacing: 4, runSpacing: 4, children: a.topics.map((t) => _badge(t, Colors.white, Colors.black)).toList())),
                    Positioned(bottom: 16, left: 16, right: 16, child: Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(a.parsedDate).toUpperCase(), style: const TextStyle(fontSize: 8, color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white),
                      children: [
                        TextSpan(
                          text: "${a.source}  ",
                          style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                        TextSpan(text: text),
                        const TextSpan(text: "... "),
                        const TextSpan(text: "more", style: TextStyle(color: AppColors.textSubtle)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: AppColors.appSurface,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Row(children: [Icon(FontAwesomeIcons.gear, color: widget.primaryColor), const SizedBox(width: 12), const Text("CONTROL PANEL", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 30),
          _coverageToggle(),
          const SizedBox(height: 40),
          const Text("THEME PALETTE", style: TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _themePicker(),
          const SizedBox(height: 40),
          const Text("TOPIC FILTERS", style: TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _topicList(),
          const SizedBox(height: 40),
          _sourcesButton(), 
          const SizedBox(height: 12),
          _aboutButton(),
        ],
      ),
    );
  }

  Widget _sourcesButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showSourcesDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
          color: AppColors.highlightOverlay,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.satelliteDish, size: 14, color: widget.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  "SIGNAL SOURCES",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
            Icon(FontAwesomeIcons.arrowRight, size: 10, color: widget.primaryColor),
          ],
        ),
      ),
    );
  }

  void _showSourcesDialog() {
    final allSources = Map.from(AppConfig.coreSources)..addAll(AppConfig.globalSources);
    if (_extendedMode) allSources.addAll(AppConfig.extendedSources);
    final sortedNames = allSources.values.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.appSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderSubtle)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ACTIVE SIGNALS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(FontAwesomeIcons.xmark, size: 18)),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedNames.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sortedNames[index], style: const TextStyle(fontSize: 11, color: AppColors.textMain, fontWeight: FontWeight.w500)),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent, 
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutButton() {
    return InkWell(
      onTap: () { Navigator.pop(context); _showAboutDialog(); },
      child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: widget.primaryColor)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(FontAwesomeIcons.circleInfo, size: 14, color: widget.primaryColor), const SizedBox(width: 12), const Text("ABOUT PROJECT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))]), Icon(FontAwesomeIcons.arrowRight, size: 10, color: widget.primaryColor)])),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.appSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderSubtle)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(FontAwesomeIcons.circleInfo, size: 16, color: widget.primaryColor), const SizedBox(width: 10), const Text("PROJECT BRIEFING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4))]), const SizedBox(height: 10), Text("THE RADICAL", style: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))]), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(FontAwesomeIcons.xmark, size: 18))]),
                const SizedBox(height: 30),
                Container(padding: const EdgeInsets.only(left: 20), decoration: BoxDecoration(border: Border(left: BorderSide(color: widget.primaryColor, width: 2))), child: const Text("The Radical is an independent news aggregator designed to centralise reporting from Australian political and social perspectives.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic))),
                const SizedBox(height: 20),
                const Text("Designed for tracking material and economic realities without having to manually check dozens of sources every day.", style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, foregroundColor: Colors.black, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), padding: const EdgeInsets.symmetric(vertical: 20)), child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverageToggle() {
    return SwitchListTile(
      title: const Text("EXTENDED COVERAGE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: const Text("Include broader independent sources.", style: TextStyle(fontSize: 10)),
      value: _extendedMode,
      activeThumbColor: widget.primaryColor,
      onChanged: (v) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('extended_coverage', v);
        } catch (e) { debugPrint("Save failed: $e"); }
        setState(() => _extendedMode = v);
        _fetchNews();
      },
    );
  }

  Widget _themePicker() {
    return Wrap(spacing: 10, runSpacing: 10, children: AppColors.themeChoices.map((c) => GestureDetector(onTap: () => widget.onThemeChanged(c), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: c, border: Border.all(color: widget.primaryColor == c ? Colors.white : Colors.transparent, width: 2))))).toList());
  }

  Widget _topicList() {
    final List<String> availableTopics = ["ALL", ...AppConfig.topics.keys];
    return Column(
      children: availableTopics.map((name) {
        bool isActive = _activeFilter == name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(width: double.infinity, child: TextButton(onPressed: () { setState(() => _activeFilter = name); _applyLogic(); Navigator.pop(context); }, style: TextButton.styleFrom(backgroundColor: isActive ? widget.primaryColor : Colors.transparent, alignment: Alignment.centerLeft, side: BorderSide(color: isActive ? widget.primaryColor : AppColors.borderSubtle)), child: Text(name, style: TextStyle(color: isActive ? Colors.black : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)))),
        );
      }).toList(),
    );
  }

  Widget _badge(String t, Color bg, Color tc) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: bg, child: Text(t, style: TextStyle(color: tc, fontSize: 9, fontWeight: FontWeight.bold)));

  Widget _arrow(IconData i, VoidCallback o) => GestureDetector(onTap: o, child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: Icon(i, size: 16)));

  Widget _loader() {
    double progress = _totalSources > 0 ? _completedSources / _totalSources : 0;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(value: (progress == 0) ? null : progress, color: widget.primaryColor, strokeWidth: 6), const SizedBox(height: 30), Text("${(progress * 100).toInt()}%", style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("RECEIVING SIGNALS...", style: TextStyle(color: widget.primaryColor, fontSize: 10, letterSpacing: 4)), const SizedBox(height: 20), Text(_statusMessage.toUpperCase(), style: const TextStyle(color: AppColors.textSubtle, fontSize: 9, letterSpacing: 1))]));
  }

  Widget _emptyState() => const Center(child: Text("NO SIGNALS FOUND"));
}
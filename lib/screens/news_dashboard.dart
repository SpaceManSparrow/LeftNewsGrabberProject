import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../models/article.dart';
import '../services/feed_parser.dart';

// Split UI Components
import 'dashboard_header.dart';
import 'dashboard_drawer.dart';
import 'dashboard_content_view.dart';
import 'dashboard_dialogs.dart';

/// ===========================================================================
/// NEWS DASHBOARD
/// The main entry point for the news feed. Manages state, background
/// synchronization, and the primary layout scaffold.
/// ===========================================================================
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
  // Global keys and controllers for layout management
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Data lists for article management
  List<Article> _allArticles = [];
  List<Article> _displayList = [];
  List<Article> _incomingArticles = [];

  // State flags for UI behavior
  int _visibleCount = 12;
  int _tabIndex = 0;
  bool _isLoading = true;
  bool _extendedMode = false;
  bool _prettyMode = false;
  bool _hasNewSignals = false;
  String _activeFilter = "ALL";

  // Progress tracking for the sync sequence
  int _totalSources = 0;
  int _completedSources = 0;
  String _statusMessage = "Ready";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _bootSequence();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// ===========================================================================
  /// LOGIC: SCROLL LISTENER
  /// Triggers pagination (lazy loading) when user nears the bottom.
  /// ===========================================================================
  void _scrollListener() {
    if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 400) {
      if (_visibleCount < _displayList.length) {
        setState(() {
          _visibleCount += 12;
        });
      }
      }
  }

  /// ===========================================================================
  /// LOGIC: BOOT SEQUENCE
  /// Loads saved preferences and offline cache before triggering a network fetch.
  /// ===========================================================================
  Future<void> _bootSequence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _extendedMode = prefs.getBool('extended_coverage') ?? false;
      _prettyMode = prefs.getBool('pretty_mode') ?? false;

      final String? cachedJson = prefs.getString('offline_cache');
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        setState(() {
          _allArticles = decoded.map((m) => Article.fromMap(m)).toList();
          _isLoading = false;
          _applyLogic();
        });
      }
    } catch (e) {
      debugPrint("Cache Error: $e");
    }
    _fetchNews(isBackground: _allArticles.isNotEmpty);
  }

  /// ===========================================================================
  /// LOGIC: FETCH NEWS
  /// Orchestrates the RSS parsing sequence from multiple sources.
  /// ===========================================================================
  Future<void> _fetchNews({bool isBackground = false}) async {
    if (!mounted) return;
    if (!isBackground) {
      setState(() {
        _isLoading = true;
      });
    }

    final sources = Map.from(AppConfig.coreSources)
    ..addAll(AppConfig.globalSources);
    if (_extendedMode) sources.addAll(AppConfig.extendedSources);

    _totalSources = sources.length;
    _completedSources = 0;
    List<Article> freshBatch = [];
    Set<String> currentLinks = _allArticles.map((a) => a.link).toSet();

    for (var entry in sources.entries) {
      if (!mounted) break;
      if (!isBackground) {
        setState(() {
          _statusMessage = "Receiving: ${entry.value}";
        });
      }

      try {
        String finalUrl = kIsWeb
        ? 'https://corsproxy.io/?${Uri.encodeComponent(entry.key)}'
        : entry.key;

        final response = await http
        .get(Uri.parse(finalUrl))
        .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          String rawXml = utf8.decode(
            response.bodyBytes,
            allowMalformed: true,
          );
          final parsed = FeedParser.parse(rawXml, entry.value);

          for (var article in parsed) {
            if (article.link.isEmpty) continue;
            if (!currentLinks.contains(article.link)) {
              freshBatch.add(article);
              currentLinks.add(article.link);
            }
          }
        }
      } catch (e) {
        debugPrint("Fetch Error: $e");
      } finally {
        if (mounted) {
          setState(() {
            _completedSources++;
          });
        }
      }
    }

    if (mounted) {
      if (isBackground) {
        if (freshBatch.isNotEmpty) {
          freshBatch.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
          setState(() {
            _incomingArticles = freshBatch;
            _hasNewSignals = true;
          });
        }
      } else {
        freshBatch.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
        setState(() {
          _allArticles = freshBatch;
          _isLoading = false;
          _applyLogic();
        });
        _saveToCache();
      }
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _allArticles.take(100).map((a) => a.toMap()).toList(),
      );
      await prefs.setString('offline_cache', encoded);
    } catch (_) {}
  }

  void _mergeNewSignals() {
    setState(() {
      _allArticles = [..._incomingArticles, ..._allArticles];
      _allArticles.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
      _incomingArticles = [];
      _hasNewSignals = false;
      _applyLogic();
    });
    _saveToCache();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _applyLogic() {
    setState(() {
      Iterable<Article> filtered = _allArticles;
      if (_activeFilter != "ALL") {
        filtered = filtered.where((a) => a.topics.contains(_activeFilter));
      }
      if (_prettyMode) {
        filtered = filtered.where((a) => a.thumbnail.isNotEmpty);
      }
      _displayList = filtered.toList();
      _visibleCount = 12;
    });
  }

  void _handleSearch(String q) {
    setState(() {
      _displayList = _allArticles
      .where((a) =>
      a.title.toLowerCase().contains(q.toLowerCase()) ||
      a.source.toLowerCase().contains(q.toLowerCase()))
      .toList();
      _visibleCount = 12;
    });
  }

  /// ===========================================================================
  /// UI: MAIN BUILDER
  /// The structural assembly of the dashboard.
  /// ===========================================================================
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: DashboardDrawer(
        primaryColor: widget.primaryColor,
        onThemeChanged: widget.onThemeChanged,
        prettyMode: _prettyMode,
        onPrettyModeChanged: (v) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pretty_mode', v);
          setState(() => _prettyMode = v);
          _applyLogic();
        },
        extendedMode: _extendedMode,
        onExtendedModeChanged: (v) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('extended_coverage', v);
          setState(() => _extendedMode = v);
          _fetchNews(isBackground: false);
        },
        activeFilter: _activeFilter,
        onFilterChanged: (name) {
          setState(() => _activeFilter = name);
          _applyLogic();
          Navigator.pop(context);
        },
        onShowSources: () {
          Navigator.pop(context);
          DashboardDialogs.showSourcesDialog(
            context,
            widget.primaryColor,
            _extendedMode,
          );
        },
        onShowAbout: () {
          Navigator.pop(context);
          DashboardDialogs.showAboutDialog(
            context,
            widget.primaryColor,
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          Column(
            children: [
              DashboardHeader(
                width: width,
                primaryColor: widget.primaryColor,
                searchController: _searchController,
                onSearchChanged: _handleSearch,
                onLogoTap: () {
                  setState(() => _activeFilter = "ALL");
                  _applyLogic();
                },
                onOpenSettings: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              Expanded(
                child: DashboardContentView(
                  tabIndex: _tabIndex,
                  isLoading: _isLoading,
                  width: width,
                  primaryColor: widget.primaryColor,
                  displayList: _displayList,
                  visibleCount: _visibleCount,
                  scrollController: _scrollController,
                  totalSources: _totalSources,
                  completedSources: _completedSources,
                  statusMessage: _statusMessage,
                  onRefresh: () => _fetchNews(isBackground: false),
                ),
              ),
            ],
          ),
          if (_hasNewSignals && _tabIndex == 0)
            DashboardContentView.newSignalPrompt(
              primaryColor: widget.primaryColor,
              incomingCount: _incomingArticles.length,
              onTap: _mergeNewSignals,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.appBackground,
        selectedItemColor: widget.primaryColor,
        unselectedItemColor: Colors.white24,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house, size: 18),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.play, size: 18),
            label: "Videos",
          ),
        ],
      ),
    );
  }
}

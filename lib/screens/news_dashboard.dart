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

import 'dashboard_header.dart';
import 'dashboard_drawer.dart';
import 'dashboard_content_view.dart';
import 'dashboard_dialogs.dart';

class NewsDashboard extends StatefulWidget {
  final Color primaryColor;
  final Function(Color) onThemeChanged;
  const NewsDashboard({super.key, required this.primaryColor, required this.onThemeChanged});
  @override
  State<NewsDashboard> createState() => _NewsDashboardState();
}

class _NewsDashboardState extends State<NewsDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Article> _allArticles = [], _displayList = [];
  Map<String, String> _viewedStoryMap = {}; // Link -> ISO Timestamp
  int _visibleCount = 12, _tabIndex = 0, _totalSources = 0, _completedSources = 0;
  bool _isLoading = true, _extendedMode = false, _hideTheory = true;
  String _activeFilter = "ALL", _statusMessage = "Ready";
  bool _allSourcesEnabled = true;
  Set<String> _enabledSources = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() { 
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 && _visibleCount < _displayList.length) {
        setState(() => _visibleCount += 12);
      }
    });
    _bootSequence();
  }

  Future<void> _bootSequence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _extendedMode = prefs.getBool('extended_coverage') ?? false;
      _hideTheory = prefs.getBool('hide_theory') ?? true;
      _allSourcesEnabled = prefs.getBool('all_sources_enabled') ?? true;
      
      final String? viewedJson = prefs.getString('viewed_stories_v1');
      if (viewedJson != null) {
        _viewedStoryMap = Map<String, String>.from(jsonDecode(viewedJson));
        _cleanupOldStories();
      }

      final List<String>? savedSources = prefs.getStringList('enabled_sources');
      if (savedSources != null) {
        _enabledSources = savedSources.toSet();
      } else {
        // Default to all core + global if no prefs saved
        _enabledSources = {
          ...AppConfig.coreSources.values,
          ...AppConfig.globalSources.values
        };
      }

      final String? cachedJson = prefs.getString('offline_cache');
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        setState(() { 
          _allArticles = decoded.map((m) => Article.fromMap(m)).toList(); 
          _isLoading = false; 
          _applyLogic(); 
        });
      }
    } catch (_) {}
    _fetchNews(isBackground: _allArticles.isNotEmpty);
  }

  void _cleanupOldStories() async {
    final now = DateTime.now();
    bool changed = false;
    _viewedStoryMap.removeWhere((link, timestamp) {
      final date = DateTime.tryParse(timestamp) ?? now;
      if (now.difference(date).inHours > 48) {
        changed = true;
        return true;
      }
      return false;
    });
    if (changed) _persistViewedStories();
  }

  void _markStoryViewed(String link) {
    if (!_viewedStoryMap.containsKey(link)) {
      setState(() => _viewedStoryMap[link] = DateTime.now().toIso8601String());
      _persistViewedStories();
    }
  }

  Future<void> _persistViewedStories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewed_stories_v1', jsonEncode(_viewedStoryMap));
  }

  Future<void> _fetchNews({bool isBackground = false}) async {
    if (!mounted) return;
    if (!isBackground) setState(() => _isLoading = true);

    // Determine current target sources
    final Map<String, String> sources = Map.from(AppConfig.coreSources)..addAll(AppConfig.globalSources);
    if (_extendedMode) sources.addAll(AppConfig.extendedSources);
    
    // Background fetch doesn't care about manual source toggles (it gets everything available)
    // but foreground fetch respects the 'Signal Sources' dialog
    if (!_allSourcesEnabled) {
      sources.removeWhere((url, name) => !_enabledSources.contains(name));
    }

    _totalSources = sources.length;
    _completedSources = 0;
    List<Article> freshBatch = [];

    for (var entry in sources.entries) {
      if (!mounted) break;
      if (!isBackground) setState(() => _statusMessage = "Receiving: ${entry.value}");
      try {
        final response = await http.get(Uri.parse(kIsWeb ? 'https://corsproxy.io/?${Uri.encodeComponent(entry.key)}' : entry.key)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          freshBatch.addAll(FeedParser.parse(utf8.decode(response.bodyBytes, allowMalformed: true), entry.value));
        }
      } catch (_) {} finally { 
        if (mounted) setState(() => _completedSources++); 
      }
    }
    if (mounted) _processFetchedArticles(freshBatch);
  }

  void _processFetchedArticles(List<Article> freshBatch) {
    setState(() {
      final Map<String, Article> deduplicated = {};
      for (var a in _allArticles) { deduplicated[a.link.toLowerCase()] = a; }
      for (var a in freshBatch) { deduplicated[a.link.toLowerCase()] = a; }
      _allArticles = deduplicated.values.toList()..sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
      _isLoading = false;
      _applyLogic();
    });
    _saveToCache();
  }

  /// THE FIX: Logic now filters the master list based on all active toggles
  void _applyLogic() {
    setState(() {
      Iterable<Article> filtered = _allArticles;

      // 1. Topic Filter (Sidebar)
      if (_activeFilter != "ALL") {
        filtered = filtered.where((a) => a.topics.contains(_activeFilter));
      }

      // 2. Theory Filter (Sidebar Toggle)
      if (_hideTheory) {
        filtered = filtered.where((a) => !a.topics.contains("THEORY/REVIEW"));
      }

      // 3. Extended Coverage Filter (The Fix)
      // If extended mode is OFF, hide anything that belongs specifically to the extended list
      if (!_extendedMode) {
        final Set<String> extendedNames = AppConfig.extendedSources.values.toSet();
        filtered = filtered.where((a) => !extendedNames.contains(a.source));
      }

      // 4. Manual Source Filter (Signal Sources Dialog)
      if (!_allSourcesEnabled) {
        filtered = filtered.where((a) => _enabledSources.contains(a.source));
      }

      _displayList = filtered.toList();
      _visibleCount = 12;
    });
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('offline_cache', jsonEncode(_allArticles.take(100).map((a) => a.toMap()).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: DashboardDrawer(
        primaryColor: widget.primaryColor, 
        onThemeChanged: widget.onThemeChanged,
        extendedMode: _extendedMode, 
        onExtendedModeChanged: (v) async { 
          final p = await SharedPreferences.getInstance(); 
          p.setBool('extended_coverage', v); 
          setState(() => _extendedMode = v); 
          // Re-apply logic immediately to hide/show extended articles already in cache
          _applyLogic();
          // Then fetch to ensure we have the latest if turning ON
          if (v) _fetchNews(); 
        },
        hideTheory: _hideTheory, 
        onHideTheoryChanged: (v) async { 
          final p = await SharedPreferences.getInstance(); 
          p.setBool('hide_theory', v); 
          setState(() => _hideTheory = v); 
          _applyLogic(); 
        },
        activeFilter: _activeFilter, 
        onFilterChanged: (n) { 
          setState(() => _activeFilter = n); 
          _applyLogic(); 
          Navigator.pop(context); 
        },
        onShowSources: () { 
          Navigator.pop(context); 
          DashboardDialogs.showSourcesDialog(
            context: context, 
            primaryColor: widget.primaryColor, 
            extendedMode: _extendedMode, 
            allSourcesEnabled: _allSourcesEnabled, 
            enabledSources: _enabledSources, 
            onSaved: (all, set) async { 
              setState(() { 
                _allSourcesEnabled = all; 
                _enabledSources = set; 
              }); 
              final p = await SharedPreferences.getInstance(); 
              p.setBool('all_sources_enabled', all); 
              p.setStringList('enabled_sources', set.toList()); 
              _applyLogic();
              _fetchNews(); 
            }
          ); 
        },
        onShowAbout: () { 
          Navigator.pop(context); 
          DashboardDialogs.showAboutDialog(context, widget.primaryColor); 
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, 
        onTap: (i) { 
          setState(() => _tabIndex = i); 
          if (i == 0) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
            }
          }
        }, 
        backgroundColor: AppColors.appBackground, 
        selectedItemColor: widget.primaryColor, 
        unselectedItemColor: Colors.white24, 
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house, size: 18), label: "Home"), 
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.play, size: 18), label: "Videos")
        ]
      ),
      body: Column(children: [
        DashboardHeader(
          width: MediaQuery.of(context).size.width, 
          primaryColor: widget.primaryColor, 
          searchController: _searchController, 
          onSearchChanged: (q) { 
            setState(() { 
              _displayList = _allArticles.where((a) => a.title.toLowerCase().contains(q.toLowerCase())).toList(); 
              _visibleCount = 12; 
            }); 
          }, 
          onLogoTap: () { 
            setState(() {
              _activeFilter = "ALL"; 
              _applyLogic();
            }); 
          }, 
          onOpenSettings: () => _scaffoldKey.currentState?.openEndDrawer()
        ),
        Expanded(child: DashboardContentView(
          tabIndex: _tabIndex, 
          isLoading: _isLoading, 
          width: MediaQuery.of(context).size.width, 
          primaryColor: widget.primaryColor, 
          displayList: _displayList, 
          allArticles: _displayList, // Changed to displayList to keep stories consistent with feed
          viewedStoryLinks: _viewedStoryMap.keys.toSet(),
          onStoryViewed: _markStoryViewed,
          visibleCount: _visibleCount, 
          scrollController: _scrollController, 
          totalSources: _totalSources, 
          completedSources: _completedSources, 
          statusMessage: _statusMessage, 
          onRefresh: () => _fetchNews()
        )),
      ]),
    );
  }
}
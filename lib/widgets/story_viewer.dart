import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../core/app_colors.dart';

/// ===========================================================================
/// STORY VIEWER
/// Full-screen Instagram-style story interface with 10s auto-progression.
/// ===========================================================================
class StoryViewer extends StatefulWidget {
  final List<Article> articles;
  final String sourceName;
  final Color primaryColor;

  const StoryViewer({
    super.key,
    required this.articles,
    required this.sourceName,
    required this.primaryColor,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(vsync: this);

    // FIX: Wait for the first frame to complete before starting the story timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStory();
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  void _startStory() {
    if (!mounted) return;
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 10);
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex + 1 < widget.articles.length) {
      setState(() {
        _currentIndex++;
      });
      _safeMovePage();
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _safeMovePage();
      _startStory();
    }
  }

  // FIX: Safety helper to prevent the "positions.isNotEmpty" error
  void _safeMovePage() {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.articles[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final double width = MediaQuery.of(context).size.width;
          final double dx = details.globalPosition.dx;
          if (dx < width / 3) {
            _prevStory();
          } else if (dx > 2 * width / 3) {
            _nextStory();
          } else {
            launchUrl(Uri.parse(article.link));
          }
        },
        child: Stack(
          children: [
            // Background Viewport
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.articles.length,
                itemBuilder: (context, index) {
                  final a = widget.articles[index];
                  return a.thumbnail.isNotEmpty
                      ? Image.network(a.thumbnail, fit: BoxFit.cover)
                      : Container(color: AppColors.appSurface);
                },
              ),
            ),
            // Gradient Darkening
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent, Colors.black],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // UI Overlay
            SafeArea(
              child: Column(
                children: [
                  // Progress Segments
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: widget.articles.asMap().entries.map((e) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _ProgressIndicator(
                              index: e.key,
                              currentIndex: _currentIndex,
                              animation: _animController,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: widget.primaryColor,
                          child: Text(widget.sourceName[0], 
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Text(widget.sourceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Article Content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),
                        Text(article.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.keyboard_arrow_up, color: widget.primaryColor),
                              const SizedBox(height: 8),
                              Text("TAP TO READ FULL ARTICLE", style: TextStyle(color: widget.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ],
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
}

class _ProgressIndicator extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Animation<double> animation;

  const _ProgressIndicator({required this.index, required this.currentIndex, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
      child: index < currentIndex
          ? Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)))
          : index == currentIndex
              ? AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animation.value,
                    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
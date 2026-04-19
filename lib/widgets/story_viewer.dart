import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../core/app_colors.dart';
import '../core/app_utils.dart';

class StoryViewer extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;
  final String sourceName;
  final Color primaryColor;
  final Function(String) onStoryViewed;

  const StoryViewer({
    super.key, required this.articles, required this.sourceName, 
    required this.primaryColor, required this.onStoryViewed, this.initialIndex = 0
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startStory());

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _nextStory();
    });
  }

  void _startStory() {
    if (!mounted) return;
    
    // Mark as viewed immediately upon slide entry
    widget.onStoryViewed(widget.articles[_currentIndex].link);

    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 10);
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex + 1 < widget.articles.length) {
      setState(() => _currentIndex++);
      _safeMovePage();
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _safeMovePage();
      _startStory();
    }
  }

  void _safeMovePage() {
    if (_pageController.hasClients) _pageController.jumpToPage(_currentIndex);
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
          if (details.globalPosition.dx < width / 3) _prevStory();
          else if (details.globalPosition.dx > 2 * width / 3) _nextStory();
          else launchUrl(Uri.parse(article.link));
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.articles.length,
                itemBuilder: (context, index) {
                  final a = widget.articles[index];
                  return a.thumbnail.isNotEmpty ? Image.network(a.thumbnail, fit: BoxFit.cover) : Container(color: AppColors.appSurface);
                },
              ),
            ),
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent, Colors.black], stops: [0.0, 0.4, 1.0])))),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: widget.articles.asMap().entries.map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _ProgressIndicator(index: e.key, currentIndex: _currentIndex, animation: _animController)))).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 16, backgroundColor: widget.primaryColor, child: Text(widget.sourceName[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(widget.sourceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(AppUtils.formatRelativeDate(article.parsedDate).toLowerCase(), style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                        ]),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(article.title, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 20),
                        Text(article.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 40),
                        Center(child: Column(children: [Icon(Icons.keyboard_arrow_up, color: widget.primaryColor), const SizedBox(height: 8), Text("TAP TO READ FULL ARTICLE", style: TextStyle(color: widget.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))])),
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
  final int index, currentIndex;
  final Animation<double> animation;
  const _ProgressIndicator({required this.index, required this.currentIndex, required this.animation});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
      child: index < currentIndex ? Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))) :
             index == currentIndex ? AnimatedBuilder(animation: animation, builder: (context, child) => FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: animation.value, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))))) : const SizedBox.shrink(),
    );
  }
}
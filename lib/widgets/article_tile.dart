import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../core/app_colors.dart';

class ArticleTile extends StatefulWidget {
  final Article article;
  final Color primaryColor;
  const ArticleTile({super.key, required this.article, required this.primaryColor});

  @override
  State<ArticleTile> createState() => _ArticleTileState();
}

class _ArticleTileState extends State<ArticleTile> {
  final PageController _tileController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _tileController.dispose();
    super.dispose();
  }

  Widget _miniArrow(IconData i, VoidCallback o) {
    return GestureDetector(
      onTap: o,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
        child: Icon(i, size: 10, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    String snippet = widget.article.description.trim();
    if (snippet.length > 85) snippet = snippet.substring(0, 85);
    if (snippet.endsWith('.')) {
      List<String> words = snippet.split(' ');
      if (words.length > 1) { words.removeLast(); snippet = words.join(' '); }
    }
    snippet = snippet.trimRight();

    String fullDesc = widget.article.description;
    if (fullDesc.length > 250) fullDesc = "${fullDesc.substring(0, 250)}...";

    return Container(
      width: 400, height: 580, color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  PageView(
                    controller: _tileController,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    children: [
                      // Slide 1
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(widget.article.link)),
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.tileBackground, border: Border.all(color: AppColors.appBackground), borderRadius: BorderRadius.circular(28)),
                          child: Stack(
                            children: [
                              if (widget.article.thumbnail.isNotEmpty) Positioned.fill(child: Image.network(widget.article.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(FontAwesomeIcons.satelliteDish, color: Colors.white10)))),
                              Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])))),
                              
                              Positioned(
                                top: 12, left: 12, 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widget.article.topics.map((t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: badge(t, Colors.white, Colors.black))).toList(),
                                ),
                              ),

                              // FIXED: Brand bar extending from right edge to start of name
                              Positioned(
                                top: 20, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
                                  decoration: BoxDecoration(
                                    color: widget.primaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    widget.article.source.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 9, 
                                      fontWeight: FontWeight.w900, 
                                      letterSpacing: 1.2
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(bottom: 24, left: 16, right: 16, child: Text(widget.article.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontStyle: FontStyle.italic))),
                              Positioned(bottom: 24, right: 16, child: Icon(FontAwesomeIcons.arrowUpRightFromSquare, color: Colors.white.withValues(alpha: 0.6), size: 14)),
                            ],
                          ),
                        ),
                      ),
                      // Slide 2
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Color.lerp(widget.article.dominantColor, Colors.black, 0.6)?.withValues(alpha: 0.95) ?? AppColors.tileBackground, 
                          borderRadius: BorderRadius.circular(28), 
                          border: Border.all(color: AppColors.appBackground),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(FontAwesomeIcons.circleInfo, color: Colors.white, size: 18),
                            const SizedBox(height: 16),
                            Text(widget.article.title.toUpperCase(), maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.5, height: 1.1)),
                            const SizedBox(height: 16),
                            Expanded(child: Text(fullDesc, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400))),
                            const SizedBox(height: 16),
                            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => launchUrl(Uri.parse(widget.article.link)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text("OPEN ARTICLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(bottom: 12, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(2, (index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Icon(FontAwesomeIcons.circle, size: 6, color: _currentIndex == index ? Colors.white : Colors.white24))))),
                  if (width > 500) ...[
                    if (_currentIndex == 1) Positioned(left: 10, top: 0, bottom: 0, child: Center(child: _miniArrow(FontAwesomeIcons.chevronLeft, () => _tileController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)))),
                    if (_currentIndex == 0) Positioned(right: 10, top: 0, bottom: 0, child: Center(child: _miniArrow(FontAwesomeIcons.chevronRight, () => _tileController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)))),
                  ]
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(widget.article.parsedDate).toUpperCase(), style: const TextStyle(fontSize: 8, color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                RichText(maxLines: 2, overflow: TextOverflow.ellipsis, text: TextSpan(style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white), children: [TextSpan(text: "${widget.article.source}  ", style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.w900, fontSize: 11)), TextSpan(text: snippet), const TextSpan(text: "... "), const TextSpan(text: "more", style: TextStyle(color: AppColors.textSubtle))])),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget badge(String t, Color bg, Color tc) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
  color: bg, 
  child: Text(t, style: TextStyle(color: tc, fontSize: 9, fontWeight: FontWeight.bold))
);
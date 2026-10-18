import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:awadalj/models/montage_preset.dart';
import 'package:awadalj/models/video_project.dart';

class VideoPreviewCanvas extends StatelessWidget {
  final VideoProject project;
  final double currentPosition;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const VideoPreviewCanvas({
    super.key,
    required this.project,
    required this.currentPosition,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  double _getAspectRatioValue(VideoAspectRatio ratio) {
    switch (ratio) {
      case VideoAspectRatio.vertical916:
        return 9 / 16;
      case VideoAspectRatio.horizontal169:
        return 16 / 9;
      case VideoAspectRatio.square11:
        return 1 / 1;
      case VideoAspectRatio.portrait45:
        return 4 / 5;
    }
  }

  ColorFilter _getFilterMatrix(ColorFilterType type) {
    switch (type) {
      case ColorFilterType.tealOrange:
        return const ColorFilter.matrix([
          1.25, 0.0, 0.0, 0.0, 18,
          0.0, 1.05, 0.0, 0.0, -5,
          0.0, 0.0, 1.35, 0.0, 25,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.warmGolden:
        return const ColorFilter.matrix([
          1.3, 0.0, 0.0, 0.0, 20,
          0.0, 1.15, 0.0, 0.0, 10,
          0.0, 0.0, 0.8, 0.0, -10,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.cyberpunk:
        return const ColorFilter.matrix([
          1.4, 0.0, 0.2, 0.0, 15,
          0.0, 0.9, 0.2, 0.0, -15,
          0.3, 0.0, 1.5, 0.0, 30,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.blackAndWhite:
        return const ColorFilter.matrix([
          0.33, 0.59, 0.11, 0, 0,
          0.33, 0.59, 0.11, 0, 0,
          0.33, 0.59, 0.11, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterType.vividSummer:
        return const ColorFilter.matrix([
          1.25, 0.0, 0.0, 0.0, 0,
          0.0, 1.25, 0.0, 0.0, 0,
          0.0, 0.0, 1.15, 0.0, 0,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.softPastel:
        return const ColorFilter.matrix([
          1.05, 0.05, 0.05, 0.0, 15,
          0.05, 1.05, 0.05, 0.0, 15,
          0.05, 0.05, 1.05, 0.0, 15,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.none:
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetAspect = _getAspectRatioValue(project.aspectRatio);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070B13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.5,
        ),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: targetAspect,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Rendered animated frame with filter
                ColorFiltered(
                  colorFilter: _getFilterMatrix(project.filter),
                  child: CustomPaint(
                    painter: _SimulatedVideoFramePainter(
                      time: currentPosition,
                      isPlaying: isPlaying,
                      presetId: project.presetId,
                    ),
                  ),
                ),

                // Top Vignette gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Watermark Badge
                if (project.watermarkText.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00C896).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF00C896),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.watermarkText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Aspect ratio / Speed indicator
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${project.playbackSpeed}x • ${_getAspectName(project.aspectRatio)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Live Dynamic Subtitles
                if (project.enableSubtitles)
                  Positioned(
                    bottom: 24,
                    left: 14,
                    right: 14,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _getSubtitlesForTime(currentPosition),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Play / Pause interactive center overlay
                GestureDetector(
                  onTap: onTogglePlay,
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isPlaying ? 0.0 : 0.9,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00C896),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C896).withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAspectName(VideoAspectRatio ratio) {
    switch (ratio) {
      case VideoAspectRatio.vertical916:
        return '9:16';
      case VideoAspectRatio.horizontal169:
        return '16:9';
      case VideoAspectRatio.square11:
        return '1:1';
      case VideoAspectRatio.portrait45:
        return '4:5';
    }
  }

  String _getSubtitlesForTime(double sec) {
    final mod = (sec % 12).toInt();
    if (mod < 3) {
      return '✨ مونتاج عوض الج الذكي بجودة 4K';
    } else if (mod < 6) {
      return '🎵 مزامنة النبضات مع المؤثرات الصوتية';
    } else if (mod < 9) {
      return '🎨 تدريج لوني احترافي وتثبيت المشهد';
    } else {
      return '💾 جاهز للتصدير المباشر لمعرض الهاتف';
    }
  }
}

class _SimulatedVideoFramePainter extends CustomPainter {
  final double time;
  final bool isPlaying;
  final String presetId;

  _SimulatedVideoFramePainter({
    required this.time,
    required this.isPlaying,
    required this.presetId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shift = (math.sin(time * 0.7) + 1.0) / 2.0;

    // Cinematic dynamic color blend
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF0F2027), const Color(0xFF203A43), shift)!,
        Color.lerp(const Color(0xFF2C5364), const Color(0xFF0A192F), 1.0 - shift)!,
        const Color(0xFF090D16),
      ],
    );

    final bgPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Audio frequency / motion waves simulation
    final wavePaint = Paint()
      ..color = const Color(0xFF00C896).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    const waveCount = 4;
    for (int i = 0; i < waveCount; i++) {
      final yOffset = size.height * (0.3 + (i * 0.14));
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 12) {
        final y = yOffset +
            math.sin((x * 0.025) + (time * 2.5) + (i * 0.9)) * 12.0;
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    // Dynamic focal aura
    final orbX = size.width * (0.35 + 0.3 * (math.sin(time * 0.8) + 1) / 2);
    final orbY = size.height * (0.4 + 0.2 * (math.cos(time * 0.9) + 1) / 2);
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
          const Color(0xFF00C896).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: 85));

    canvas.drawCircle(Offset(orbX, orbY), 85, orbPaint);

    // Cinematic crosshair in center
    final centerCrosshair = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    final cX = size.width / 2;
    final cY = size.height / 2;
    canvas.drawLine(Offset(cX - 12, cY), Offset(cX + 12, cY), centerCrosshair);
    canvas.drawLine(Offset(cX, cY - 12), Offset(cX, cY + 12), centerCrosshair);
  }

  @override
  bool shouldRepaint(covariant _SimulatedVideoFramePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.presetId != presetId;
  }
}

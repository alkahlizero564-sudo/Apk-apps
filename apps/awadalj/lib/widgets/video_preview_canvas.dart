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
          1.2, 0.0, 0.0, 0.0, 15,
          0.0, 1.0, 0.0, 0.0, 0,
          0.0, 0.0, 1.3, 0.0, 25,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.warmGolden:
        return const ColorFilter.matrix([
          1.3, 0.0, 0.0, 0.0, 20,
          0.0, 1.15, 0.0, 0.0, 10,
          0.0, 0.0, 0.8, 0.0, 0,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case ColorFilterType.cyberpunk:
        return const ColorFilter.matrix([
          1.4, 0.0, 0.2, 0.0, 10,
          0.0, 0.9, 0.2, 0.0, -10,
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

    return Center(
      child: AspectRatio(
        aspectRatio: targetAspect,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Simulated dynamic video canvas with filter applied
              ColorFiltered(
                colorFilter: _getFilterMatrix(project.filter),
                child: CustomPaint(
                  painter: _SimulatedVideoFramePainter(
                    time: currentPosition,
                    isPlaying: isPlaying,
                  ),
                ),
              ),

              // Watermark Overlay
              if (project.watermarkText.isNotEmpty)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF00C896),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.watermarkText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Real-time Subtitles Simulated Overlay
              if (project.enableSubtitles)
                Positioned(
                  bottom: 30,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getSubtitlesForTime(currentPosition),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Play / Pause Tap Overlay
              GestureDetector(
                onTap: onTogglePlay,
                behavior: HitTestBehavior.translucent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 0.0 : 0.85,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                ),
              ),

              // Active Preset Badge
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${project.playbackSpeed}x | ${project.aspectRatio.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitlesForTime(double sec) {
    final mod = (sec % 12).toInt();
    if (mod < 3) {
      return '✨ مونتاج ذكي وسريع بجودة فائقة';
    } else if (mod < 6) {
      return '🎵 مزامنة الإيقاع مع الموسيقى التصويرية';
    } else if (mod < 9) {
      return '🎨 تدريج لوني احترافي وتأثيرات بصرية';
    } else {
      return '💾 جاهز للحفظ المباشر في المعرض';
    }
  }
}

class _SimulatedVideoFramePainter extends CustomPainter {
  final double time;
  final bool isPlaying;

  _SimulatedVideoFramePainter({required this.time, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Background gradient changing softly with playback
    final shift = (math.sin(time * 0.5) + 1.0) / 2.0;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF1E3A8A), const Color(0xFF0F172A), shift)!,
        Color.lerp(const Color(0xFF065F46), const Color(0xFF1E1B4B), 1.0 - shift)!,
        const Color(0xFF111827),
      ],
    );

    final bgPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Decorative cinematic grid / motion waves
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final waveCount = 5;
    for (int i = 0; i < waveCount; i++) {
      final yOffset = size.height * (0.2 + (i * 0.15));
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 15) {
        final y = yOffset +
            math.sin((x * 0.02) + (time * 2.0) + (i * 0.8)) * 14.0;
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    // Glowing motion orb (representing video focal subject)
    final orbX = size.width * (0.3 + 0.4 * (math.sin(time * 0.8) + 1) / 2);
    final orbY = size.height * (0.4 + 0.2 * (math.cos(time * 0.9) + 1) / 2);
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.4),
          const Color(0xFF00C896).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: 90));

    canvas.drawCircle(Offset(orbX, orbY), 90, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _SimulatedVideoFramePainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.isPlaying != isPlaying;
  }
}

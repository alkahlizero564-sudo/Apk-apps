import 'package:flutter/material.dart';

class TimelineTrimmer extends StatelessWidget {
  final double totalDuration;
  final double trimStart;
  final double trimEnd;
  final double currentPosition;
  final Function(double, double) onTrimChanged;
  final Function(double) onSeek;

  const TimelineTrimmer({
    super.key,
    required this.totalDuration,
    required this.trimStart,
    required this.trimEnd,
    required this.currentPosition,
    required this.onTrimChanged,
    required this.onSeek,
  });

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    final tenths = ((seconds - seconds.toInt()) * 10).toInt();
    return '$mins:$secs.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveLength = (trimEnd - trimStart).clamp(0.0, totalDuration);
    final validTotal = totalDuration > 0 ? totalDuration : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      size: 16,
                      color: Color(0xFF00C896),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'مسار الفيديو والقص',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C896).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'المحدد: ${_formatTime(effectiveLength)}',
                  style: const TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Filmstrip & Timeline Scrubber
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 52,
              color: Colors.black,
              child: Stack(
                children: [
                  // Thumbnails simulation
                  Row(
                    children: List.generate(
                      12,
                      (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.8),
                          decoration: BoxDecoration(
                            color: (i % 2 == 0)
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF0F172A),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.movie_creation_outlined,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Active Selected Range Box
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final startRatio = (trimStart / validTotal).clamp(0.0, 1.0);
                      final endRatio = (trimEnd / validTotal).clamp(0.0, 1.0);
                      final currentRatio =
                          (currentPosition / validTotal).clamp(0.0, 1.0);

                      final leftPos = startRatio * width;
                      final boxWidth = ((endRatio - startRatio) * width)
                          .clamp(4.0, width);

                      return Stack(
                        children: [
                          // Dimmed outside left
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: leftPos,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                          // Dimmed outside right
                          Positioned(
                            left: endRatio * width,
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                          // Selected Region Frame
                          Positioned(
                            left: leftPos,
                            width: boxWidth,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF00C896),
                                  width: 2.5,
                                ),
                                color: const Color(0xFF00C896)
                                    .withValues(alpha: 0.15),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.drag_indicator_rounded,
                                      size: 12, color: Colors.white),
                                  Icon(Icons.drag_indicator_rounded,
                                      size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          // Playhead cursor line
                          Positioned(
                            left: (currentRatio * width) - 1.5,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.amberAccent,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Trim Dual Slider
          RangeSlider(
            values: RangeValues(
              trimStart.clamp(0.0, validTotal),
              trimEnd.clamp(0.0, validTotal),
            ),
            min: 0.0,
            max: validTotal,
            activeColor: const Color(0xFF00C896),
            inactiveColor: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            onChanged: (RangeValues values) {
              if (values.end - values.start >= 0.5) {
                onTrimChanged(values.start, values.end);
              }
            },
          ),

          // Scrubber Playhead
          Slider(
            value: currentPosition.clamp(trimStart, trimEnd),
            min: trimStart,
            max: trimEnd > trimStart ? trimEnd : trimStart + 0.1,
            activeColor: Colors.amberAccent,
            inactiveColor: isDark ? Colors.white12 : Colors.black12,
            onChanged: onSeek,
          ),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'البداية: ${_formatTime(trimStart)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'الموقع: ${_formatTime(currentPosition)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
              Text(
                'النهاية: ${_formatTime(trimEnd)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

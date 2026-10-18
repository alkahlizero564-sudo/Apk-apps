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
    final millis = ((seconds - seconds.toInt()) * 10).toInt();
    return '$mins:$secs.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.content_cut_rounded,
                      size: 18, color: Color(0xFF00C896)),
                  const SizedBox(width: 6),
                  Text(
                    'قص وتشذيب المسار الزمني',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'المحدد: ${_formatTime(trimEnd - trimStart)}',
                  style: const TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Timeline Thumbnail Strip Simulation
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Row(
                    children: List.generate(
                      10,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: (index % 2 == 0)
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.6)
                              : const Color(0xFF0F766E).withValues(alpha: 0.6),
                          child: Center(
                            child: Icon(
                              Icons.movie_creation_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Active Selected Range Overlay
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final startRatio =
                          (trimStart / (totalDuration == 0 ? 1 : totalDuration))
                              .clamp(0.0, 1.0);
                      final endRatio =
                          (trimEnd / (totalDuration == 0 ? 1 : totalDuration))
                              .clamp(0.0, 1.0);
                      final currentRatio = (currentPosition /
                              (totalDuration == 0 ? 1 : totalDuration))
                          .clamp(0.0, 1.0);

                      return Stack(
                        children: [
                          // Highlight box
                          Positioned(
                            left: startRatio * width,
                            width: (endRatio - startRatio) * width,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF00C896),
                                  width: 2.5,
                                ),
                                color: const Color(0xFF00C896)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          // Scrubber playhead line
                          Positioned(
                            left: (currentRatio * width) - 1.5,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 3,
                              color: Colors.amberAccent,
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

          const SizedBox(height: 10),

          // Dual Range Slider for trimming
          RangeSlider(
            values: RangeValues(
              trimStart.clamp(0.0, totalDuration),
              trimEnd.clamp(0.0, totalDuration),
            ),
            min: 0.0,
            max: totalDuration > 0 ? totalDuration : 1.0,
            activeColor: const Color(0xFF00C896),
            inactiveColor: isDark ? Colors.white24 : Colors.black12,
            onChanged: (RangeValues values) {
              if (values.end - values.start >= 1.0) {
                onTrimChanged(values.start, values.end);
              }
            },
          ),

          // Playhead Scrubbing Slider
          Slider(
            value: currentPosition.clamp(trimStart, trimEnd),
            min: trimStart,
            max: trimEnd > trimStart ? trimEnd : trimStart + 0.1,
            activeColor: Colors.amberAccent,
            inactiveColor: Colors.transparent,
            onChanged: (val) => onSeek(val),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'البداية: ${_formatTime(trimStart)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                'الموقع الحالي: ${_formatTime(currentPosition)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
              Text(
                'النهاية: ${_formatTime(trimEnd)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

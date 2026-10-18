import 'package:flutter/material.dart';
import 'package:awadalj/models/montage_preset.dart';

class PresetSelector extends StatelessWidget {
  final String activePresetId;
  final Function(MontagePreset) onSelectPreset;

  const PresetSelector({
    super.key,
    required this.activePresetId,
    required this.onSelectPreset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF00C896), size: 18),
              const SizedBox(width: 8),
              Text(
                'قوالب المونتاج الذكية (Smart Presets)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: MontagePreset.presets.length,
            itemBuilder: (context, index) {
              final preset = MontagePreset.presets[index];
              final isSelected = preset.id == activePresetId;

              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: InkWell(
                  onTap: () => onSelectPreset(preset),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C896).withValues(alpha: 0.18)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C896)
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              preset.icon,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF00C896)
                                  : (isDark ? Colors.white70 : Colors.blueGrey),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFF00C896),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.titleAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF00C896)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.defaultMusicTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

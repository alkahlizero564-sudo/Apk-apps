import 'package:flutter/material.dart';
import 'package:awadalj/models/video_project.dart';

class AudioSettingsSheet extends StatefulWidget {
  final VideoProject project;
  final Function({
    double? originalVol,
    double? bgMusicVol,
    String? musicTitle,
    bool? denoise,
  }) onAudioChanged;

  const AudioSettingsSheet({
    super.key,
    required this.project,
    required this.onAudioChanged,
  });

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  late double _origVolume;
  late double _bgVolume;
  late String _musicTitle;
  late bool _denoise;

  final List<String> _musicLibrary = [
    'سيمفونية الأفق الهادئ',
    'إيقاع إلكتروني سريع',
    'عزف بيانو هادئ',
    'طبول ملحمية حماسية',
    'ألحان لو فاي خافتة',
    'بدون موسيقى خلفية (صوت أصلي فقط)',
  ];

  @override
  void initState() {
    super.initState();
    _origVolume = widget.project.originalAudioVolume;
    _bgVolume = widget.project.backgroundMusicVolume;
    _musicTitle = widget.project.selectedMusic;
    _denoise = widget.project.enableAudioDenoise;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Color(0xFF00C896),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'هندسة الصوت وموسيقى المونتاج',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Denoise AI Switch
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: SwitchListTile(
                        value: _denoise,
                        activeColor: const Color(0xFF00C896),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'عزل التشويش والرياح بالذكاء الاصطناعي',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        subtitle: const Text(
                          'تنقية صوت المتحدث وتخفيض الضوضاء الخلفية',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        onChanged: (val) {
                          setState(() => _denoise = val);
                          widget.onAudioChanged(denoise: val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sliders
                    Text(
                      'مستوى الصوت الأصلي للفيديو: ${(_origVolume * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Slider(
                      value: _origVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF00C896),
                      onChanged: (val) {
                        setState(() => _origVolume = val);
                        widget.onAudioChanged(originalVol: val);
                      },
                    ),

                    Text(
                      'مستوى الموسيقى التصويرية: ${(_bgVolume * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Slider(
                      value: _bgVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) {
                        setState(() => _bgVolume = val);
                        widget.onAudioChanged(bgMusicVol: val);
                      },
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'اختر المسار الموسيقي:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Music list
                    ..._musicLibrary.map((track) {
                      final isSelected = _musicTitle == track;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00C896).withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00C896)
                                : Colors.transparent,
                          ),
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            track,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: track,
                          groupValue: _musicTitle,
                          activeColor: const Color(0xFF00C896),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          dense: true,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _musicTitle = val);
                              widget.onAudioChanged(musicTitle: val);
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

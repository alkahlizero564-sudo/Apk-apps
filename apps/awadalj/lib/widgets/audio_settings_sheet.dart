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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.graphic_eq_rounded,
                      color: Color(0xFF00C896), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'هندسة الصوت وموسيقى المونتاج',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Denoise AI switch
              SwitchListTile(
                value: _denoise,
                activeColor: const Color(0xFF00C896),
                contentPadding: EdgeInsets.zero,
                title: const Text('عزل التشويش والرياح بالذكاء الاصطناعي'),
                subtitle: const Text('تنقية صوت المتحدث وتخفيض الضجيج المحيط'),
                onChanged: (val) {
                  setState(() => _denoise = val);
                  widget.onAudioChanged(denoise: val);
                },
              ),
              const Divider(),

              // Original volume
              Text('مستوى الصوت الأصلي (${(_origVolume * 100).toInt()}%)',
                  style: theme.textTheme.bodyMedium),
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

              // Background music volume
              Text('مستوى الموسيقى التصويرية (${(_bgVolume * 100).toInt()}%)',
                  style: theme.textTheme.bodyMedium),
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
              const SizedBox(height: 10),

              // Music Tracks
              Text(
                'اختر المسار الموسيقي:',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._musicLibrary.map((track) {
                final isSelected = _musicTitle == track;
                return RadioListTile<String>(
                  title: Text(track),
                  value: track,
                  groupValue: _musicTitle,
                  activeColor: const Color(0xFF00C896),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _musicTitle = val);
                      widget.onAudioChanged(musicTitle: val);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

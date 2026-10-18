import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awadalj/models/montage_preset.dart';
import 'package:awadalj/state/montage_provider.dart';
import 'package:awadalj/widgets/video_preview_canvas.dart';
import 'package:awadalj/widgets/timeline_trimmer.dart';
import 'package:awadalj/widgets/preset_selector.dart';
import 'package:awadalj/widgets/audio_settings_sheet.dart';
import 'package:awadalj/widgets/export_dialog.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  void _showWatermarkDialog(BuildContext context, MontageProvider provider) {
    final controller = TextEditingController(
      text: provider.activeProject?.watermarkText ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('العلامة المائية / اسم صانع المحتوى'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'اكتب اسمك أو علامتك المائية',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateWatermark(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _triggerExport(BuildContext context, MontageProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Consumer<MontageProvider>(
        builder: (context, prov, _) {
          return ExportDialog(
            progress: prov.exportProgress,
            statusText: prov.exportStageText,
            isCompleted: !prov.isExporting && prov.exportProgress >= 1.0,
            onDone: () => Navigator.of(context).pop(),
          );
        },
      ),
    );

    final success = await provider.exportAndSaveToGallery();
    if (!success && context.mounted) {
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MontageProvider>();
    final project = provider.activeProject;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('استوديو المونتاج')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('لم يتم اختيار أي فيديو للعمل عليه'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'العلامة المائية',
            icon: const Icon(Icons.branding_watermark_rounded),
            onPressed: () => _showWatermarkDialog(context, provider),
          ),
          IconButton(
            tooltip: 'الصوت والموسيقى',
            icon: const Icon(Icons.music_note_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AudioSettingsSheet(
                  project: project,
                  onAudioChanged: provider.updateAudioMix,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _triggerExport(context, provider),
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              label: const Text(
                'حفظ بالمعرض',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Canvas Container
            Container(
              height: 320,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VideoPreviewCanvas(
                project: project,
                currentPosition: provider.currentPlaybackPosition,
                isPlaying: provider.isPlaying,
                onTogglePlay: provider.togglePlayPause,
              ),
            ),
            const SizedBox(height: 12),

            // Aspect Ratio Selector Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AspectRatioBtn(
                    label: '9:16 تيك توك/ريلز',
                    ratio: VideoAspectRatio.vertical916,
                    isSelected:
                        project.aspectRatio == VideoAspectRatio.vertical916,
                    onTap: () =>
                        provider.updateAspectRatio(VideoAspectRatio.vertical916),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioBtn(
                    label: '16:9 يوتيوب',
                    ratio: VideoAspectRatio.horizontal169,
                    isSelected:
                        project.aspectRatio == VideoAspectRatio.horizontal169,
                    onTap: () =>
                        provider.updateAspectRatio(VideoAspectRatio.horizontal169),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioBtn(
                    label: '1:1 مربع',
                    ratio: VideoAspectRatio.square11,
                    isSelected: project.aspectRatio == VideoAspectRatio.square11,
                    onTap: () =>
                        provider.updateAspectRatio(VideoAspectRatio.square11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Timeline Trimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TimelineTrimmer(
                totalDuration: project.durationSeconds,
                trimStart: project.trimStart,
                trimEnd: project.trimEnd,
                currentPosition: provider.currentPlaybackPosition,
                onTrimChanged: provider.updateTrimRange,
                onSeek: provider.seekTo,
              ),
            ),
            const SizedBox(height: 16),

            // Smart Presets
            PresetSelector(
              activePresetId: project.presetId,
              onSelectPreset: provider.applyPreset,
            ),
            const SizedBox(height: 14),

            // Quick Color Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'فلاتر التلوين السينمائية:',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _FilterChip(
                    name: 'بدون فلتر',
                    type: ColorFilterType.none,
                    isSelected: project.filter == ColorFilterType.none,
                    onTap: () => provider.updateFilter(ColorFilterType.none),
                  ),
                  _FilterChip(
                    name: 'تيل & أورانج',
                    type: ColorFilterType.tealOrange,
                    isSelected: project.filter == ColorFilterType.tealOrange,
                    onTap: () =>
                        provider.updateFilter(ColorFilterType.tealOrange),
                  ),
                  _FilterChip(
                    name: 'ذهبي دافئ',
                    type: ColorFilterType.warmGolden,
                    isSelected: project.filter == ColorFilterType.warmGolden,
                    onTap: () =>
                        provider.updateFilter(ColorFilterType.warmGolden),
                  ),
                  _FilterChip(
                    name: 'سايبر بانك',
                    type: ColorFilterType.cyberpunk,
                    isSelected: project.filter == ColorFilterType.cyberpunk,
                    onTap: () =>
                        provider.updateFilter(ColorFilterType.cyberpunk),
                  ),
                  _FilterChip(
                    name: 'أبيض وأسود فخم',
                    type: ColorFilterType.blackAndWhite,
                    isSelected: project.filter == ColorFilterType.blackAndWhite,
                    onTap: () =>
                        provider.updateFilter(ColorFilterType.blackAndWhite),
                  ),
                  _FilterChip(
                    name: 'صيفي مشرق',
                    type: ColorFilterType.vividSummer,
                    isSelected: project.filter == ColorFilterType.vividSummer,
                    onTap: () =>
                        provider.updateFilter(ColorFilterType.vividSummer),
                  ),
                  _FilterChip(
                    name: 'باستيل هادئ',
                    type: ColorFilterType.softPastel,
                    isSelected: project.filter == ColorFilterType.softPastel,
                    onTap: () =>
                        provider.updateFilter(ColorFilterType.softPastel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Speed & Subtitles Toggles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.speed_rounded,
                                color: Color(0xFF00C896), size: 20),
                            SizedBox(width: 8),
                            Text('سرعة العرض:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        DropdownButton<double>(
                          value: project.playbackSpeed,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 0.5, child: Text('0.5x بطيء')),
                            DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                            DropdownMenuItem(value: 1.0, child: Text('1.0x عادي')),
                            DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                            DropdownMenuItem(value: 1.5, child: Text('1.5x سريع')),
                            DropdownMenuItem(value: 2.0, child: Text('2.0x فائق')),
                          ],
                          onChanged: (speed) {
                            if (speed != null) {
                              provider.updatePlaybackSpeed(speed);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تفعيل النصوص التوضيحية (Auto Captions)'),
                      value: project.enableSubtitles,
                      activeColor: const Color(0xFF00C896),
                      onChanged: provider.toggleSubtitles,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _AspectRatioBtn extends StatelessWidget {
  final String label;
  final VideoAspectRatio ratio;
  final bool isSelected;
  final VoidCallback onTap;

  const _AspectRatioBtn({
    required this.label,
    required this.ratio,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C896)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String name;
  final ColorFilterType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.name,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: const Color(0xFF00C896).withValues(alpha: 0.25),
        checkmarkColor: const Color(0xFF00C896),
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? const Color(0xFF00C896) : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

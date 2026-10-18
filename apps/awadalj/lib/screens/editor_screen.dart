import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awadalj/models/montage_preset.dart';
import 'package:awadalj/state/montage_provider.dart';
import 'package:awadalj/widgets/video_preview_canvas.dart';
import 'package:awadalj/widgets/timeline_trimmer.dart';
import 'package:awadalj/widgets/preset_selector.dart';
import 'package:awadalj/widgets/audio_settings_sheet.dart';
import 'package:awadalj/widgets/export_dialog.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  int _currentToolIndex = 0; // 0: قص وقوالب, 1: تلوين وفلاتر, 2: أبعاد وسرعة

  void _showWatermarkDialog(BuildContext context, MontageProvider provider) {
    final controller = TextEditingController(
      text: provider.activeProject?.watermarkText ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.branding_watermark_rounded,
                color: Color(0xFF00C896), size: 22),
            SizedBox(width: 8),
            Text('العلامة المائية', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'اكتب اسمك أو علامتك المائية',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
              foregroundColor: Colors.white,
            ),
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
              const Icon(Icons.movie_creation_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('لم يتم اختيار أي فيديو للعمل عليه'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'العلامة المائية',
            icon: const Icon(Icons.branding_watermark_rounded, size: 21),
            onPressed: () => _showWatermarkDialog(context, provider),
          ),
          IconButton(
            tooltip: 'الصوت والموسيقى',
            icon: const Icon(Icons.music_note_rounded, size: 22),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => FractionallySizedBox(
                  heightFactor: 0.75,
                  child: AudioSettingsSheet(
                    project: project,
                    onAudioChanged: provider.updateAudioMix,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: const Color(0xFF0B0F19),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
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
      body: SafeArea(
        child: Column(
          children: [
            // Preview Canvas Viewport
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: VideoPreviewCanvas(
                  project: project,
                  currentPosition: provider.currentPlaybackPosition,
                  isPlaying: provider.isPlaying,
                  onTogglePlay: provider.togglePlayPause,
                ),
              ),
            ),

            // Tool Switcher Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF151D2F)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: 'القص والقوالب',
                    icon: Icons.movie_filter_rounded,
                    isSelected: _currentToolIndex == 0,
                    onTap: () => setState(() => _currentToolIndex = 0),
                  ),
                  _TabButton(
                    label: 'الفلاتر والألوان',
                    icon: Icons.color_lens_rounded,
                    isSelected: _currentToolIndex == 1,
                    onTap: () => setState(() => _currentToolIndex = 1),
                  ),
                  _TabButton(
                    label: 'الأبعاد والسرعة',
                    icon: Icons.aspect_ratio_rounded,
                    isSelected: _currentToolIndex == 2,
                    onTap: () => setState(() => _currentToolIndex = 2),
                  ),
                ],
              ),
            ),

            // Active Tool Content Area
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolPanel(context, provider, project, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolPanel(
    BuildContext context,
    MontageProvider provider,
    dynamic project,
    bool isDark,
  ) {
    switch (_currentToolIndex) {
      case 0:
        return Column(
          key: const ValueKey(0),
          children: [
            TimelineTrimmer(
              totalDuration: project.durationSeconds,
              trimStart: project.trimStart,
              trimEnd: project.trimEnd,
              currentPosition: provider.currentPlaybackPosition,
              onTrimChanged: provider.updateTrimRange,
              onSeek: provider.seekTo,
            ),
            const SizedBox(height: 12),
            PresetSelector(
              activePresetId: project.presetId,
              onSelectPreset: provider.applyPreset,
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D2F) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded,
                          color: Color(0xFF00C896), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'التدرج اللوني السينمائي (LUTs):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterBadge(
                        name: 'طبيعي (بدون فلتر)',
                        type: ColorFilterType.none,
                        isSelected: project.filter == ColorFilterType.none,
                        onTap: () => provider.updateFilter(ColorFilterType.none),
                      ),
                      _FilterBadge(
                        name: 'تيل & أورانج السينمائي',
                        type: ColorFilterType.tealOrange,
                        isSelected:
                            project.filter == ColorFilterType.tealOrange,
                        onTap: () =>
                            provider.updateFilter(ColorFilterType.tealOrange),
                      ),
                      _FilterBadge(
                        name: 'ذهبي دافئ (Sunset)',
                        type: ColorFilterType.warmGolden,
                        isSelected:
                            project.filter == ColorFilterType.warmGolden,
                        onTap: () =>
                            provider.updateFilter(ColorFilterType.warmGolden),
                      ),
                      _FilterBadge(
                        name: 'سايبر بانك (نيون)',
                        type: ColorFilterType.cyberpunk,
                        isSelected: project.filter == ColorFilterType.cyberpunk,
                        onTap: () =>
                            provider.updateFilter(ColorFilterType.cyberpunk),
                      ),
                      _FilterBadge(
                        name: 'أبيض وأسود كلاسيك',
                        type: ColorFilterType.blackAndWhite,
                        isSelected:
                            project.filter == ColorFilterType.blackAndWhite,
                        onTap: () =>
                            provider.updateFilter(ColorFilterType.blackAndWhite),
                      ),
                      _FilterBadge(
                        name: 'صيفي مشرق (Vivid)',
                        type: ColorFilterType.vividSummer,
                        isSelected:
                            project.filter == ColorFilterType.vividSummer,
                        onTap: () =>
                            provider.updateFilter(ColorFilterType.vividSummer),
                      ),
                      _FilterBadge(
                        name: 'باستيل ناعم',
                        type: ColorFilterType.softPastel,
                        isSelected:
                            project.filter == ColorFilterType.softPastel,
                        onTap: () =>
                            provider.updateFilter(ColorFilterType.softPastel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Aspect ratio section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D2F) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أبعاد الفيديو والمنصة المستهدفة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AspectCard(
                          icon: Icons.smartphone_rounded,
                          title: '9:16',
                          subtitle: 'ريلز وتيك توك',
                          isSelected: project.aspectRatio ==
                              VideoAspectRatio.vertical916,
                          onTap: () => provider.updateAspectRatio(
                              VideoAspectRatio.vertical916),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AspectCard(
                          icon: Icons.tv_rounded,
                          title: '16:9',
                          subtitle: 'يوتيوب والشاشات',
                          isSelected: project.aspectRatio ==
                              VideoAspectRatio.horizontal169,
                          onTap: () => provider.updateAspectRatio(
                              VideoAspectRatio.horizontal169),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AspectCard(
                          icon: Icons.crop_square_rounded,
                          title: '1:1',
                          subtitle: 'انستقرام مربع',
                          isSelected: project.aspectRatio ==
                              VideoAspectRatio.square11,
                          onTap: () => provider.updateAspectRatio(
                              VideoAspectRatio.square11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Speed ramp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.speed_rounded,
                              color: Color(0xFF00C896), size: 20),
                          SizedBox(width: 8),
                          Text('سرعة العرض (Speed Ramp):',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      DropdownButton<double>(
                        value: project.playbackSpeed,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text('0.5x بطيء')),
                          DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                          DropdownMenuItem(value: 0.95, child: Text('0.95x سينمائي')),
                          DropdownMenuItem(value: 1.0, child: Text('1.0x عادي')),
                          DropdownMenuItem(value: 1.15, child: Text('1.15x ريلز')),
                          DropdownMenuItem(value: 1.25, child: Text('1.25x أكشن')),
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
                    title: const Text(
                      'توليد التسميات التوضيحية (Auto Captions)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'عرض نصوص ذكية متزامنة أسفل الفيديو',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: project.enableSubtitles,
                    activeColor: const Color(0xFF00C896),
                    onChanged: provider.toggleSubtitles,
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00C896) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF0B0F19) : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF0B0F19)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AspectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AspectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C896).withValues(alpha: 0.16)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C896)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF00C896) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? const Color(0xFF00C896) : null,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String name;
  final ColorFilterType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterBadge({
    required this.name,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C896)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C896)
                : Colors.transparent,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0B0F19) : null,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

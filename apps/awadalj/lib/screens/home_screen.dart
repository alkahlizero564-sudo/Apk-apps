import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awadalj/state/montage_provider.dart';
import 'package:awadalj/screens/editor_screen.dart';
import 'package:awadalj/screens/saved_projects_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _pickAndStart(BuildContext context) async {
    final provider = context.read<MontageProvider>();
    final success = await provider.pickVideoFromDevice();
    if (success && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    }
  }

  void _openSample(BuildContext context) {
    final provider = context.read<MontageProvider>();
    provider.loadSampleVideo();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<MontageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C896), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.movie_creation_rounded,
                color: Color(0xFF0B0F19),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'عوض الج | Awadalj',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'المشاريع المحفوظة',
            icon: Stack(
              children: [
                const Icon(Icons.folder_special_rounded, size: 24),
                if (provider.savedProjects.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C896),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedProjectsScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00C896)),
                  SizedBox(height: 18),
                  Text(
                    'جارٍ استيراد وتحليل الفيديو...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Studio Banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF151D2F),
                                const Color(0xFF0B0F19),
                              ]
                            : [
                                const Color(0xFF00897B),
                                const Color(0xFF005b52),
                              ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFF00A896),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C896).withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.amberAccent, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'مونتاج ذكي متطور',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'اصنع فيديوهات سينمائية واحترافية بسهولة فائقة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أرفق الفيديو من جهازك، وسيقوم محرك عوض الج بالقص الذكي، ومزامنة الموسيقى، وتطبيق درجات الألوان مع الحفظ المباشر في المعرض.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C896),
                                  foregroundColor: const Color(0xFF0B0F19),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: () => _pickAndStart(context),
                                icon: const Icon(Icons.video_call_rounded,
                                    size: 22),
                                label: const Text(
                                  'إرفاق فيديو جديد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick test sample action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF00C896)
                            : const Color(0xFF00897B),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openSample(context),
                    icon: Icon(
                      Icons.play_circle_outline_rounded,
                      color: isDark
                          ? const Color(0xFF00C896)
                          : const Color(0xFF00897B),
                    ),
                    label: Text(
                      'تجربة عينة فيديو فورية (بدون رفع)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF00C896)
                            : const Color(0xFF00897B),
                      ),
                    ),
                  ),

                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Saved Projects Quick Bar
                  if (provider.savedProjects.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المشاريع الأخيرة بالمعرض',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedProjectsScreen(),
                              ),
                            );
                          },
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 94,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.savedProjects.length > 5
                            ? 5
                            : provider.savedProjects.length,
                        itemBuilder: (context, idx) {
                          final p = provider.savedProjects[idx];
                          return Container(
                            width: 170,
                            margin: const EdgeInsets.only(left: 10),
                            child: InkWell(
                              onTap: () {
                                provider.openExistingProject(p);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditorScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF151D2F)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.movie_filter_rounded,
                                          size: 16,
                                          color: Color(0xFF00C896),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${p.effectiveDuration.toStringAsFixed(1)} ثانية',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
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

                  const SizedBox(height: 28),

                  // Feature cards
                  Text(
                    'أدوات المونتاج المتوفرة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _FeatureItem(
                    icon: Icons.movie_filter_rounded,
                    title: 'تدرج لوني سينمائي (Color Grading)',
                    subtitle:
                        'فلاتر Teal & Orange، والذهبي الدافئ، وألوان السايبربانك والباستيل.',
                  ),
                  _FeatureItem(
                    icon: Icons.music_note_rounded,
                    title: 'مكتبة مسارات صوتية وتصفية الصوت',
                    subtitle:
                        'مزامنة الموسيقى التصويرية وعزل ضوضاء الرياح بالذكاء الاصطناعي.',
                  ),
                  _FeatureItem(
                    icon: Icons.aspect_ratio_rounded,
                    title: 'تنسيق أبعاد تلقائي لجميع المنصات',
                    subtitle:
                        'تكييف الفيديو فورا لريلز وتيك توك (9:16) أو يوتيوب (16:9).',
                  ),
                  _FeatureItem(
                    icon: Icons.subtitles_rounded,
                    title: 'تسميات توضيحية وعلامة مائية',
                    subtitle:
                        'توليد التسميات التلقائية مع إضافة علامتك المائية الشخصية للحماية.',
                  ),
                ],
              ),
            ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00C896), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

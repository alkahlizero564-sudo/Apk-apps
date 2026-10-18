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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.movie_creation_rounded,
                color: Color(0xFF00C896),
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'عوض الج | Awadalj',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'المشاريع المحفوظة',
            icon: const Icon(Icons.folder_special_rounded),
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
                  SizedBox(height: 16),
                  Text('جارٍ استيراد وتحليل الفيديو...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Showcase Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF1E293B),
                                const Color(0xFF0F172A),
                              ]
                            : [
                                const Color(0xFF00C896),
                                const Color(0xFF00897B),
                              ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C896).withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.amberAccent, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'مونتاج ذكي واحترافي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'اصنع فيديوهات سينمائية بضغطة زر واحدة!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أرفق الفيديو من جهازك، وسيقوم التطبيق بالقص الذكي، ومزامنة الموسيقى، وتطبيق درجات الألوان الساحرة مع حفظ المقطع النهائي في معرض الصور.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: () => _pickAndStart(context),
                                icon: const Icon(Icons.video_call_rounded,
                                    color: Color(0xFF00C896)),
                                label: const Text(
                                  'إرفاق فيديو جديد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick test with sample video
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                          color: Color(0xFF00C896), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openSample(context),
                    icon: const Icon(Icons.play_circle_outline_rounded,
                        color: Color(0xFF00C896)),
                    label: const Text(
                      'تجربة عينة فيديو فورية (بدون رفع)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C896),
                      ),
                    ),
                  ),

                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
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

                  const SizedBox(height: 28),

                  // Feature Cards Grid
                  Text(
                    'مميزات المونتاج في عوض الج',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _FeatureItem(
                    icon: Icons.movie_filter_rounded,
                    title: 'تدرج لوني سينمائي (Color Grading)',
                    subtitle:
                        'فلاتر Teal & Orange، وأفلام كوداك الكلاسيكية، ونمط الباستيل الهادئ.',
                  ),
                  _FeatureItem(
                    icon: Icons.music_note_rounded,
                    title: 'مكتبة مسارات صوتية وموسيقى ترند',
                    subtitle:
                        'مزامنة الإيقاع التلقائي وعزل ضوضاء الرياح والمحيط بالذكاء الاصطناعي.',
                  ),
                  _FeatureItem(
                    icon: Icons.aspect_ratio_rounded,
                    title: 'تنسيق أبعاد تلقائي لجميع المنصات',
                    subtitle:
                        'تكييف الفيديو فورا لأبعاد Reels وTikTok (9:16) أو YouTube (16:9).',
                  ),
                  _FeatureItem(
                    icon: Icons.download_for_offline_rounded,
                    title: 'حفظ فائق السرعة في المعرض',
                    subtitle:
                        'تصدير بجودة عالية بدون ضياع الإطارات مع إضافة علامتك المائية الخاصة.',
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
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
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
            child: Icon(icon, color: const Color(0xFF00C896), size: 24),
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
                    height: 1.3,
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

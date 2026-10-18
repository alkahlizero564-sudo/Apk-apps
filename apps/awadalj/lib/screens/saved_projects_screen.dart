import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awadalj/state/montage_provider.dart';
import 'package:awadalj/screens/editor_screen.dart';

class SavedProjectsScreen extends StatelessWidget {
  const SavedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<MontageProvider>();
    final savedList = provider.savedProjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشاريع المحفوظة بالمعرض'),
      ),
      body: savedList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Color(0xFF00C896),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فيديوهات تم حفظها بعد',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أرفق فيديو الآن واصنع أول مونتاج احترافي لك!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedList.length,
              itemBuilder: (context, index) {
                final project = savedList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151D2F) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C896), Color(0xFF00897B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.movie_filter_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'المدة: ${project.effectiveDuration.toStringAsFixed(1)}ث • ${project.presetId}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.blueGrey,
                              ),
                            ),
                            if (project.exportedFilePath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  project.exportedFilePath!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF00C896),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            color: Color(0xFF00C896)),
                        tooltip: 'تعديل في المونتير',
                        onPressed: () {
                          provider.openExistingProject(project);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditorScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
                        tooltip: 'حذف',
                        onPressed: () {
                          provider.deleteProject(project.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حذف المشروع'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

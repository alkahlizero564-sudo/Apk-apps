import 'package:flutter/material.dart';

class ExportDialog extends StatelessWidget {
  final double progress;
  final String statusText;
  final bool isCompleted;
  final VoidCallback? onDone;

  const ExportDialog({
    super.key,
    required this.progress,
    required this.statusText,
    required this.isCompleted,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).toInt();

    return PopScope(
      canPop: isCompleted,
      child: Dialog(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompleted) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 6,
                        color: const Color(0xFF00C896),
                        backgroundColor:
                            const Color(0xFF00C896).withValues(alpha: 0.15),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C896),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'جارٍ تصدير وحفظ المونتاج...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: const Color(0xFF00C896),
                    backgroundColor:
                        const Color(0xFF00C896).withValues(alpha: 0.15),
                  ),
                ),
              ] else ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00C896),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تم حفظ الفيديو في المعرض بنجاح!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'تمت معالجة الفيديو بجودة عالية وتخزينه في مجلد المعرض (Gallery) بهاتفك.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: onDone,
                    icon: const Icon(Icons.done_all_rounded, size: 20),
                    label: const Text(
                      'تم واستعراض المقطع',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import 'audio_visualizer.dart';

class QueueDialog extends StatelessWidget {
  const QueueDialog({super.key});

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final queue = vm.queue;
    final currentIndex = vm.currentIndex;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF2E2E3C), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: AppTheme.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Çalma Sırası (Sıradaki Şarkılar)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${queue.length} parça sırada • Sürükleyerek sırayı değiştirebilirsiniz',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (queue.length > 1)
                    TextButton.icon(
                      onPressed: vm.clearUpcomingQueue,
                      icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppTheme.error),
                      label: const Text(
                        'Sırayı Temizle',
                        style: TextStyle(color: AppTheme.error, fontSize: 12.5),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF262632), height: 1),
              const SizedBox(height: 12),

              // Queue List
              Expanded(
                child: queue.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.queue_music_outlined, size: 48, color: AppTheme.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'Çalma sırası boş.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: queue.length,
                        onReorder: vm.reorderQueue,
                        itemBuilder: (context, index) {
                          final track = queue[index];
                          final isCurrent = index == currentIndex;

                          return Container(
                            key: ValueKey('queue_${track.id}_$index'),
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.primary.withAlpha(35)
                                  : AppTheme.surfaceElevated.withAlpha(140),
                              borderRadius: BorderRadius.circular(10),
                              border: isCurrent
                                  ? Border.all(color: AppTheme.primary.withAlpha(110), width: 1)
                                  : null,
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color: AppTheme.textMuted,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: isCurrent && vm.isPlaying
                                          ? const AudioVisualizer(isPlaying: true, maxHeight: 14)
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: isCurrent ? AppTheme.primaryLight : AppTheme.textMuted,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.primaryLight : AppTheme.textPrimary,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatDuration(track.duration),
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                  ),
                                  const SizedBox(width: 6),
                                  if (!isCurrent)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.textMuted),
                                      tooltip: 'Sıradan Çıkar',
                                      onPressed: () => vm.removeFromQueueAt(index),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      child: Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.primaryLight),
                                    ),
                                ],
                              ),
                              onTap: () => vm.playTrack(track),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

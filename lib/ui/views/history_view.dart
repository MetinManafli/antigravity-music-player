import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/track_list_item.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.primaryLight,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Son Çalınanlar',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'En son dinlediğiniz ${vm.recentTracks.length} parça',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (vm.recentTracks.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: vm.clearRecentHistory,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppTheme.error),
                    label: const Text('Geçmişi Temizle', style: TextStyle(color: AppTheme.error)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      vm.playTrack(vm.recentTracks.first, newQueue: vm.recentTracks);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Hepsini Çal'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: vm.recentTracks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            size: 60,
                            color: AppTheme.textMuted.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz şarkı çalmadınız',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Çaldığınız şarkılar otomatik olarak bu listede görünecektir.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: vm.recentTracks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final track = vm.recentTracks[index];
                        return TrackListItem(
                          track: track,
                          index: index,
                          queueContext: vm.recentTracks,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

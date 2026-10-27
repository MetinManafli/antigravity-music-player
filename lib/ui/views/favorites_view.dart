import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/track_list_item.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Beğendiğim Şarkılar',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${vm.favorites.length} Şarkı',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (vm.favorites.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      vm.playTrack(vm.favorites.first, newQueue: vm.favorites);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Hepsini Çal'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // List or Empty
            Expanded(
              child: vm.favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 60,
                            color: AppTheme.textMuted.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz favori şarkınız yok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Şarkıların yanındaki kalp simgesine tıklayarak favorilerinize ekleyebilirsiniz.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: vm.favorites.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final track = vm.favorites[index];
                        return TrackListItem(
                          track: track,
                          index: index,
                          queueContext: vm.favorites,
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

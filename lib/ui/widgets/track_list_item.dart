import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import 'audio_visualizer.dart';
import 'add_to_playlist_dialog.dart';
import 'track_info_dialog.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final int? index;
  final List<Track>? queueContext;
  final VoidCallback? onCustomRemove;
  final String? removeLabel;

  const TrackListItem({
    super.key,
    required this.track,
    this.index,
    this.queueContext,
    this.onCustomRemove,
    this.removeLabel,
  });

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final isCurrent = vm.currentTrack?.id == track.id;
    final isPlaying = isCurrent && vm.isPlaying;
    final isFav = vm.isFavorite(track);

    return Material(
      color: isCurrent ? AppTheme.surfaceElevated : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppTheme.surfaceElevated.withAlpha(120),
        onTap: () {
          vm.playTrack(track, newQueue: queueContext);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Index or playing visualizer
              Container(
                width: 32,
                alignment: Alignment.center,
                child: isPlaying
                    ? const AudioVisualizer(isPlaying: true, maxHeight: 16)
                    : isCurrent
                        ? const Icon(Icons.pause, color: AppTheme.primary, size: 18)
                        : Text(
                            index != null ? '${index! + 1}' : '',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
              ),
              const SizedBox(width: 8),

              // Thumbnail or Music Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  color: AppTheme.surfaceHighlight,
                  child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          track.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.music_note,
                            color: AppTheme.textMuted,
                            size: 22,
                          ),
                        )
                      : Icon(
                          track.isOnline ? Icons.cloud : Icons.music_note,
                          color: isCurrent ? AppTheme.primaryLight : AppTheme.textMuted,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Artist, Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? AppTheme.primaryLight : AppTheme.textPrimary,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (track.isOnline) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withAlpha(35),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.accent.withAlpha(90),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'Online',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (track.lyrics != null && track.lyrics!.trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message: 'Şarkı sözü mevcut',
                            child: Icon(Icons.lyrics_outlined, size: 14, color: AppTheme.primaryLight),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        if (track.playCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${track.playCount} dinlenme',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Album (if desktop wide space)
              if (track.album != null && track.album!.isNotEmpty) ...[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    track.album!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 16),

              // Duration
              Text(
                _formatDuration(track.duration),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12.5,
                ),
              ),

              const SizedBox(width: 8),

              // Favorite Heart Button
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppTheme.error : AppTheme.textMuted,
                  size: 20,
                ),
                splashRadius: 18,
                tooltip: isFav ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                onPressed: () => vm.toggleFavorite(track),
              ),

              // Context Menu (3 dots)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
                tooltip: 'Seçenekler',
                color: AppTheme.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play_now',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, size: 18, color: AppTheme.primaryLight),
                        SizedBox(width: 10),
                        Text('Şimdi Çal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'play_next',
                    child: Row(
                      children: [
                        Icon(Icons.queue_play_next_rounded, size: 18, color: AppTheme.accent),
                        SizedBox(width: 10),
                        Text('Bundan Sonra Çal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_queue',
                    child: Row(
                      children: [
                        Icon(Icons.add_to_queue_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Çalma Sırasına Ekle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add, size: 18),
                        SizedBox(width: 10),
                        Text('Çalma Listesine Ekle'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'track_info',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.primaryLight),
                        SizedBox(width: 10),
                        Text('Şarkı Bilgileri & Düzenle'),
                      ],
                    ),
                  ),
                  if (!track.isOnline && !kIsWeb)
                    const PopupMenuItem(
                      value: 'reveal_in_explorer',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Dosya Konumunu Göster'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  if (onCustomRemove != null)
                    PopupMenuItem(
                      value: 'custom_remove',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                          const SizedBox(width: 10),
                          Text(removeLabel ?? 'Listeden Kaldır',
                              style: const TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    )
                  else if (!track.isOnline)
                    const PopupMenuItem(
                      value: 'remove_from_library',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                          SizedBox(width: 10),
                          Text('Kütüphaneden Kaldır', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'play_now':
                      vm.playTrack(track, newQueue: queueContext);
                      break;
                    case 'play_next':
                      vm.playNextInQueue(track);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${track.title}" sıradaki şarkı olarak ayarlandı.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      break;
                    case 'add_to_queue':
                      vm.addToQueue(track);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${track.title}" çalma sırasına eklendi.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      break;
                    case 'add_to_playlist':
                      showDialog(
                        context: context,
                        builder: (_) => AddToPlaylistDialog(track: track),
                      );
                      break;
                    case 'track_info':
                      showDialog(
                        context: context,
                        builder: (_) => TrackInfoDialog(track: track),
                      );
                      break;
                    case 'reveal_in_explorer':
                      vm.revealInExplorer(track);
                      break;
                    case 'custom_remove':
                      onCustomRemove?.call();
                      break;
                    case 'remove_from_library':
                      vm.removeTrackFromLibrary(track);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

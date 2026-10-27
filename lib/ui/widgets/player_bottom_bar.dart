import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import 'audio_effects_dialog.dart';
import 'audio_visualizer.dart';
import 'now_playing_modal.dart';
import 'queue_sheet.dart';

class PlayerBottomBar extends StatelessWidget {
  const PlayerBottomBar({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _openNowPlaying(BuildContext context, PlayerViewModel vm) {
    if (vm.currentTrack == null) return;
    showDialog(
      context: context,
      builder: (_) => const NowPlayingModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final track = vm.currentTrack;

    return Container(
      height: 106,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFF262630), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // 1. Left: Track Details (Clickable to open Fullscreen Now Playing)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InkWell(
                  onTap: track != null ? () => _openNowPlaying(context, vm) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 52,
                          height: 52,
                          color: AppTheme.surfaceElevated,
                          child: track != null && track.thumbnailUrl != null
                              ? Image.network(
                                  track.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.music_note,
                                    color: AppTheme.primaryLight,
                                    size: 28,
                                  ),
                                )
                              : const Icon(
                                  Icons.music_note,
                                  color: AppTheme.textMuted,
                                  size: 28,
                                ),
                        ),
                      ),
                      if (track != null)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              size: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: track != null ? () => _openNowPlaying(context, vm) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.title ?? 'Çalınan şarkı yok',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            track?.artist ?? 'Bir şarkı seçip dinlemeye başlayın',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (track != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      vm.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
                      color: vm.isFavorite(track) ? AppTheme.error : AppTheme.textMuted,
                      size: 20,
                    ),
                    tooltip: vm.isFavorite(track) ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                    onPressed: () => vm.toggleFavorite(track),
                  ),
                ],
              ],
            ),
          ),

          // 2. Center: Controls & Progress Seekbar
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: Image.asset(
                        'assets/icons/shuffle.png',
                        width: 19,
                        height: 19,
                        color: vm.isShuffle ? AppTheme.primaryLight : AppTheme.textMuted,
                      ),
                      tooltip: vm.isShuffle ? 'Karışık Çalma: Açık (S)' : 'Karışık Çalma: Kapalı (S)',
                      onPressed: vm.toggleShuffle,
                    ),
                    const SizedBox(width: 4),

                    // Seek -5s
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(
                        Icons.replay_5_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: '5 Saniye Geri (Sol Ok)',
                      onPressed: () => vm.seekRelative(const Duration(seconds: -5)),
                    ),
                    const SizedBox(width: 4),

                    // Previous
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: AppTheme.textPrimary,
                        size: 26,
                      ),
                      tooltip: 'Önceki Şarkı (P)',
                      onPressed: vm.previous,
                    ),
                    const SizedBox(width: 8),

                    // Play/Pause Big Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: vm.togglePlayPause,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(100),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: vm.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    vm.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppTheme.textPrimary,
                        size: 26,
                      ),
                      tooltip: 'Sonraki Şarkı (N)',
                      onPressed: vm.next,
                    ),
                    const SizedBox(width: 4),

                    // Seek +5s
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(
                        Icons.forward_5_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: '5 Saniye İleri (Sağ Ok)',
                      onPressed: () => vm.seekRelative(const Duration(seconds: 5)),
                    ),
                    const SizedBox(width: 4),

                    // Repeat Mode
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: Icon(
                        vm.repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: vm.repeatMode != RepeatMode.off
                            ? AppTheme.primaryLight
                            : AppTheme.textMuted,
                        size: 20,
                      ),
                      tooltip: switch (vm.repeatMode) {
                        RepeatMode.off => 'Tekrar: Kapalı (R)',
                        RepeatMode.all => 'Tekrar: Tüm Liste (R)',
                        RepeatMode.one => 'Tekrar: Tek Şarkı (R)',
                      },
                      onPressed: vm.toggleRepeatMode,
                    ),
                  ],
                ),

                // Seekbar & timestamps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(vm.currentPosition),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (vm.isABLoopActive) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: vm.clearABLoop,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withAlpha(45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'A-B',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: vm.totalDuration.inMilliseconds > 0
                                ? (vm.currentPosition.inMilliseconds /
                                        vm.totalDuration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            onChanged: (val) {
                              if (vm.totalDuration.inMilliseconds > 0) {
                                final seekPos = Duration(
                                  milliseconds:
                                      (val * vm.totalDuration.inMilliseconds).toInt(),
                                );
                                vm.seek(seekPos);
                              }
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(vm.totalDuration),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Right: Speed/Effects, Queue, Volume & Extras
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (vm.showVisualizer) ...[
                  AudioVisualizer(isPlaying: vm.isPlaying, barCount: 4, maxHeight: 16),
                  const SizedBox(width: 8),
                ],

                // Audio Effects, Speed, A-B Loop & Sleep Timer Button
                Builder(
                  builder: (context) {
                    final hasActiveEffects = vm.eqEnabled ||
                        vm.playbackRate != 1.0 ||
                        vm.balance != 0.0 ||
                        vm.isSleepTimerActive ||
                        vm.isABLoopActive;
                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AudioEffectsDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: hasActiveEffects
                              ? AppTheme.primary.withAlpha(40)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasActiveEffects
                                ? AppTheme.primary.withAlpha(100)
                                : const Color(0xFF2E2E3A),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vm.isSleepTimerActive ? Icons.bedtime_rounded : Icons.tune_rounded,
                              size: 15,
                              color: vm.isSleepTimerActive ? Colors.amber : AppTheme.primaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vm.eqEnabled && vm.playbackRate == 1.0
                                  ? 'EQ'
                                  : '${vm.playbackRate.toStringAsFixed(vm.playbackRate % 1 == 0 ? 1 : 2)}x',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Queue Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Badge(
                    isLabelVisible: vm.queue.isNotEmpty,
                    backgroundColor: AppTheme.primary,
                    label: Text(
                      '${vm.queue.length}',
                      style: const TextStyle(fontSize: 9.5, color: Colors.white),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: AppTheme.textSecondary,
                      size: 21,
                    ),
                  ),
                  tooltip: 'Çalma Sırası (Q)',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const QueueDialog(),
                    );
                  },
                ),

                // Mini Player (Always-on-Top) Toggle Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: AppTheme.textSecondary,
                    size: 19,
                  ),
                  tooltip: 'Mini Oynatıcı Modu (Her Zaman Üstte)',
                  onPressed: vm.toggleMiniPlayerMode,
                ),

                // Volume icon toggle mute
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    vm.isMuted
                        ? Icons.volume_off_rounded
                        : vm.volume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    color: vm.isMuted ? AppTheme.error : AppTheme.textSecondary,
                    size: 20,
                  ),
                  tooltip: vm.isMuted ? 'Sesi Aç (M)' : 'Sesi Kapat (M)',
                  onPressed: vm.toggleMute,
                ),

                // Volume slider
                Flexible(
                  child: SizedBox(
                    width: 78,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      ),
                      child: Slider(
                        value: vm.volume,
                        onChanged: vm.setVolume,
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import 'audio_visualizer.dart';
import 'track_info_dialog.dart';

class NowPlayingModal extends StatelessWidget {
  const NowPlayingModal({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final track = vm.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return Dialog.fullscreen(
      backgroundColor: AppTheme.background,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: AppTheme.textPrimary),
            tooltip: 'Küçült',
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              const Text(
                'ŞİMDİ ÇALINIYOR',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
              Text(
                track.album ?? 'Antigravity Music Player',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.textSecondary),
              tooltip: 'Şarkı Bilgileri & Sözlerini Düzenle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => TrackInfoDialog(track: track),
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            children: [
              // Left/Center: Big Artwork, Visualizer & Transport Controls
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Album Art Card
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3A2468), Color(0xFF1A1A26)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(70),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              track.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.album_rounded,
                                size: 96,
                                color: AppTheme.primaryLight,
                              ),
                            )
                          : const Icon(
                              Icons.album_rounded,
                              size: 96,
                              color: AppTheme.primaryLight,
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Large Audio Visualizer
                    AudioVisualizer(
                      isPlaying: vm.isPlaying,
                      barCount: 24,
                      maxHeight: 36,
                      color: AppTheme.primaryLight,
                    ),
                    const SizedBox(height: 20),

                    // Track Title & Artist
                    Text(
                      track.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.artist,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Slider
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          Slider(
                            value: vm.totalDuration.inMilliseconds > 0
                                ? (vm.currentPosition.inMilliseconds / vm.totalDuration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            onChanged: (val) {
                              if (vm.totalDuration.inMilliseconds > 0) {
                                vm.seek(Duration(
                                  milliseconds: (val * vm.totalDuration.inMilliseconds).toInt(),
                                ));
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(vm.currentPosition),
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                if (vm.isABLoopActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'A-B Döngüsü: ${_formatDuration(vm.loopStartA!)} - ${_formatDuration(vm.loopEndB!)}',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _formatDuration(vm.totalDuration),
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Playback Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Image.asset(
                            'assets/icons/shuffle.png',
                            width: 22,
                            height: 22,
                            color: vm.isShuffle ? AppTheme.primaryLight : AppTheme.textMuted,
                          ),
                          tooltip: 'Karışık Çal',
                          onPressed: vm.toggleShuffle,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.replay_5_rounded, size: 26, color: AppTheme.textSecondary),
                          tooltip: '5 Saniye Geri',
                          onPressed: () => vm.seekRelative(const Duration(seconds: -5)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 34, color: AppTheme.textPrimary),
                          tooltip: 'Önceki Şarkı',
                          onPressed: vm.previous,
                        ),
                        const SizedBox(width: 14),
                        InkWell(
                          onTap: vm.togglePlayPause,
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withAlpha(110),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              vm.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 34, color: AppTheme.textPrimary),
                          tooltip: 'Sonraki Şarkı',
                          onPressed: vm.next,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.forward_5_rounded, size: 26, color: AppTheme.textSecondary),
                          tooltip: '5 Saniye İleri',
                          onPressed: () => vm.seekRelative(const Duration(seconds: 5)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            vm.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: vm.repeatMode != RepeatMode.off
                                ? AppTheme.primaryLight
                                : AppTheme.textMuted,
                            size: 24,
                          ),
                          tooltip: 'Tekrar Modu',
                          onPressed: vm.toggleRepeatMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Lyrics / Notes & Quick A-B Loop Panel
              if (MediaQuery.of(context).size.width >= 820) ...[
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF282834)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lyrics_rounded, color: AppTheme.primaryLight, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Şarkı Sözleri & Notlar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: vm.isFetchingLyrics
                                      ? null
                                      : () async {
                                          final found = await vm.fetchOnlineLyrics(track);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  found != null
                                                      ? 'Şarkı sözleri internetten bulundu ve kaydedildi!'
                                                      : 'Bu parça için otomatik şarkı sözü bulunamadı.',
                                                ),
                                                backgroundColor: found != null ? AppTheme.success : AppTheme.error,
                                              ),
                                            );
                                          }
                                        },
                                  icon: vm.isFetchingLyrics
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.auto_fix_high_rounded, size: 15, color: AppTheme.accent),
                                  label: const Text('Otomatik Söz Bul', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => TrackInfoDialog(track: track),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, size: 15),
                                  label: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF262632), height: 20),
                        Expanded(
                          child: track.lyrics != null && track.lyrics!.trim().isNotEmpty
                              ? SingleChildScrollView(
                                  child: SelectableText(
                                    track.lyrics!,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      height: 1.7,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lyrics_outlined,
                                        size: 48,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Bu şarkı için henüz şarkı sözü eklenmemiş.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: vm.isFetchingLyrics
                                                ? null
                                                : () async {
                                                    final found = await vm.fetchOnlineLyrics(track);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            found != null
                                                                ? 'Şarkı sözleri internetten bulundu ve kaydedildi!'
                                                                : 'Bu parça için otomatik şarkı sözü bulunamadı.',
                                                          ),
                                                          backgroundColor: found != null ? AppTheme.success : AppTheme.error,
                                                        ),
                                                      );
                                                    }
                                                  },
                                            icon: vm.isFetchingLyrics
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const Icon(Icons.auto_fix_high_rounded, size: 16),
                                            label: const Text('İnternetten Otomatik Bul'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => TrackInfoDialog(track: track),
                                              );
                                            },
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Manuel Ekle'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
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

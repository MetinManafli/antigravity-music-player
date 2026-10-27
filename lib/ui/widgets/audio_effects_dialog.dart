import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';

class AudioEffectsDialog extends StatelessWidget {
  const AudioEffectsDialog({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDb(double val) {
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(1)} dB';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF2E2E3C), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        Icons.tune_rounded,
                        color: AppTheme.primaryLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stüdyo Ekolayzer & Ses Efektleri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '5-Bant ekolayzer, hız, stereo denge, A-B döngüsü ve uyku modu',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        vm.resetAudioEffects();
                        vm.resetEqualizer();
                      },
                      child: const Text('Sıfırla'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFF262632), height: 1),
                const SizedBox(height: 18),

                // 0. 5-Band Equalizer Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.equalizer_rounded, size: 19, color: AppTheme.primaryLight),
                        const SizedBox(width: 8),
                        const Text(
                          '5-Bant Grafik Ekolayzer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14.5,
                          ),
                        ),
                        if (vm.isProcessingEq) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: vm.eqEnabled
                                ? AppTheme.primary.withAlpha(35)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AudioPlayerService.eqPresetNames[vm.eqPreset] ?? 'Özel',
                            style: TextStyle(
                              color: vm.eqEnabled ? AppTheme.primaryLight : AppTheme.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: vm.eqEnabled,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (val) => vm.toggleEqualizer(val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // EQ Presets Wrap
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AudioPlayerService.eqPresetNames.entries
                      .where((e) => e.key != 'custom')
                      .map((entry) {
                    final isSelected = vm.eqPreset == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value, style: const TextStyle(fontSize: 11.5)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary.withAlpha(65),
                      backgroundColor: AppTheme.surfaceElevated,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => vm.setEqPreset(entry.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 5 Vertical Band Sliders
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: vm.eqEnabled
                          ? AppTheme.primary.withAlpha(70)
                          : const Color(0xFF2E2E3A),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(AudioPlayerService.eqFrequencies.length, (i) {
                      final gain = i < vm.eqBands.length ? vm.eqBands[i] : 0.0;
                      final label = AudioPlayerService.eqLabels[i];
                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDb(gain),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: vm.eqEnabled
                                    ? (gain != 0 ? AppTheme.primaryLight : AppTheme.textSecondary)
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 135,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    activeTrackColor:
                                        vm.eqEnabled ? AppTheme.primary : AppTheme.textMuted,
                                    thumbColor:
                                        vm.eqEnabled ? Colors.white : AppTheme.textSecondary,
                                    thumbShape:
                                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  ),
                                  child: Slider(
                                    value: gain.clamp(-12.0, 12.0),
                                    min: -12.0,
                                    max: 12.0,
                                    divisions: 48,
                                    onChanged: (val) =>
                                        vm.setEqBand(i, val, applyNow: false),
                                    onChangeEnd: (val) => vm.applyEqualizerChanges(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFF262632), height: 1),
                const SizedBox(height: 18),

                // 1. Playback Speed & Presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed_rounded, size: 18, color: AppTheme.primaryLight),
                        SizedBox(width: 8),
                        Text(
                          'Oynatma Hızı & Ses Modu',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${vm.playbackRate.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: vm.playbackRate.clamp(0.5, 2.0),
                  min: 0.5,
                  max: 2.0,
                  divisions: 30,
                  onChanged: vm.setPlaybackRate,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip('0.5x Yavaş', 0.5, vm),
                    _buildPresetChip('0.85x Slowed', 0.85, vm),
                    _buildPresetChip('1.0x Normal', 1.0, vm),
                    _buildPresetChip('1.25x Nightcore', 1.25, vm),
                    _buildPresetChip('1.5x Hızlı', 1.5, vm),
                    _buildPresetChip('2.0x Turbo', 2.0, vm),
                  ],
                ),

                const SizedBox(height: 22),

                // 2. Stereo Balance (L / R)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speaker_group_rounded, size: 18, color: AppTheme.accent),
                        SizedBox(width: 8),
                        Text(
                          'Stereo Kanal Dengesi (Sol / Sağ)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      vm.balance == 0
                          ? 'Merkez (0%)'
                          : vm.balance < 0
                              ? 'Sol %${(vm.balance.abs() * 100).round()}'
                              : 'Sağ %${(vm.balance * 100).round()}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('SOL', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: vm.balance.clamp(-1.0, 1.0),
                        min: -1.0,
                        max: 1.0,
                        divisions: 20,
                        activeColor: AppTheme.accent,
                        onChanged: vm.setBalance,
                      ),
                    ),
                    const Text('SAĞ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: Color(0xFF262632), height: 1),
                const SizedBox(height: 18),

                // 3. A-B Loop (Kesit Tekrarlama)
                const Row(
                  children: [
                    Icon(Icons.repeat_on_rounded, size: 18, color: AppTheme.primaryLight),
                    SizedBox(width: 8),
                    Text(
                      'A-B Kesit Tekrarlama (A-B Loop)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Çalan şarkının belirli bir bölümünü sürekli tekrarlamak için A (Başlangıç) ve B (Bitiş) noktalarını seçin.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: vm.currentTrack == null ? null : () => vm.setLoopPointA(),
                        icon: const Icon(Icons.flag_rounded, size: 16, color: AppTheme.primaryLight),
                        label: Text(
                          vm.loopStartA != null
                              ? 'A: ${_formatDuration(vm.loopStartA!)}'
                              : 'A Noktası Seç',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: vm.currentTrack == null ? null : () => vm.setLoopPointB(),
                        icon: const Icon(Icons.sports_score_rounded, size: 16, color: AppTheme.accent),
                        label: Text(
                          vm.loopEndB != null
                              ? 'B: ${_formatDuration(vm.loopEndB!)}'
                              : 'B Noktası Seç',
                        ),
                      ),
                    ),
                    if (vm.loopStartA != null || vm.loopEndB != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.error),
                        tooltip: 'A-B Döngüsünü Kapat',
                        onPressed: vm.clearABLoop,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 22),
                const Divider(color: Color(0xFF262632), height: 1),
                const SizedBox(height: 18),

                // 4. Sleep Timer (Uyku Zamanlayıcısı)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bedtime_rounded, size: 18, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Uyku Zamanlayıcısı (Otomatik Durdurma)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (vm.isSleepTimerActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vm.stopAfterCurrentTrack
                              ? 'Şarkı Bitince Duracak'
                              : 'Kalan: ${_formatDuration(vm.sleepTimerRemaining!)}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSleepChip('15 Dakika', const Duration(minutes: 15), vm),
                    _buildSleepChip('30 Dakika', const Duration(minutes: 30), vm),
                    _buildSleepChip('45 Dakika', const Duration(minutes: 45), vm),
                    _buildSleepChip('60 Dakika', const Duration(minutes: 60), vm),
                    ActionChip(
                      avatar: Icon(
                        Icons.music_off_rounded,
                        size: 16,
                        color: vm.stopAfterCurrentTrack ? Colors.amber : AppTheme.textSecondary,
                      ),
                      label: const Text('Şarkı Bitince Durdur'),
                      backgroundColor: vm.stopAfterCurrentTrack
                          ? Colors.amber.withAlpha(35)
                          : AppTheme.surfaceElevated,
                      onPressed: () {
                        if (vm.stopAfterCurrentTrack) {
                          vm.cancelSleepTimer();
                        } else {
                          vm.setSleepTimer(null, afterCurrentTrack: true);
                        }
                      },
                    ),
                    if (vm.isSleepTimerActive)
                      ActionChip(
                        avatar: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.error),
                        label: const Text('Zamanlayıcıyı İptal Et', style: TextStyle(color: AppTheme.error)),
                        backgroundColor: AppTheme.error.withAlpha(25),
                        onPressed: vm.cancelSleepTimer,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double rate, PlayerViewModel vm) {
    final isSelected = (vm.playbackRate - rate).abs() < 0.02;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: isSelected,
      selectedColor: AppTheme.primary.withAlpha(65),
      backgroundColor: AppTheme.surfaceElevated,
      onSelected: (_) => vm.setPlaybackRate(rate),
    );
  }

  Widget _buildSleepChip(String label, Duration duration, PlayerViewModel vm) {
    return ActionChip(
      avatar: const Icon(Icons.timer_outlined, size: 15, color: AppTheme.textSecondary),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      backgroundColor: AppTheme.surfaceElevated,
      onPressed: () => vm.setSleepTimer(duration),
    );
  }
}

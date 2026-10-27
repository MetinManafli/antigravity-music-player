import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/online_music_service.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_effects_dialog.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isRunningMaintenance = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<PlayerViewModel>();
      vm.refreshAudioCacheSize();
      vm.checkExternalEngines();
    });
  }

  String _formatDb(double val) {
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(1)} dB';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(70),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ayarlar & Stüdyo Ekolayzer',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '5-Bant ses ekolayzeri, YouTube indirici tercihleri, önbellek ve sistem bakım araçları',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    vm.refreshAudioCacheSize();
                    vm.checkExternalEngines();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.accent),
                  label: const Text('Durumu Yenile'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 1. Stüdyo Ekolayzer & Ses İşleme (5-Bant Grafik Ekolayzer)
            _buildSectionCard(
              icon: Icons.equalizer_rounded,
              iconColor: AppTheme.primaryLight,
              title: '🎚️ Stüdyo Ekolayzer & Ses İşleme (5-Bant Grafik Ekolayzer)',
              subtitle:
                  'FFmpeg tabanlı 5-bant parametrik ses işleme motoru ve hazır müzik profilleri',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (vm.isProcessingEq)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: vm.resetEqualizer,
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: const Text('Sıfırla (0 dB)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AudioEffectsDialog(),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryLight),
                    label: const Text('Gelişmiş Efektler & Uyku Zamanlayıcı'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vm.eqEnabled ? 'Ekolayzer Aktif' : 'Kapalı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: vm.eqEnabled ? AppTheme.primaryLight : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: vm.eqEnabled,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) => vm.toggleEqualizer(val),
                      ),
                    ],
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 10 Preset Chips
                  const Text(
                    'Hazır Ses Profilleri (Presets)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AudioPlayerService.eqPresetNames.entries
                        .where((e) => e.key != 'custom')
                        .map((entry) {
                      final isSelected = vm.eqPreset == entry.key;
                      return ChoiceChip(
                        avatar: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.graphic_eq_rounded,
                          size: 16,
                          color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                        ),
                        label: Text(entry.value, style: const TextStyle(fontSize: 12.5)),
                        selected: isSelected,
                        selectedColor: AppTheme.primary.withAlpha(65),
                        backgroundColor: AppTheme.surfaceElevated,
                        onSelected: (_) => vm.setEqPreset(entry.key),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 5 Vertical Equalizer Band Sliders with visual dB scale
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: vm.eqEnabled
                            ? AppTheme.primary.withAlpha(80)
                            : const Color(0xFF2E2E3A),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Visual dB scale on the left
                        SizedBox(
                          height: 170,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 24),
                                child: Text(
                                  '+12 dB',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '0 dB',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Text(
                                  '-12 dB',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 5 Band Vertical Sliders
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              AudioPlayerService.eqFrequencies.length,
                              (i) {
                                final gain = i < vm.eqBands.length ? vm.eqBands[i] : 0.0;
                                final label = AudioPlayerService.eqLabels[i];
                                return Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: vm.eqEnabled && gain != 0
                                              ? AppTheme.primary.withAlpha(40)
                                              : AppTheme.surface,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatDb(gain),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: vm.eqEnabled
                                                ? (gain != 0
                                                    ? AppTheme.primaryLight
                                                    : AppTheme.textSecondary)
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 150,
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 5,
                                              activeTrackColor: vm.eqEnabled
                                                  ? AppTheme.primary
                                                  : AppTheme.textMuted,
                                              thumbColor: vm.eqEnabled
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                              thumbShape: const RoundSliderThumbShape(
                                                enabledThumbRadius: 7,
                                              ),
                                            ),
                                            child: Slider(
                                              value: gain.clamp(-12.0, 12.0),
                                              min: -12.0,
                                              max: 12.0,
                                              divisions: 48,
                                              onChanged: (val) =>
                                                  vm.setEqBand(i, val, applyNow: false),
                                              onChangeEnd: (val) =>
                                                  vm.applyEqualizerChanges(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Playback Speed & Stereo Balance Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Playback Speed
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E2E3A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.speed_rounded, size: 17, color: AppTheme.primaryLight),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Oynatma Hızı (0.5x - 2.0x)',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${vm.playbackRate.toStringAsFixed(2)}x',
                                    style: const TextStyle(
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: vm.playbackRate.clamp(0.5, 2.0),
                                min: 0.5,
                                max: 2.0,
                                divisions: 30,
                                onChanged: vm.setPlaybackRate,
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [0.75, 0.85, 1.0, 1.25, 1.5].map((spd) {
                                  final selected = (vm.playbackRate - spd).abs() < 0.02;
                                  return ChoiceChip(
                                    label: Text('${spd}x', style: const TextStyle(fontSize: 11.5)),
                                    selected: selected,
                                    visualDensity: VisualDensity.compact,
                                    selectedColor: AppTheme.primary.withAlpha(65),
                                    backgroundColor: AppTheme.surface,
                                    onSelected: (_) => vm.setPlaybackRate(spd),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Stereo Balance
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E2E3A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.speaker_group_rounded, size: 17, color: AppTheme.accent),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Stereo Kanal Dengesi (Sol / Sağ)',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    vm.balance == 0
                                        ? 'Merkez (0%)'
                                        : vm.balance < 0
                                            ? 'Sol %${(vm.balance.abs() * 100).round()}'
                                            : 'Sağ %${(vm.balance * 100).round()}',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Sol', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
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
                                  const Text('Sağ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ActionChip(
                                    label: const Text('Sol (-50%)', style: TextStyle(fontSize: 11.5)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: AppTheme.surface,
                                    onPressed: () => vm.setBalance(-0.5),
                                  ),
                                  ActionChip(
                                    label: const Text('Merkez (0%)', style: TextStyle(fontSize: 11.5)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: AppTheme.surface,
                                    onPressed: () => vm.setBalance(0.0),
                                  ),
                                  ActionChip(
                                    label: const Text('Sağ (+50%)', style: TextStyle(fontSize: 11.5)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: AppTheme.surface,
                                    onPressed: () => vm.setBalance(0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. YouTube İndirici & Kayıt Klasörü Ayarları
            _buildSectionCard(
              icon: Icons.cloud_download_rounded,
              iconColor: AppTheme.accent,
              title: '📥 YouTube İndirici & Kayıt Klasörü Ayarları',
              subtitle:
                  'Varsayılan indirme klasörü, ses kodeği (Opus / M4A) ve çoklu iş parçacığı hızlandırma ayarları',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default Download Folder
                  const Text(
                    'Varsayılan İndirme Klasörü',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2E2E3A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_rounded, color: AppTheme.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            vm.customDownloadDir.isNotEmpty ? vm.customDownloadDir : vm.defaultDownloadDirectory,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontFamily: 'Consolas',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: vm.pickCustomDownloadDir,
                          icon: const Icon(Icons.drive_folder_upload_rounded, size: 17),
                          label: const Text('Klasör Seç'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: vm.openDownloadDirInExplorer,
                          icon: const Icon(Icons.folder_open_rounded, size: 17),
                          label: const Text('Klasörü Aç'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Default Audio Format Selector
                  const Text(
                    'Varsayılan Ses Formatı & Kalite',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: AudioDownloadFormat.values.map((fmt) {
                      final isSelected = vm.downloadFormat == fmt;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: fmt == AudioDownloadFormat.values.first ? 8 : 0,
                            left: fmt == AudioDownloadFormat.values.last ? 8 : 0,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => vm.setDownloadFormat(fmt),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withAlpha(35)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFF2E2E3A),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? AppTheme.primaryLight
                                            : AppTheme.textMuted,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fmt.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSelected
                                                ? AppTheme.textPrimary
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    fmt.description,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Concurrent Downloads & Threads per track
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eşzamanlı Şarkı İndirme (1-10)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E2E3A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Eşzamanlı Şarkı İndirme',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${vm.concurrentDownloads} Şarkı Aynı Anda',
                                      style: const TextStyle(
                                        color: AppTheme.primaryLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: vm.concurrentDownloads.clamp(1, 10).toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                onChanged: (val) => vm.setConcurrentDownloads(val.round()),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [1, 3, 5, 8, 10].map((cnt) {
                                  final selected = vm.concurrentDownloads == cnt;
                                  return ChoiceChip(
                                    label: Text('$cnt Şarkı', style: const TextStyle(fontSize: 11.5)),
                                    selected: selected,
                                    visualDensity: VisualDensity.compact,
                                    selectedColor: AppTheme.primary.withAlpha(65),
                                    backgroundColor: AppTheme.surface,
                                    onSelected: (_) => vm.setConcurrentDownloads(cnt),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Parça Başına Bağlantı / Thread (1, 4, 8, 16)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E2E3A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Parça Başına Bağlantı (Thread)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${vm.downloadThreads}x Hızlandırma',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'yt-dlp --concurrent-fragments için parça başına paralel bağlantı sayısı:',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [1, 4, 8, 16].map((th) {
                                  final selected = vm.downloadThreads == th;
                                  return ChoiceChip(
                                    label: Text('${th}x Thread', style: const TextStyle(fontSize: 12)),
                                    selected: selected,
                                    visualDensity: VisualDensity.compact,
                                    selectedColor: AppTheme.accent.withAlpha(65),
                                    backgroundColor: AppTheme.surface,
                                    onSelected: (_) => vm.setDownloadThreads(th),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Görünüm, Oynatma & Şarkı Sözleri
            _buildSectionCard(
              icon: Icons.palette_rounded,
              iconColor: AppTheme.primaryLight,
              title: '🎨 Görünüm, Oynatma & Şarkı Sözleri',
              subtitle: 'Arayüz görselleştirmeleri ve çevrim içi şarkı sözü entegrasyonu',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: const Icon(Icons.graphic_eq_rounded, color: AppTheme.primaryLight),
                    title: const Text(
                      'Ses Görselleştirici (Audio Visualizer)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Alt oynatma çubuğunda dinamik frekans çubuklarını göster',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                    value: vm.showVisualizer,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (val) => vm.setShowVisualizer(val),
                  ),
                  const Divider(color: Color(0xFF262632), height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: const Icon(Icons.lyrics_rounded, color: AppTheme.accent),
                    title: const Text(
                      'Otomatik Şarkı Sözü Bulma (LRCLIB)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Şarkı çalarken senkronize (.lrc) veya düz şarkı sözlerini otomatik ara',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                    value: vm.autoFetchLyrics,
                    activeThumbColor: AppTheme.accent,
                    onChanged: (val) => vm.setAutoFetchLyrics(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Depolama, Önbellek & Kütüphane Bakımı
            _buildSectionCard(
              icon: Icons.storage_rounded,
              iconColor: Colors.amber,
              title: '🛠️ Depolama, Önbellek & Kütüphane Bakımı',
              subtitle:
                  'Geçici ses/ekolayzer önbelleğini temizleyin veya bozuk kütüphane kayıtlarını onarın',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2E2E3A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cleaning_services_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Geçici Ses & Ekolayzer Önbelleği',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kullanılan alan: ${vm.audioCacheSizeMb.toStringAsFixed(1)} MB',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isClearingCache
                              ? null
                              : () async {
                                  setState(() => _isClearingCache = true);
                                  final deleted = await vm.clearAudioCache();
                                  if (!mounted) return;
                                  setState(() => _isClearingCache = false);
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Önbellek temizlendi ($deleted geçici dosya silindi).',
                                      ),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: const Text('Önbelleği Temizle'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isRunningMaintenance
                            ? null
                            : () async {
                                setState(() => _isRunningMaintenance = true);
                                final fixedCount = await vm.runLibraryMaintenance();
                                if (!mounted) return;
                                setState(() => _isRunningMaintenance = false);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      fixedCount > 0
                                          ? 'Kütüphane bakımı tamamlandı: $fixedCount kayıt onarıldı/temizlendi.'
                                          : 'Kütüphane tarandı: Tüm şarkı kayıtları sağlıklı.',
                                    ),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              },
                        icon: _isRunningMaintenance
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.build_circle_outlined, size: 18, color: AppTheme.accent),
                        label: const Text(
                          'Kütüphaneyi Tara ve Onar (Eksik Dosya & Karakter Onarımı)',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          vm.clearRecentHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dinleme geçmişi temizlendi.'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
                        label: const Text('Dinleme Geçmişini Temizle'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error.withAlpha(120)),
                        ),
                        onPressed: () async {
                          await vm.resetAllSettingsToDefault();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tüm ayarlar varsayılan değerlere döndürüldü.'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_backup_restore_rounded, size: 18, color: AppTheme.error),
                        label: const Text('Tüm Ayarları Varsayılana Döndür'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. Motor Durumu & Klavye Kısayolları
            _buildSectionCard(
              icon: Icons.bolt_rounded,
              iconColor: AppTheme.success,
              title: '⚡ Motor Durumu & Klavye Kısayolları',
              subtitle: 'Yerel ses/indirme motorlarının durumu ve hızlı klavye kontrolleri',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEngineStatusTile(
                          title: 'FFmpeg Ses Motoru',
                          subtitle: '5-Bant Ekolayzer & Ses Dönüştürme',
                          isAvailable: vm.isFfmpegAvailable,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildEngineStatusTile(
                          title: 'yt-dlp İndirme Motoru',
                          subtitle: 'Yüksek Hızlı YouTube & Playlist İndirici',
                          isAvailable: vm.isYtDlpAvailable,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Klavye Kısayolları Referansı',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _ShortcutBadge(keyLabel: 'Space', description: 'Oynat / Duraklat'),
                      _ShortcutBadge(keyLabel: '← / →', description: '5 sn Geri / İleri'),
                      _ShortcutBadge(keyLabel: '↑ / ↓', description: 'Ses Seviyesi'),
                      _ShortcutBadge(keyLabel: 'M', description: 'Sessize Al'),
                      _ShortcutBadge(keyLabel: 'N / P', description: 'Sonraki / Önceki'),
                      _ShortcutBadge(keyLabel: 'S / R', description: 'Karıştır / Tekrar'),
                      _ShortcutBadge(keyLabel: 'Q', description: 'Çalma Sırası'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282834), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF24242E), height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildEngineStatusTile({
    required String title,
    required String subtitle,
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppTheme.success.withAlpha(80) : AppTheme.error.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isAvailable ? AppTheme.success : AppTheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.success.withAlpha(35) : AppTheme.error.withAlpha(35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAvailable ? 'Aktif' : 'Bulunamadı',
              style: TextStyle(
                color: isAvailable ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  final String keyLabel;
  final String description;

  const _ShortcutBadge({
    required this.keyLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E2E3A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              keyLabel,
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Consolas',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

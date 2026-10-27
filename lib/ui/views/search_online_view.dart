import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/playlist.dart';
import '../../models/download_item.dart';
import '../../services/online_music_service.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';

class SearchOnlineView extends StatefulWidget {
  final void Function(Playlist playlist)? onNavigateToPlaylist;

  const SearchOnlineView({
    super.key,
    this.onNavigateToPlaylist,
  });

  @override
  State<SearchOnlineView> createState() => _SearchOnlineViewState();
}

class _SearchOnlineViewState extends State<SearchOnlineView> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _dirController = TextEditingController();
  bool _hasStarted = false;

  AudioDownloadFormat _selectedFormat = AudioDownloadFormat.opus;
  int _selectedThreads = 8;
  int _selectedConcurrent = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PlayerViewModel>();
      _dirController.text = vm.defaultDownloadDirectory;
      setState(() {
        _selectedFormat = vm.downloadFormat;
        _selectedThreads = vm.downloadThreads;
        _selectedConcurrent = vm.concurrentDownloads;
      });
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _dirController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomFolder() async {
    final currentDir = _dirController.text.trim();
    final initial = (currentDir.isNotEmpty && Directory(currentDir).existsSync())
        ? currentDir
        : null;

    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Müziklerin İndirileceği Klasörü Seçin',
      initialDirectory: initial,
    );
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _dirController.text = selected;
      });
    }
  }

  Future<void> _openFolderInExplorer() async {
    final currentDir = _dirController.text.trim();
    if (currentDir.isNotEmpty) {
      final dir = Directory(currentDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await Process.run('explorer.exe', [dir.path]);
    }
  }

  Future<void> _startDownload(PlayerViewModel vm) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir YouTube playlist veya video bağlantısı yapıştırın.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _hasStarted = true);

    final success = await vm.downloadYouTubePlaylist(
      url,
      customDir: _dirController.text.trim(),
      format: _selectedFormat,
      threads: _selectedThreads,
      concurrentDownloads: _selectedConcurrent,
    );

    if (mounted) {
      if (success) {
        final playlist = vm.lastCreatedPlaylist;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              playlist != null
                  ? '"${playlist.name}" başarıyla indirildi ve Çalma Listelerine aktarıldı!'
                  : 'Çalma listesi başarıyla indirildi ve kütüphanenize eklendi!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );

        if (playlist != null) {
          // Navigate directly to PlaylistsView
          widget.onNavigateToPlaylist?.call(playlist);
        }
      } else if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_for_offline_rounded,
                    color: AppTheme.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YouTube Çalma Listesi İndirici',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'YouTube veya YouTube Music çalma listenizi doğrudan belirlediğiniz klasöre indirip çalma listelerinize aktarın.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Main Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YouTube Çalma Listesi veya Video Bağlantısı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.accent),
                        hintText: 'Örn: https://music.youtube.com/playlist?list=PL...',
                        suffixIcon: _urlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _urlController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),

                    const SizedBox(height: 18),

                    // Destination Folder
                    const Text(
                      'Kayıt Edilecek Klasör (Belirlediğiniz Dizin)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dirController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.folder_outlined, color: AppTheme.primaryLight),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _pickCustomFolder,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Gözat...'),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Bu klasörü Windows Gezgininde aç',
                          child: OutlinedButton.icon(
                            onPressed: _openFolderInExplorer,
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            label: const Text('Klasörü Aç'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Download Options (Format & Speed Selection)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceElevated, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 20, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text(
                                'İndirme Tercihleri & Kalite',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Row 1: Audio Format & Speed Channels
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Format Selection
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ses Kalitesi (Orijinal Akış)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<AudioDownloadFormat>(
                                      initialValue: _selectedFormat,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: AppTheme.surfaceElevated,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      dropdownColor: AppTheme.surfaceElevated,
                                      items: AudioDownloadFormat.values.map((fmt) {
                                        return DropdownMenuItem(
                                          value: fmt,
                                          child: Text(
                                            fmt.label,
                                            style: const TextStyle(fontSize: 12.5),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedFormat = val);
                                          vm.setDownloadFormat(val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Speed / Connection Threads Selection
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Parça Kanal Hızı',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int>(
                                      initialValue: _selectedThreads,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: AppTheme.surfaceElevated,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      dropdownColor: AppTheme.surfaceElevated,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 4,
                                          child: Text('Normal (4x)', style: TextStyle(fontSize: 12.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 8,
                                          child: Text('⚡ Hızlı (8x)', style: TextStyle(fontSize: 12.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 16,
                                          child: Text('🚀 Turbo (16x)', style: TextStyle(fontSize: 12.5)),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedThreads = val);
                                          vm.setDownloadThreads(val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Row 2: Draggable Slider for Concurrent Downloads (1 - 10)
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.surfaceHighlight.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.speed_rounded, size: 18, color: AppTheme.accent),
                                        SizedBox(width: 8),
                                        Text(
                                          'Eşzamanlı İndirme Hızı',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _selectedConcurrent >= 8
                                            ? Colors.deepOrange.withAlpha(40)
                                            : _selectedConcurrent >= 5
                                                ? AppTheme.accent.withAlpha(40)
                                                : AppTheme.primaryLight.withAlpha(40),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _selectedConcurrent >= 8
                                              ? Colors.deepOrangeAccent.withAlpha(140)
                                              : _selectedConcurrent >= 5
                                                  ? AppTheme.accent.withAlpha(140)
                                                  : AppTheme.primaryLight.withAlpha(90),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _selectedConcurrent >= 8
                                                ? Icons.rocket_launch_rounded
                                                : _selectedConcurrent >= 5
                                                    ? Icons.bolt_rounded
                                                    : Icons.layers_rounded,
                                            size: 15,
                                            color: _selectedConcurrent >= 8
                                                ? Colors.deepOrangeAccent
                                                : _selectedConcurrent >= 5
                                                    ? AppTheme.accent
                                                    : AppTheme.primaryLight,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$_selectedConcurrent Şarkı${_selectedConcurrent == 1 ? ' (Tekli)' : _selectedConcurrent == 10 ? ' (Maksimum Turbo)' : ' Aynı Anda'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedConcurrent >= 8
                                                  ? Colors.deepOrangeAccent
                                                  : _selectedConcurrent >= 5
                                                      ? AppTheme.accent
                                                      : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    showValueIndicator: ShowValueIndicator.never,
                                    activeTrackColor: _selectedConcurrent >= 8
                                        ? Colors.deepOrangeAccent
                                        : AppTheme.accent,
                                    inactiveTrackColor: AppTheme.surfaceHighlight,
                                    thumbColor: _selectedConcurrent >= 8
                                        ? Colors.deepOrangeAccent
                                        : AppTheme.accent,
                                    overlayColor: AppTheme.accent.withAlpha(32),
                                    trackHeight: 6,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                  ),
                                  child: Slider(
                                    value: _selectedConcurrent.toDouble(),
                                    min: 1.0,
                                    max: 10.0,
                                    divisions: 9,
                                    onChanged: (val) {
                                      final intVal = val.round();
                                      setState(() => _selectedConcurrent = intVal);
                                      vm.setConcurrentDownloads(intVal);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildPresetButton(1, '1 (Tek tek)', vm),
                                    _buildPresetButton(3, '3 (Önerilen)', vm),
                                    _buildPresetButton(5, '5 ⚡ Hızlı', vm),
                                    _buildPresetButton(8, '8 🚀 Turbo', vm),
                                    _buildPresetButton(10, '10 🔥 Maksimum', vm),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${_selectedFormat.description} • Çubuğu kaydırarak aynı anda kaç şarkının indirileceğini (1-10 arası) kolayca ayarlayabilirsiniz.',
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Download Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: vm.isDownloadingPlaylist ? null : () => _startDownload(vm),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          disabledBackgroundColor: AppTheme.surfaceElevated,
                        ),
                        icon: vm.isDownloadingPlaylist
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 22),
                        label: Text(
                          vm.isDownloadingPlaylist
                              ? 'İndiriliyor... Lütfen bekleyiniz'
                              : '⬇️  Çalma Listesini İndir ve Çalma Listelerime Ekle',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Progress & Status Card
            if (vm.isDownloadingPlaylist || _hasStarted) ...[
              Card(
                color: AppTheme.surfaceElevated,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            vm.isDownloadingPlaylist
                                ? Icons.sync
                                : vm.downloadProgress >= 1.0
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline,
                            color: vm.isDownloadingPlaylist
                                ? AppTheme.accent
                                : vm.downloadProgress >= 1.0
                                    ? AppTheme.success
                                    : AppTheme.primaryLight,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vm.downloadStatus.isNotEmpty
                                  ? vm.downloadStatus
                                  : 'İşlem bekleniyor...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (vm.downloadTotal > 0 && vm.isDownloadingPlaylist)
                            Text(
                              '%${(vm.downloadProgress * 100).toInt()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: vm.downloadProgress > 0 ? vm.downloadProgress : null,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceHighlight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                        ),
                      ),
                      if (vm.downloadItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // KPI Summary Badges
                        Builder(
                          builder: (context) {
                            final activeItems = vm.downloadItems.where((i) => i.status == DownloadItemStatus.downloading).toList();
                            final completedItems = vm.downloadItems.where((i) => i.status == DownloadItemStatus.completed).toList();
                            final queuedItems = vm.downloadItems.where((i) => i.status == DownloadItemStatus.queued).toList();
                            final failedItems = vm.downloadItems.where((i) => i.status == DownloadItemStatus.failed).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildStatusPill(
                                      icon: Icons.bolt_rounded,
                                      label: '${activeItems.length} Aktif İndiriliyor (Aynı Anda)',
                                      color: AppTheme.accent,
                                      isActive: activeItems.isNotEmpty,
                                    ),
                                    _buildStatusPill(
                                      icon: Icons.check_circle_rounded,
                                      label: '${completedItems.length} Tamamlandı',
                                      color: AppTheme.success,
                                      isActive: completedItems.isNotEmpty,
                                    ),
                                    if (queuedItems.isNotEmpty)
                                      _buildStatusPill(
                                        icon: Icons.hourglass_empty_rounded,
                                        label: '${queuedItems.length} Sırada',
                                        color: AppTheme.textMuted,
                                        isActive: false,
                                      ),
                                    if (failedItems.isNotEmpty)
                                      InkWell(
                                        onTap: () => _showFailedItemsModal(context, vm, failedItems),
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildStatusPill(
                                          icon: Icons.error_outline_rounded,
                                          label: '${failedItems.length} Başarısız (Sebepleri Gör)',
                                          color: AppTheme.error,
                                          isActive: true,
                                        ),
                                      ),
                                  ],
                                ),
                                if (failedItems.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.error.withAlpha(80), width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.error),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${failedItems.length} Parça YouTube Kısıtlamaları Nedeniyle İndirilemedi',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.error,
                                                ),
                                              ),
                                            ),
                                            if (!vm.isDownloadingPlaylist)
                                              ElevatedButton.icon(
                                                onPressed: () => vm.retryAllFailedDownloads(),
                                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                                label: const Text(
                                                  'Tümünü Tekrar Dene',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...failedItems.map((item) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceElevated,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.error.withAlpha(60), width: 1),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.error.withAlpha(30),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '#${item.index}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.error,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.title,
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppTheme.textPrimary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFFF8B8B)),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              item.errorMessage ?? 'İndirme tamamlanamadı.',
                                                              style: const TextStyle(
                                                                fontFamily: 'Consolas',
                                                                fontSize: 10.5,
                                                                color: Color(0xFFFF8B8B),
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              maxLines: 3,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                 IconButton(
                                                   icon: const Icon(Icons.terminal_rounded, size: 16, color: Colors.white70),
                                                   tooltip: 'Ham Terminal Logunu Gör',
                                                   onPressed: () => _showRawLogModal(context, item),
                                                   splashRadius: 16,
                                                   padding: EdgeInsets.zero,
                                                   constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                 ),
                                                 IconButton(
                                                   icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.accent),
                                                   tooltip: 'Bu Parçayı Tekrar Dene',
                                                   onPressed: vm.isDownloadingPlaylist ? null : () => vm.retryDownloadItem(item),
                                                   splashRadius: 16,
                                                   padding: EdgeInsets.zero,
                                                   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                 ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                                if (activeItems.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  // Active Concurrent Downloads Container
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withAlpha(15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.accent.withAlpha(60), width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.downloading_rounded, size: 16, color: AppTheme.accent),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Şu Anda Aynı Anda İndirilen Parçalar (${activeItems.length} / $_selectedConcurrent Slot Aktif)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...activeItems.map((item) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceElevated,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.accent.withAlpha(80), width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accent.withAlpha(30),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '#${item.index}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.accent,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppTheme.accent,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accent.withAlpha(25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    '⚡ İndiriliyor',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.accent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                // Complete Playlist Queue Table
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHighlight.withAlpha(40),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.surfaceHighlight.withAlpha(80), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Tüm Çalma Listesi Sıralaması',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              '${completedItems.length} / ${vm.downloadItems.length} Parça Tamamlandı',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1, color: Color(0xFF252535)),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 220),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          itemCount: vm.downloadItems.length,
                                          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFF252535)),
                                          itemBuilder: (context, idx) {
                                            final item = vm.downloadItems[idx];
                                            final isDone = item.status == DownloadItemStatus.completed;
                                            final isDownloading = item.status == DownloadItemStatus.downloading;
                                            final isFailed = item.status == DownloadItemStatus.failed;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 28,
                                                    child: Text(
                                                      '#${item.index}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDownloading
                                                            ? AppTheme.accent
                                                            : isDone
                                                                ? AppTheme.success
                                                                : AppTheme.textMuted,
                                                        fontWeight: isDownloading ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    isDone
                                                        ? Icons.check_circle_rounded
                                                        : isDownloading
                                                            ? Icons.downloading_rounded
                                                            : isFailed
                                                                ? Icons.error_outline_rounded
                                                                : Icons.schedule_rounded,
                                                    size: 16,
                                                    color: isDone
                                                        ? AppTheme.success
                                                        : isDownloading
                                                            ? AppTheme.accent
                                                            : isFailed
                                                                ? AppTheme.error
                                                                : AppTheme.textMuted,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          item.title,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: isDownloading ? FontWeight.bold : FontWeight.normal,
                                                            color: isDownloading
                                                                ? AppTheme.textPrimary
                                                                : isDone
                                                                    ? AppTheme.textSecondary
                                                                    : isFailed
                                                                        ? AppTheme.textPrimary
                                                                        : AppTheme.textMuted,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (isFailed && item.errorMessage != null)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 2),
                                                            child: Text(
                                                              'Sebep: ${item.errorMessage!}',
                                                              style: const TextStyle(
                                                                fontSize: 10.5,
                                                                color: Color(0xFFFF8B8B),
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (isFailed)
                                                    IconButton(
                                                      icon: const Icon(Icons.terminal_rounded, size: 15, color: Colors.white70),
                                                      tooltip: 'Ham Terminal Logunu Gör',
                                                      onPressed: () => _showRawLogModal(context, item),
                                                      splashRadius: 14,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    ),
                                                  if (isFailed && !vm.isDownloadingPlaylist)
                                                    IconButton(
                                                      icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.accent),
                                                      tooltip: 'Tekrar Dene',
                                                      onPressed: () => vm.retryDownloadItem(item),
                                                      splashRadius: 14,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDone
                                                          ? AppTheme.success.withAlpha(20)
                                                          : isDownloading
                                                              ? AppTheme.accent.withAlpha(20)
                                                              : isFailed
                                                                  ? AppTheme.error.withAlpha(20)
                                                                  : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      isDone
                                                          ? 'Tamamlandı'
                                                          : isDownloading
                                                              ? 'İndiriliyor...'
                                                              : isFailed
                                                                  ? 'Başarısız'
                                                                  : 'Sırada',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: isDownloading ? FontWeight.bold : FontWeight.normal,
                                                        color: isDone
                                                            ? AppTheme.success
                                                            : isDownloading
                                                                ? AppTheme.accent
                                                                : isFailed
                                                                    ? AppTheme.error
                                                                    : AppTheme.textMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      if (!vm.isDownloadingPlaylist && vm.lastCreatedPlaylist != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                widget.onNavigateToPlaylist?.call(vm.lastCreatedPlaylist!);
                              },
                              icon: const Icon(Icons.playlist_play_rounded, size: 20),
                              label: Text('"${vm.lastCreatedPlaylist!.name}" Listesine Git'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                vm.playPlaylist(vm.lastCreatedPlaylist!);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text('Hemen Çal'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Informational Feature Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface.withAlpha(160),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E2E3A), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt_rounded, color: AppTheme.primaryLight, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Otomatik Kütüphane & Çalma Listesi Senkronizasyonu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'İndirilen tüm parçalar seçtiğiniz formatta cihazınıza kaydedilir. Şarkılar kütüphanenize eklenir ve aynı isimle otomatik bir çalma listesi oluşturulur. İndirme bittiğinde doğrudan "Çalma Listeleri" bölümünden dinleyebilirsiniz.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(int value, String label, PlayerViewModel vm) {
    final isSelected = (_selectedConcurrent == value);
    return InkWell(
      onTap: () {
        setState(() => _selectedConcurrent = value);
        vm.setConcurrentDownloads(value);
      },
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (value >= 8
                  ? Colors.deepOrangeAccent.withAlpha(50)
                  : AppTheme.accent.withAlpha(50))
              : AppTheme.surfaceHighlight.withAlpha(40),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (value >= 8 ? Colors.deepOrangeAccent : AppTheme.accent)
                : AppTheme.surfaceHighlight.withAlpha(100),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (value >= 8 ? Colors.deepOrangeAccent : AppTheme.accent)
                : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isActive ? 35 : 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(isActive ? 120 : 60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFailedItemsModal(
    BuildContext context,
    PlayerViewModel vm,
    List<DownloadItemProgress> failedItems,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${failedItems.length} Başarısız Parça ve Hata Nedenleri',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aşağıdaki parçalar YouTube kısıtlamaları (telif engeli, kaldırılmış/gizli video veya oturum şartı) sebebiyle indirilemedi:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: failedItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = failedItems[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.error.withAlpha(60)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${item.index}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.error),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.terminal_rounded, size: 18, color: Colors.white70),
                                  tooltip: 'Ham Terminal Logunu Gör',
                                  onPressed: () => _showRawLogModal(context, item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.accent),
                                  tooltip: 'Tekrar Dene',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    vm.retryDownloadItem(item);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFFF7E7E)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.errorMessage ?? 'İndirme tamamlanamadı.',
                                    style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Color(0xFFFF7E7E), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'YouTube ID: ${item.id} • https://www.youtube.com/watch?v=${item.id}',
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!vm.isDownloadingPlaylist)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  vm.retryAllFailedDownloads();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tümünü Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void _showRawLogModal(BuildContext context, DownloadItemProgress item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1D28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.terminal_rounded, color: AppTheme.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terminal Logu: ${item.title}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF331515),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF662222)),
                    ),
                    child: SelectableText(
                      'Hata Satırı: ${item.errorMessage!}',
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8B8B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text(
                  'Ham yt-dlp & Sistem Çıktısı (stderr & stdout):',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1017),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        (item.rawLog != null && item.rawLog!.trim().isNotEmpty)
                            ? item.rawLog!
                            : (item.errorMessage ?? 'Ek terminal logu bulunamadı.'),
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 11,
                          color: Color(0xFFCCCCCC),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Tüm Logu Kopyala'),
              onPressed: () {
                final textToCopy = (item.rawLog != null && item.rawLog!.trim().isNotEmpty)
                    ? item.rawLog!
                    : (item.errorMessage ?? '');
                Clipboard.setData(ClipboardData(text: textToCopy));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Log panoya kopyalandı.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        );
      },
    );
  }
}

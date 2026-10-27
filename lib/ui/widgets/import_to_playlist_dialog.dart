import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../services/file_picker_service.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';

class ImportFilesToPlaylistDialog extends StatefulWidget {
  final List<Track> tracks;
  final void Function(Playlist playlist)? onPlaylistCreatedOrUpdated;

  const ImportFilesToPlaylistDialog({
    super.key,
    required this.tracks,
    this.onPlaylistCreatedOrUpdated,
  });

  /// Launch the entire import-to-playlist flow from anywhere
  static Future<void> startImportFlow({
    required BuildContext context,
    required PlayerViewModel vm,
    void Function(Playlist playlist)? onNavigateToPlaylist,
  }) async {
    final tracks = await vm.pickAudioFiles();
    if (tracks.isEmpty || !context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => ImportFilesToPlaylistDialog(
        tracks: tracks,
        onPlaylistCreatedOrUpdated: onNavigateToPlaylist,
      ),
    );
  }

  @override
  State<ImportFilesToPlaylistDialog> createState() => _ImportFilesToPlaylistDialogState();
}

class _ImportFilesToPlaylistDialogState extends State<ImportFilesToPlaylistDialog> {
  late final TextEditingController _nameController;
  bool _createNew = true;
  String? _selectedPlaylistId;

  @override
  void initState() {
    super.initState();
    final defaultName = FilePickerService.suggestPlaylistName(widget.tracks);
    _nameController = TextEditingController(text: defaultName);

    final vm = context.read<PlayerViewModel>();
    if (vm.playlists.isNotEmpty) {
      _selectedPlaylistId = vm.playlists.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(PlayerViewModel vm) async {
    Playlist targetPlaylist;

    if (_createNew || vm.playlists.isEmpty) {
      final name = _nameController.text.trim();
      final finalName = name.isNotEmpty ? name : 'İçe Aktarılan Müzikler';
      targetPlaylist = await vm.createPlaylistWithTracks(finalName, widget.tracks);
    } else {
      final plId = _selectedPlaylistId ?? vm.playlists.first.id;
      await vm.addTracksToPlaylist(plId, widget.tracks);
      targetPlaylist = vm.playlists.firstWhere((p) => p.id == plId);
    }

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${targetPlaylist.name}" çalma listesine ${widget.tracks.length} şarkı eklendi.'),
          backgroundColor: AppTheme.success,
          action: SnackBarAction(
            label: 'Listeyi Gör',
            textColor: Colors.white,
            onPressed: () {
              widget.onPlaylistCreatedOrUpdated?.call(targetPlaylist);
            },
          ),
        ),
      );

      widget.onPlaylistCreatedOrUpdated?.call(targetPlaylist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final hasExistingPlaylists = vm.playlists.isNotEmpty;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.playlist_add_rounded, color: AppTheme.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${widget.tracks.length} Şarkıyı Çalma Listesine Ekle',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçtiğiniz ${widget.tracks.length} yerel müzik dosyası doğrudan "Çalma Listeleri" bölümüne aktarılacaktır.',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            if (hasExistingPlaylists) ...[
              // Option toggle: New vs Existing
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Yeni Liste Oluştur')),
                      selected: _createNew,
                      onSelected: (val) => setState(() => _createNew = true),
                      selectedColor: AppTheme.primary.withAlpha(50),
                      labelStyle: TextStyle(
                        fontWeight: _createNew ? FontWeight.bold : FontWeight.normal,
                        color: _createNew ? AppTheme.primaryLight : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Mevcut Listeye Ekle')),
                      selected: !_createNew,
                      onSelected: (val) => setState(() => _createNew = false),
                      selectedColor: AppTheme.primary.withAlpha(50),
                      labelStyle: TextStyle(
                        fontWeight: !_createNew ? FontWeight.bold : FontWeight.normal,
                        color: !_createNew ? AppTheme.primaryLight : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (_createNew || !hasExistingPlaylists) ...[
              TextField(
                controller: _nameController,
                autofocus: true,
                onSubmitted: (_) => _submit(vm),
                decoration: const InputDecoration(
                  labelText: 'Çalma Listesi Adı',
                  hintText: 'Örn: Sevilen Parçalar, Rock, Araba Müzikleri...',
                  prefixIcon: Icon(Icons.edit_outlined, size: 18),
                ),
              ),
            ] else ...[
              // Dropdown for existing playlists
              DropdownButtonFormField<String>(
                initialValue: _selectedPlaylistId ?? vm.playlists.first.id,
                decoration: const InputDecoration(
                  labelText: 'Hedef Çalma Listesi',
                  prefixIcon: Icon(Icons.queue_music_rounded, size: 18),
                ),
                dropdownColor: AppTheme.surfaceElevated,
                items: vm.playlists.map((pl) {
                  return DropdownMenuItem<String>(
                    value: pl.id,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pl.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '(${pl.tracks.length} parça)',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPlaylistId = val);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: () => _submit(vm),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(_createNew || !hasExistingPlaylists ? 'Liste Oluştur ve Ekle' : 'Listeye Ekle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

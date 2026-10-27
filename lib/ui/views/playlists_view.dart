import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/track_list_item.dart';

class PlaylistsView extends StatefulWidget {
  final String? initialPlaylistId;
  final VoidCallback? onPlaylistClosed;

  const PlaylistsView({
    super.key,
    this.initialPlaylistId,
    this.onPlaylistClosed,
  });

  @override
  State<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<PlaylistsView> {
  Playlist? _selectedPlaylist;
  final TextEditingController _detailSearchController = TextEditingController();
  String _detailSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkInitialPlaylist();
  }

  @override
  void dispose() {
    _detailSearchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PlaylistsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPlaylistId != oldWidget.initialPlaylistId && widget.initialPlaylistId != null) {
      _checkInitialPlaylist();
    }
  }

  void _checkInitialPlaylist() {
    if (widget.initialPlaylistId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final vm = context.read<PlayerViewModel>();
        final match = vm.playlists.where((p) => p.id == widget.initialPlaylistId);
        if (match.isNotEmpty) {
          setState(() {
            _selectedPlaylist = match.first;
            _detailSearchController.clear();
            _detailSearchQuery = '';
          });
        }
      });
    }
  }

  String _formatTotalDuration(List<Track> tracks) {
    int totalSeconds = 0;
    for (final t in tracks) {
      totalSeconds += t.duration.inSeconds;
    }
    if (totalSeconds <= 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return ' • $hours sa $minutes dk';
    }
    return ' • $minutes dk';
  }

  void _showCreatePlaylistDialog(BuildContext context, PlayerViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Çalma Listesi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Liste adı (ör: Yolculuk Müzikleri)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await vm.createPlaylist(name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, PlayerViewModel vm, Playlist pl) {
    final controller = TextEditingController(text: pl.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çalma Listesini Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Yeni liste adı',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await vm.renamePlaylist(pl.id, name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    // If a playlist is selected, show its detail view
    if (_selectedPlaylist != null) {
      final match = vm.playlists.where((p) => p.id == _selectedPlaylist!.id);
      if (match.isEmpty) {
        _selectedPlaylist = null;
      } else {
        return _buildPlaylistDetail(context, vm, match.first);
      }
    }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Çalma Listelerim',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vm.playlists.length} Çalma Listesi',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!kIsWeb) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final imported = await vm.importPlaylistFromM3U();
                      if (context.mounted && imported != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${imported.name}" (${imported.tracks.length} şarkı) içe aktarıldı.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_open_outlined, size: 18, color: AppTheme.accent),
                    label: const Text('M3U İçe Aktar'),
                  ),
                  const SizedBox(width: 10),
                ],
                ElevatedButton.icon(
                  onPressed: () => _showCreatePlaylistDialog(context, vm),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Yeni Liste Oluştur'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Content Grid or Empty
            Expanded(
              child: vm.playlists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.playlist_add_rounded,
                              color: AppTheme.primaryLight,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz bir çalma listeniz yok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Şarkılarınızı kategorilere ayırmak için yeni bir liste oluşturun veya M3U dosyası içe aktarın.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showCreatePlaylistDialog(context, vm),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Liste Oluştur'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: vm.playlists.length,
                      itemBuilder: (context, index) {
                        final pl = vm.playlists[index];
                        return _buildPlaylistCard(context, vm, pl);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, PlayerViewModel vm, Playlist pl) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() {
          _selectedPlaylist = pl;
          _detailSearchController.clear();
          _detailSearchQuery = '';
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B2A63), Color(0xFF1E1E2A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: AppTheme.primaryLight,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pl.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                    onSelected: (val) async {
                      if (val == 'rename') {
                        _showRenamePlaylistDialog(context, vm, pl);
                      } else if (val == 'export') {
                        final savedPath = await vm.exportPlaylistAsM3U(pl);
                        if (context.mounted && savedPath != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('M3U8 dışa aktarıldı: $savedPath'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } else if (val == 'delete') {
                        vm.deletePlaylist(pl.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Adını Değiştir'),
                          ],
                        ),
                      ),
                      if (!kIsWeb)
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.save_alt_rounded, size: 16, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text('M3U8 Olarak Dışa Aktar'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('Listeyi Sil', style: TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${pl.tracks.length} Şarkı${_formatTotalDuration(pl.tracks)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistDetail(BuildContext context, PlayerViewModel vm, Playlist pl) {
    final filtered = pl.tracks.where((t) {
      if (_detailSearchQuery.isEmpty) return true;
      final q = _detailSearchQuery.toLowerCase();
      return t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button & Playlist Info
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Listelere Dön',
                  onPressed: () {
                    setState(() => _selectedPlaylist = null);
                    widget.onPlaylistClosed?.call();
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              pl.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                            tooltip: 'Liste Adını Düzenle',
                            onPressed: () => _showRenamePlaylistDialog(context, vm, pl),
                          ),
                        ],
                      ),
                      Text(
                        '${pl.tracks.length} Şarkı${_formatTotalDuration(pl.tracks)}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!kIsWeb && pl.tracks.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final savedPath = await vm.exportPlaylistAsM3U(pl);
                      if (context.mounted && savedPath != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('M3U8 dışa aktarıldı: $savedPath'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_alt_rounded, size: 18, color: AppTheme.accent),
                    label: const Text('M3U Dışa Aktar'),
                  ),
                  const SizedBox(width: 10),
                ],
                if (pl.tracks.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      vm.playTrack(pl.tracks.first, newQueue: pl.tracks);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Tümünü Çal'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Search inside playlist
            if (pl.tracks.length > 3) ...[
              TextField(
                controller: _detailSearchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  hintText: 'Bu çalma listesinde ara...',
                  suffixIcon: _detailSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _detailSearchController.clear();
                            setState(() => _detailSearchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _detailSearchQuery = val.trim()),
              ),
              const SizedBox(height: 14),
            ],

            // Track list
            Expanded(
              child: pl.tracks.isEmpty
                  ? const Center(
                      child: Text(
                        'Bu çalma listesinde henüz şarkı yok.\nKütüphaneden veya arama sonuçlarından şarkı ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final track = filtered[index];
                        return TrackListItem(
                          track: track,
                          index: index,
                          queueContext: filtered,
                          removeLabel: 'Bu Listeden Çıkar',
                          onCustomRemove: () {
                            vm.removeTrackFromPlaylist(pl.id, track);
                          },
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/track_list_item.dart';
import '../widgets/import_to_playlist_dialog.dart';

enum LibrarySortMode {
  addedNewest,
  titleAsc,
  titleDesc,
  artistAsc,
  mostPlayed,
  durationDesc,
}

enum LibraryTabMode {
  allTracks,
  artists,
  albums,
  mostPlayed,
}

class LibraryView extends StatefulWidget {
  final void Function(String playlistId)? onNavigateToPlaylist;

  const LibraryView({
    super.key,
    this.onNavigateToPlaylist,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';
  LibrarySortMode _sortMode = LibrarySortMode.addedNewest;
  LibraryTabMode _tabMode = LibraryTabMode.allTracks;
  String? _selectedGroupKey; // Selected Artist or Album name when drilling down

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Track> _getSortedTracks(List<Track> source) {
    final list = List<Track>.from(source);
    switch (_sortMode) {
      case LibrarySortMode.addedNewest:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case LibrarySortMode.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LibrarySortMode.titleDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case LibrarySortMode.artistAsc:
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case LibrarySortMode.mostPlayed:
        list.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case LibrarySortMode.durationDesc:
        list.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    final filteredBase = vm.localTracks.where((track) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return track.title.toLowerCase().contains(q) ||
          track.artist.toLowerCase().contains(q) ||
          (track.album?.toLowerCase().contains(q) ?? false);
    }).toList();

    final sortedTracks = _getSortedTracks(filteredBase);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Primary Actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yerel Kütüphanem',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vm.localTracks.length} Şarkı kayıtlı',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Play all button
                if (sortedTracks.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      vm.playTrack(sortedTracks.first, newQueue: sortedTracks);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Hepsini Çal'),
                  ),
                  const SizedBox(width: 10),
                ],
                // Scan Folder Button
                if (!kIsWeb) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final count = await vm.pickLocalFolder();
                      if (context.mounted && count > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Klasörden $count yeni ses dosyası kütüphaneye eklendi.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18, color: AppTheme.accent),
                    label: const Text('Klasör Tara'),
                  ),
                  const SizedBox(width: 10),
                ],
                // Add music files directly to playlist button
                OutlinedButton.icon(
                  onPressed: () async {
                    await ImportFilesToPlaylistDialog.startImportFlow(
                      context: context,
                      vm: vm,
                      onNavigateToPlaylist: (pl) {
                        widget.onNavigateToPlaylist?.call(pl.id);
                      },
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Müzik Dosyası Ekle'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category Tabs & Sort Bar
            if (vm.localTracks.isNotEmpty) ...[
              Row(
                children: [
                  _buildTabChip('Tüm Şarkılar', Icons.music_note_rounded, LibraryTabMode.allTracks),
                  const SizedBox(width: 8),
                  _buildTabChip('Sanatçılar', Icons.person_rounded, LibraryTabMode.artists),
                  const SizedBox(width: 8),
                  _buildTabChip('Albüm & Klasörler', Icons.album_rounded, LibraryTabMode.albums),
                  const SizedBox(width: 8),
                  _buildTabChip('En Çok Dinlenenler', Icons.trending_up_rounded, LibraryTabMode.mostPlayed),
                  const Spacer(),

                  // Sort Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E2E3A)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<LibrarySortMode>(
                        value: _sortMode,
                        isDense: true,
                        dropdownColor: AppTheme.surfaceElevated,
                        icon: const Icon(Icons.sort_rounded, size: 18, color: AppTheme.primaryLight),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
                        items: const [
                          DropdownMenuItem(
                            value: LibrarySortMode.addedNewest,
                            child: Text('Sırala: Son Eklenenler'),
                          ),
                          DropdownMenuItem(
                            value: LibrarySortMode.titleAsc,
                            child: Text('Sırala: Başlık (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: LibrarySortMode.titleDesc,
                            child: Text('Sırala: Başlık (Z-A)'),
                          ),
                          DropdownMenuItem(
                            value: LibrarySortMode.artistAsc,
                            child: Text('Sırala: Sanatçı (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: LibrarySortMode.mostPlayed,
                            child: Text('Sırala: En Çok Dinlenenler'),
                          ),
                          DropdownMenuItem(
                            value: LibrarySortMode.durationDesc,
                            child: Text('Sırala: Süre'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            setState(() => _sortMode = mode);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search filter field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  hintText: 'Kütüphanede ara (şarkı, sanatçı veya albüm)...',
                  suffixIcon: _searchFilter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchFilter = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() => _searchFilter = val.trim());
                },
              ),
              const SizedBox(height: 14),
            ],

            // Content list or Empty State
            Expanded(
              child: vm.localTracks.isEmpty
                  ? _buildEmptyState(context, vm)
                  : _buildTabContent(context, vm, sortedTracks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, IconData icon, LibraryTabMode mode) {
    final isSelected = _tabMode == mode;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
      ),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: isSelected,
      selectedColor: AppTheme.primary.withAlpha(55),
      backgroundColor: AppTheme.surfaceElevated,
      onSelected: (_) {
        setState(() {
          _tabMode = mode;
          _selectedGroupKey = null;
        });
      },
    );
  }

  Widget _buildTabContent(BuildContext context, PlayerViewModel vm, List<Track> sortedTracks) {
    if (sortedTracks.isEmpty) {
      return const Center(
        child: Text(
          'Aramanızla eşleşen şarkı bulunamadı.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    if (_tabMode == LibraryTabMode.mostPlayed) {
      final mostPlayed = List<Track>.from(sortedTracks)
        ..sort((a, b) => b.playCount.compareTo(a.playCount));
      return ListView.separated(
        itemCount: mostPlayed.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final track = mostPlayed[index];
          return TrackListItem(
            track: track,
            index: index,
            queueContext: mostPlayed,
          );
        },
      );
    }

    if (_tabMode == LibraryTabMode.artists || _tabMode == LibraryTabMode.albums) {
      final isArtistMode = _tabMode == LibraryTabMode.artists;

      // Group tracks
      final Map<String, List<Track>> groups = {};
      for (final t in sortedTracks) {
        final key = isArtistMode
            ? (t.artist.trim().isNotEmpty ? t.artist.trim() : 'Bilinmeyen Sanatçı')
            : (t.album != null && t.album!.trim().isNotEmpty ? t.album!.trim() : 'Genel Klasör');
        groups.putIfAbsent(key, () => []).add(t);
      }

      if (_selectedGroupKey != null && groups.containsKey(_selectedGroupKey)) {
        final groupTracks = groups[_selectedGroupKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedGroupKey = null),
                ),
                const SizedBox(width: 8),
                Icon(
                  isArtistMode ? Icons.person_rounded : Icons.album_rounded,
                  color: AppTheme.primaryLight,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_selectedGroupKey (${groupTracks.length} Şarkı)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => vm.playTrack(groupTracks.first, newQueue: groupTracks),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Grubu Çal'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: groupTracks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) => TrackListItem(
                  track: groupTracks[index],
                  index: index,
                  queueContext: groupTracks,
                ),
              ),
            ),
          ],
        );
      }

      final sortedKeys = groups.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.35,
        ),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final items = groups[key]!;
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedGroupKey = key),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isArtistMode ? Icons.person_rounded : Icons.folder_special_rounded,
                            color: AppTheme.primaryLight,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primary, size: 30),
                          tooltip: 'Hemen Çal',
                          onPressed: () => vm.playTrack(items.first, newQueue: items),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${items.length} Şarkı',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Default: All Tracks
    return ListView.separated(
      itemCount: sortedTracks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final track = sortedTracks[index];
        return TrackListItem(
          track: track,
          index: index,
          queueContext: sortedTracks,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, PlayerViewModel vm) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E3C), width: 1),
        ),
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
                Icons.library_music_rounded,
                color: AppTheme.primaryLight,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kütüphaneniz Henüz Boş',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bilgisayarınızdaki müzik dosyalarını (MP3, WAV, FLAC, M4A) veya tüm bir müzik klasörünü tek tıkla ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await ImportFilesToPlaylistDialog.startImportFlow(
                      context: context,
                      vm: vm,
                      onNavigateToPlaylist: (pl) {
                        widget.onNavigateToPlaylist?.call(pl.id);
                      },
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Müzik Dosyası Ekle'),
                ),
                if (!kIsWeb)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await vm.pickLocalFolder();
                    },
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: const Text('Klasör Tara'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/playlist.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/player_bottom_bar.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/sidebar_navigation.dart';
import 'library_view.dart';
import 'search_online_view.dart';
import 'favorites_view.dart';
import 'playlists_view.dart';
import 'history_view.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  String? _selectedPlaylistId;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _navigateToPlaylistById(String playlistId) {
    setState(() {
      _selectedPlaylistId = playlistId;
      _selectedIndex = 3;
    });
  }

  void _navigateToPlaylist(Playlist playlist) {
    _navigateToPlaylistById(playlist.id);
  }

  bool _isTypingInTextField() {
    final primaryContext = FocusManager.instance.primaryFocus?.context;
    if (primaryContext == null) return false;
    if (primaryContext.widget is EditableText) return true;
    return primaryContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isTypingInTextField()) return KeyEventResult.ignored;

    final vm = context.read<PlayerViewModel>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space) {
      vm.togglePlayPause();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      vm.seekRelative(const Duration(seconds: 5));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      vm.seekRelative(const Duration(seconds: -5));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      vm.setVolume(vm.volume + 0.05);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      vm.setVolume(vm.volume - 0.05);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyM) {
      vm.toggleMute();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyN) {
      vm.next();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyP) {
      vm.previous();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyS) {
      vm.toggleShuffle();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyR) {
      vm.toggleRepeatMode();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyQ) {
      showDialog(
        context: context,
        builder: (_) => const QueueDialog(),
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildMiniPlayerView(BuildContext context, PlayerViewModel vm) {
    final track = vm.currentTrack;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Track Info & Exit Mini Player
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 42,
                    height: 42,
                    color: AppTheme.surfaceElevated,
                    child: track != null && track.thumbnailUrl != null
                        ? Image.network(
                            track.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.music_note, color: AppTheme.primaryLight),
                          )
                        : const Icon(Icons.music_note, color: AppTheme.primaryLight),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track?.title ?? 'Çalınan şarkı yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        track?.artist ?? 'Antigravity Mini Player',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                AudioVisualizer(isPlaying: vm.isPlaying, barCount: 4, maxHeight: 14),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, size: 18, color: AppTheme.accent),
                  tooltip: 'Tam Pencereye Dön',
                  onPressed: vm.toggleMiniPlayerMode,
                ),
              ],
            ),

            // Seekbar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: vm.totalDuration.inMilliseconds > 0
                    ? (vm.currentPosition.inMilliseconds / vm.totalDuration.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (val) {
                  if (vm.totalDuration.inMilliseconds > 0) {
                    vm.seek(Duration(milliseconds: (val * vm.totalDuration.inMilliseconds).toInt()));
                  }
                },
              ),
            ),

            // Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 24),
                  onPressed: vm.previous,
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: vm.togglePlayPause,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                    child: Icon(
                      vm.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 24),
                  onPressed: vm.next,
                ),
                if (track != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      vm.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: vm.isFavorite(track) ? AppTheme.error : AppTheme.textMuted,
                    ),
                    onPressed: () => vm.toggleFavorite(track),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    if (vm.isMiniPlayer) {
      return Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: _buildMiniPlayerView(context, vm),
      );
    }

    // Error snackbar listener if errorMessage is set
    if (vm.errorMessage != null) {
      final msg = vm.errorMessage!;
      vm.clearErrorMessage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.error,
          ),
        );
      });
    }

    final isWideScreen = MediaQuery.of(context).size.width >= 720;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Desktop Sidebar Navigation
                  if (isWideScreen)
                    SidebarNavigation(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      onNavigateToPlaylist: _navigateToPlaylistById,
                    ),

                  // Main Views Stack
                  Expanded(
                    child: Container(
                      color: AppTheme.background,
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          LibraryView(
                            onNavigateToPlaylist: _navigateToPlaylistById,
                          ),
                          SearchOnlineView(
                            onNavigateToPlaylist: _navigateToPlaylist,
                          ),
                          const FavoritesView(),
                          PlaylistsView(
                            initialPlaylistId: _selectedPlaylistId,
                            onPlaylistClosed: () => setState(() => _selectedPlaylistId = null),
                          ),
                          const HistoryView(),
                          const SettingsView(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pinned Bottom Player Bar
            const PlayerBottomBar(),
          ],
        ),
        // Drawer / BottomNavigationBar for narrow screens
        bottomNavigationBar: !isWideScreen
            ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                backgroundColor: AppTheme.surface,
                selectedItemColor: AppTheme.primaryLight,
                unselectedItemColor: AppTheme.textMuted,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music),
                    label: 'Kütüphanem',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.download_for_offline_rounded),
                    label: 'İndirici',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Favoriler',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.playlist_play),
                    label: 'Listeler',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Geçmiş',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Ayarlar',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

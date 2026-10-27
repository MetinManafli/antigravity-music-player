import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';
import 'audio_effects_dialog.dart';
import 'import_to_playlist_dialog.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final void Function(String playlistId)? onNavigateToPlaylist;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onNavigateToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(color: Color(0xFF24242E), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header / Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(90),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Antigravity',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'Music Player',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
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

          const Divider(color: Color(0xFF24242E), height: 1),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildNavItem(
                  icon: Icons.library_music_rounded,
                  label: 'Kütüphanem',
                  badgeText: '${vm.localTracks.length}',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.cloud_download_rounded,
                  label: 'YouTube İndirici',
                  badgeText: 'Pro',
                  badgeColor: AppTheme.primary,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Favoriler',
                  badgeText: vm.favorites.isNotEmpty ? '${vm.favorites.length}' : null,
                  badgeColor: AppTheme.error,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.queue_music_rounded,
                  label: 'Çalma Listeleri',
                  badgeText: vm.playlists.isNotEmpty ? '${vm.playlists.length}' : null,
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.history_rounded,
                  label: 'Son Çalınanlar',
                  index: 4,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Ayarlar',
                  index: 5,
                ),

                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'ARAÇLAR & İÇE AKTAR',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Import action (Single unified button that imports directly into Playlists)
                _buildActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Müzik Dosyası Ekle',
                  onTap: () async {
                    await ImportFilesToPlaylistDialog.startImportFlow(
                      context: context,
                      vm: vm,
                      onNavigateToPlaylist: (pl) {
                        onNavigateToPlaylist?.call(pl.id);
                        onDestinationSelected(3);
                      },
                    );
                  },
                ),
                if (!kIsWeb)
                  _buildActionButton(
                    icon: Icons.create_new_folder_outlined,
                    label: 'Klasör Tara',
                    onTap: () async {
                      final added = await vm.pickLocalFolder();
                      if (context.mounted && added > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Klasörden $added şarkı eklendi.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                  ),
                _buildActionButton(
                  icon: Icons.tune_rounded,
                  label: vm.isSleepTimerActive
                      ? 'Ekolayzer & Efektler (Aktif)'
                      : 'Ekolayzer & Efektler',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AudioEffectsDialog(),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.keyboard_alt_outlined,
                  label: 'Klavye Kısayolları',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.keyboard_alt_rounded, color: AppTheme.primaryLight),
                            SizedBox(width: 10),
                            Text('Klavye Kısayolları'),
                          ],
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Boşluk (Space): Oynat / Duraklat'),
                            SizedBox(height: 6),
                            Text('• Sağ / Sol Ok: 5 Saniye İleri / Geri Sar'),
                            SizedBox(height: 6),
                            Text('• Yukarı / Aşağı Ok: Sesi Artır / Azalt'),
                            SizedBox(height: 6),
                            Text('• N / P: Sonraki / Önceki Şarkı'),
                            SizedBox(height: 6),
                            Text('• M: Sesi Kapat / Aç (Mute)'),
                            SizedBox(height: 6),
                            Text('• S: Karışık Çalma (Shuffle)'),
                            SizedBox(height: 6),
                            Text('• R: Tekrar Modu (Repeat)'),
                            SizedBox(height: 6),
                            Text('• Q: Çalma Sırasını Göster'),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    String? badgeText,
    Color? badgeColor,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withAlpha(35) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppTheme.primary.withAlpha(90), width: 1)
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => onDestinationSelected(index),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        leading: Icon(icon, color: AppTheme.accent, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

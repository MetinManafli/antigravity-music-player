import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final Track track;

  const AddToPlaylistDialog({super.key, required this.track});

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final TextEditingController _playlistNameController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.playlist_add, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isCreatingNew ? 'Yeni Çalma Listesi' : 'Çalma Listesine Ekle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Şarkı: "${widget.track.title}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_isCreatingNew) ...[
              TextField(
                controller: _playlistNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Liste Adı',
                  hintText: 'Örn: Gece Müzikleri, Çalışma...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isCreatingNew = false),
                    child: const Text('Geri'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _playlistNameController.text.trim();
                      if (name.isNotEmpty) {
                        final pl = await vm.createPlaylist(name);
                        await vm.addTrackToPlaylist(pl.id, widget.track);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"$name" listesi oluşturuldu ve şarkı eklendi.')),
                          );
                        }
                      }
                    },
                    child: const Text('Oluştur ve Ekle'),
                  ),
                ],
              ),
            ] else ...[
              if (vm.playlists.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: const Text(
                    'Henüz hiç çalma listesi oluşturmadınız.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vm.playlists.length,
                    itemBuilder: (context, index) {
                      final pl = vm.playlists[index];
                      final isAlreadyAdded = pl.tracks.any((t) => t.id == widget.track.id);

                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: AppTheme.primaryLight),
                        title: Text(pl.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${pl.tracks.length} şarkı', style: const TextStyle(fontSize: 12)),
                        trailing: isAlreadyAdded
                            ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                            : const Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 20),
                        onTap: () async {
                          if (isAlreadyAdded) {
                            await vm.removeTrackFromPlaylist(pl.id, widget.track);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Şarkı "${pl.name}" listesinden çıkarıldı.')),
                              );
                            }
                          } else {
                            await vm.addTrackToPlaylist(pl.id, widget.track);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Şarkı "${pl.name}" listesine eklendi.')),
                              );
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              const Divider(color: Color(0xFF2E2E3A), height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Yeni Liste Oluştur'),
                  onPressed: () => setState(() => _isCreatingNew = true),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _isCreatingNew
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
    );
  }
}

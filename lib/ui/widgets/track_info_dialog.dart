import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../theme/app_theme.dart';

class TrackInfoDialog extends StatefulWidget {
  final Track track;

  const TrackInfoDialog({super.key, required this.track});

  @override
  State<TrackInfoDialog> createState() => _TrackInfoDialogState();
}

class _TrackInfoDialogState extends State<TrackInfoDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _lyricsController;
  String _fileSizeText = 'Hesaplanıyor...';
  String _fileFormatText = '-';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist);
    _albumController = TextEditingController(text: widget.track.album ?? '');
    _lyricsController = TextEditingController(text: widget.track.lyrics ?? '');
    _inspectFileInfo();
  }

  Future<void> _inspectFileInfo() async {
    if (widget.track.isOnline || kIsWeb || widget.track.sourcePath.isEmpty) {
      if (mounted) {
        setState(() {
          _fileSizeText = 'Çevrim İçi Akış (Stream)';
          _fileFormatText = 'ONLINE';
        });
      }
      return;
    }

    try {
      final ext = p.extension(widget.track.sourcePath).replaceAll('.', '').toUpperCase();
      final file = File(widget.track.sourcePath);
      if (await file.exists()) {
        final bytes = await file.length();
        final mb = bytes / (1024 * 1024);
        if (mounted) {
          setState(() {
            _fileFormatText = ext.isNotEmpty ? ext : 'SES';
            _fileSizeText = '${mb.toStringAsFixed(2)} MB ($bytes bayt)';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _fileFormatText = ext.isNotEmpty ? ext : '-';
            _fileSizeText = 'Dosya bulunamadı';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fileSizeText = 'Bilinmiyor';
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return 'Çalındığında hesaplanır';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PlayerViewModel>();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(widget.track.addedAt);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF2E2E3C), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                      Icons.edit_note_rounded,
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
                          'Şarkı Bilgileri & Etiket Düzenleyici',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Başlık, sanatçı, albüm, şarkı sözleri ve dosya özelliklerini inceleyin',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF262632), height: 1),
              const SizedBox(height: 16),

              // Editable Metadata Fields
              const Text(
                'Şarkı Başlığı',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Şarkı adı'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sanatçı',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _artistController,
                          decoration: const InputDecoration(hintText: 'Sanatçı adı'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Albüm / Klasör',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _albumController,
                          decoration: const InputDecoration(hintText: 'Albüm adı'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Şarkı Sözleri (Lyrics) / Notlar',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final found = await vm.fetchOnlineLyrics(
                        widget.track.copyWith(
                          title: _titleController.text,
                          artist: _artistController.text,
                        ),
                      );
                      if (found != null && mounted) {
                        setState(() {
                          _lyricsController.text = found;
                        });
                      }
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 15, color: AppTheme.accent),
                    label: const Text(
                      'İnternetten Sözleri Otomatik Bul',
                      style: TextStyle(fontSize: 12, color: AppTheme.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _lyricsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Bu şarkı için şarkı sözlerini veya özel notlarınızı buraya yapıştırabilirsiniz...',
                ),
              ),

              const SizedBox(height: 18),

              // Technical File Details Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2E3C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBadge('Format', _fileFormatText, AppTheme.accent),
                        _buildStatBadge('Boyut', _fileSizeText, AppTheme.primaryLight),
                        _buildStatBadge('Süre', _formatDuration(widget.track.duration), AppTheme.textPrimary),
                        _buildStatBadge('Dinlenme', '${widget.track.playCount} kez', AppTheme.success),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF2E2E3C), height: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Eklenme Tarihi: $dateStr',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            'Konum: ${widget.track.sourcePath}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                            maxLines: 2,
                          ),
                        ),
                        if (!widget.track.isOnline && !kIsWeb) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => vm.revealInExplorer(widget.track),
                            icon: const Icon(Icons.folder_open_rounded, size: 16, color: AppTheme.accent),
                            label: const Text('Klasörde Göster', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final rawAlbum = _albumController.text.trim();
                      final rawLyrics = _lyricsController.text.trim();
                      await vm.updateTrackMetadata(
                        widget.track,
                        title: _titleController.text,
                        artist: _artistController.text,
                        album: rawAlbum.isEmpty ? null : rawAlbum,
                        clearAlbum: rawAlbum.isEmpty,
                        lyrics: rawLyrics.isEmpty ? null : rawLyrics,
                        clearLyrics: rawLyrics.isEmpty,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Şarkı bilgileri güncellendi.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Değişiklikleri Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
      ],
    );
  }
}

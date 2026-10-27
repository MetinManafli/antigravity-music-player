import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/playlist.dart';
import '../models/track.dart';

class FilePickerService {
  static const List<String> audioExtensions = [
    'mp3',
    'wav',
    'flac',
    'm4a',
    'aac',
    'ogg',
    'opus',
    'wma',
  ];

  /// Pick individual audio files
  Future<List<Track>> pickAudioFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Müzik Dosyası Ekle',
        type: FileType.custom,
        allowedExtensions: audioExtensions,
      );

      if (files.isEmpty) return [];

      final List<Track> tracks = [];
      for (final file in files) {
        final filePath = file.path ?? file.uri.toString();
        final name = file.name;
        final title = _cleanTitle(name);

        String artist = kIsWeb ? 'Web Dosyası' : 'Yerel Sanatçı';
        String album = 'Yerel Müzik';
        if (filePath.isNotEmpty && !kIsWeb) {
          try {
            final parentDir = p.basename(p.dirname(filePath));
            if (parentDir.isNotEmpty &&
                !['.', '/', '\\', 'music', 'müzik', 'desktop', 'masaüstü', 'downloads', 'indirilenler'].contains(parentDir.toLowerCase())) {
              artist = parentDir;
              album = parentDir;
            }
          } catch (_) {}
        }

        if (filePath.isNotEmpty) {
          tracks.add(Track(
            id: 'local_${DateTime.now().microsecondsSinceEpoch}_${tracks.length}',
            title: title,
            artist: artist,
            album: album,
            duration: Duration.zero,
            sourcePath: filePath,
            isOnline: kIsWeb,
          ));
        }
      }
      return tracks;
    } catch (e) {
      debugPrint('Error picking audio files: $e');
      return [];
    }
  }

  static String suggestPlaylistName(List<Track> tracks) {
    if (tracks.isEmpty) return 'İçe Aktarılan Müzikler';
    try {
      final firstPath = tracks.first.sourcePath;
      if (firstPath.isNotEmpty && !kIsWeb) {
        final parent = p.basename(p.dirname(firstPath));
        if (parent.isNotEmpty &&
            !['.', '/', '\\', 'music', 'müzik', 'downloads', 'indirilenler', 'desktop', 'masaüstü'].contains(parent.toLowerCase())) {
          return parent;
        }
      }
    } catch (_) {}
    return 'İçe Aktarılan Müzikler';
  }

  /// Pick a folder and scan all audio files recursively
  Future<List<Track>> pickFolderAndScan() async {
    if (kIsWeb) return []; // Web doesn't support directory scanning directly
    try {
      final String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory.isEmpty) return [];

      final dir = Directory(selectedDirectory);
      if (!await dir.exists()) return [];

      final List<Track> foundTracks = [];
      final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
          if (audioExtensions.contains(ext)) {
            final fileName = p.basename(entity.path);
            final parentFolder = p.basename(entity.parent.path);
            final title = _cleanTitle(fileName);

            foundTracks.add(Track(
              id: 'local_${entity.path.hashCode}',
              title: title,
              artist: parentFolder.isNotEmpty ? parentFolder : 'Bilinmeyen Sanatçı',
              album: parentFolder,
              duration: Duration.zero,
              sourcePath: entity.path,
              isOnline: false,
            ));
          }
        }
      }

      return foundTracks;
    } catch (e) {
      debugPrint('Error scanning folder: $e');
      return [];
    }
  }

  static String _cleanTitle(String fileName) {
    var name = p.basenameWithoutExtension(fileName);
    name = name.replaceAll(RegExp(r'^\d+[\s\.\-_]+'), '');
    return name.trim().isEmpty ? fileName : name.trim();
  }

  /// Build raw .m3u8 playlist text content
  static String buildM3UContent(Playlist playlist) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#PLAYLIST:${playlist.name}');
    for (final t in playlist.tracks) {
      final sec = t.duration.inSeconds > 0 ? t.duration.inSeconds : -1;
      buffer.writeln('#EXTINF:$sec,${t.artist} - ${t.title}');
      buffer.writeln(t.sourcePath);
    }
    return buffer.toString();
  }

  /// Parse .m3u or .m3u8 playlist content
  static Playlist parseM3UContent({
    required String content,
    required String defaultName,
    String? baseDir,
  }) {
    final lines = const LineSplitter().convert(content);
    String playlistName = Track.fixMojibake(defaultName);
    final List<Track> tracks = [];

    String? pendingTitle;
    String? pendingArtist;
    Duration pendingDuration = Duration.zero;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#PLAYLIST:')) {
        final plTitle = line.substring('#PLAYLIST:'.length).trim();
        if (plTitle.isNotEmpty) {
          playlistName = Track.fixMojibake(plTitle);
        }
      } else if (line.startsWith('#EXTINF:')) {
        final info = line.substring('#EXTINF:'.length);
        final commaIdx = info.indexOf(',');
        if (commaIdx != -1) {
          final secStr = info.substring(0, commaIdx).trim();
          final sec = int.tryParse(secStr) ?? 0;
          if (sec > 0) pendingDuration = Duration(seconds: sec);

          final display = Track.fixMojibake(info.substring(commaIdx + 1).trim());
          final dashIdx = display.indexOf(' - ');
          if (dashIdx != -1) {
            pendingArtist = display.substring(0, dashIdx).trim();
            pendingTitle = display.substring(dashIdx + 3).trim();
          } else {
            pendingTitle = display;
          }
        }
      } else if (!line.startsWith('#')) {
        String resolvedPath = line;
        final isOnline = line.startsWith('http://') || line.startsWith('https://');
        if (!isOnline && !p.isAbsolute(line) && baseDir != null) {
          resolvedPath = p.normalize(p.join(baseDir, line));
        }

        final fileName = p.basename(resolvedPath);
        final title = pendingTitle ?? Track.fixMojibake(_cleanTitle(fileName));
        final artist = pendingArtist ?? (isOnline ? 'Online' : 'Yerel Sanatçı');

        tracks.add(Track(
          id: 'm3u_${resolvedPath.hashCode}_${tracks.length}',
          title: title,
          artist: artist,
          album: playlistName,
          duration: pendingDuration,
          sourcePath: resolvedPath,
          isOnline: isOnline,
        ));

        pendingTitle = null;
        pendingArtist = null;
        pendingDuration = Duration.zero;
      }
    }

    return Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: playlistName,
      tracks: tracks,
    );
  }

  /// Export a playlist to an .m3u8 file
  Future<String?> exportPlaylistToM3U(Playlist playlist) async {
    if (kIsWeb) return null;
    try {
      final safeName = playlist.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final content = buildM3UContent(playlist);
      final encodedBytes = Uint8List.fromList(utf8.encode(content));
      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Çalma Listesini Dışa Aktar (.m3u8)',
        fileName: '$safeName.m3u8',
        type: FileType.custom,
        allowedExtensions: ['m3u8', 'm3u'],
        bytes: encodedBytes,
      );
      if (outputUri == null) return null;

      final outputPath = outputUri.toFilePath();
      final file = File(outputPath);
      if (!await file.exists()) {
        await file.writeAsBytes(encodedBytes);
      }
      return outputPath;
    } catch (e) {
      debugPrint('Error exporting M3U: $e');
      return null;
    }
  }

  /// Import an .m3u or .m3u8 playlist file from disk
  Future<Playlist?> importM3UPlaylist() async {
    if (kIsWeb) return null;
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'M3U / M3U8 Çalma Listesi İçe Aktar',
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8'],
      );
      if (files.isEmpty) return null;

      final picked = files.first;
      final filePath = picked.path;
      if (filePath == null || filePath.isEmpty) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString(encoding: utf8);
      final baseDir = p.dirname(filePath);
      final defaultName = _cleanTitle(picked.name);

      return parseM3UContent(
        content: content,
        defaultName: defaultName,
        baseDir: baseDir,
      );
    } catch (e) {
      debugPrint('Error importing M3U: $e');
      return null;
    }
  }
}

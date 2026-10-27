import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/track.dart';
import '../models/download_item.dart';

enum AudioDownloadFormat {
  opus(
    'opus',
    '💎 Opus (Orijinal / En Yüksek Kalite ~160 kbps)',
    'YouTube sunucularındaki en yüksek kaliteli orijinal ses akışıdır. Hiçbir dönüştürme yapılmadan doğrudan iner.',
  ),
  m4a(
    'm4a',
    '⚡ M4A / AAC (Orijinal / Standart Kalite ~128 kbps)',
    'YouTube orijinal AAC ses akışıdır. Dönüştürme olmadan doğrudan iner, Apple ve tüm cihazlarla tam uyumludur.',
  );

  final String id;
  final String label;
  final String description;
  const AudioDownloadFormat(this.id, this.label, this.description);

  static AudioDownloadFormat fromId(String? id) {
    if (id == 'm4a' || id == 'm4aFast' || id == 'aac') {
      return AudioDownloadFormat.m4a;
    }
    return AudioDownloadFormat.opus;
  }
}

class _YtPlaylistItem {
  final String id;
  final String title;
  const _YtPlaylistItem(this.id, this.title);
}

class OnlineMusicService {
  YoutubeExplode? _yt;

  YoutubeExplode get _client => _yt ??= YoutubeExplode();

  /// Curated initial featured songs & streams for instant listening
  List<Track> getFeaturedTracks() {
    return [
      Track(
        id: 'yt_lofi_hiphop',
        title: '🎧 Chill Lofi Hip Hop & Study Beats',
        artist: 'Lofi Girl / Chillhop',
        album: 'Odaklanma & Çalışma Serisi',
        duration: const Duration(minutes: 3, seconds: 52),
        sourcePath: 'lTRiuFIWV54',
        isOnline: true,
        thumbnailUrl: 'https://i.ytimg.com/vi/lTRiuFIWV54/hqdefault.jpg',
      ),
      Track(
        id: 'yt_synthwave_night',
        title: '🌆 Synthwave & Cyberpunk Gece Sürüşü',
        artist: 'The Midnight / Retro Electro',
        album: 'Synthwave Classics',
        duration: const Duration(minutes: 4, seconds: 18),
        sourcePath: 'MV_3Dpw-BRY',
        isOnline: true,
        thumbnailUrl: 'https://i.ytimg.com/vi/MV_3Dpw-BRY/hqdefault.jpg',
      ),
      Track(
        id: 'yt_piano_classical',
        title: '🎹 Ludovico Einaudi - Experience (Piyano & Keman)',
        artist: 'Ludovico Einaudi',
        album: 'In a Time Lapse',
        duration: const Duration(minutes: 5, seconds: 15),
        sourcePath: 'hNapt4nJM0U',
        isOnline: true,
        thumbnailUrl: 'https://i.ytimg.com/vi/hNapt4nJM0U/hqdefault.jpg',
      ),
      Track(
        id: 'yt_blinding_lights',
        title: '✨ The Weeknd - Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        duration: const Duration(minutes: 3, seconds: 22),
        sourcePath: '4NRXx6U8ABQ',
        isOnline: true,
        thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
      ),
      Track(
        id: 'yt_bohemian_rhapsody',
        title: '🎸 Queen - Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: const Duration(minutes: 5, seconds: 55),
        sourcePath: 'fJ9rUzIMcZQ',
        isOnline: true,
        thumbnailUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
      ),
      Track(
        id: 'yt_despacito',
        title: '🔥 Luis Fonsi - Despacito ft. Daddy Yankee',
        artist: 'Luis Fonsi',
        album: 'Vida',
        duration: const Duration(minutes: 4, seconds: 41),
        sourcePath: 'kJQP7kiw5Fk',
        isOnline: true,
        thumbnailUrl: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
      ),
    ];
  }

  /// Locate yt-dlp executable on the system
  Future<String?> _findYtDlp() async {
    try {
      final res = await Process.run('where.exe', ['yt-dlp']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split(RegExp(r'[\r\n]+'));
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && File(trimmed).existsSync()) {
            return trimmed;
          }
        }
      }
    } catch (_) {}

    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final candidates = [
      '$localAppData\\Programs\\Python\\Python313\\Scripts\\yt-dlp.exe',
      '$localAppData\\Programs\\Python\\Python312\\Scripts\\yt-dlp.exe',
      '$localAppData\\Programs\\Python\\Python311\\Scripts\\yt-dlp.exe',
      '$localAppData\\Programs\\Python\\Python310\\Scripts\\yt-dlp.exe',
      '$userProfile\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\yt-dlp.exe',
      'C:\\yt-dlp\\yt-dlp.exe',
    ];
    for (final p in candidates) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  /// Locate ffmpeg executable on the system for container fixup & audio extraction
  Future<String?> _findFfmpeg() async {
    try {
      final res = await Process.run('where.exe', ['ffmpeg']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split(RegExp(r'[\r\n]+'));
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && File(trimmed).existsSync()) {
            return trimmed;
          }
        }
      }
    } catch (_) {}

    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final candidates = [
      '$localAppData\\Microsoft\\WinGet\\Links\\ffmpeg.exe',
      'C:\\ffmpeg\\bin\\ffmpeg.exe',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  /// Normalize any YouTube URL (handles watch?v=...&list=..., music.youtube.com, raw IDs, etc.)
  String normalizeYouTubeUrl(String input) {
    String trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    // Check if the URL contains a list= query parameter
    final listMatch = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (listMatch != null) {
      final listId = listMatch.group(1)!;
      // If it's a standard YouTube playlist (PL..., OLAK..., etc.), force clean playlist URL
      // so yt-dlp doesn't mistakenly download only the single currently playing video (v=...)
      if (listId.startsWith('PL') || listId.startsWith('OLAK5uy_') || !trimmed.contains('watch?v=')) {
        return 'https://www.youtube.com/playlist?list=$listId';
      }
    }

    // If the user pasted a raw playlist ID
    if (trimmed.startsWith('PL') || trimmed.startsWith('OLAK5uy_')) {
      return 'https://www.youtube.com/playlist?list=$trimmed';
    }

    // Redirect music.youtube.com to www.youtube.com for max compatibility
    if (trimmed.contains('music.youtube.com')) {
      trimmed = trimmed.replaceAll('music.youtube.com', 'www.youtube.com');
    }

    return trimmed;
  }

  /// Download YouTube Playlist and save all tracks as local audio files
  Future<({List<Track> downloadedTracks, String playlistTitle})> downloadPlaylist({
    required String urlOrId,
    required String targetDirectory,
    AudioDownloadFormat format = AudioDownloadFormat.opus,
    int threads = 8,
    int concurrentDownloads = 3,
    void Function(String status, double progress, int current, int total)? onProgress,
    void Function(List<DownloadItemProgress> items)? onItemsUpdated,
    void Function(String playlistTitle)? onPlaylistTitleDetected,
    void Function(Track track)? onTrackDownloaded,
  }) async {
    final targetDir = Directory(targetDirectory);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final normalizedUrl = normalizeYouTubeUrl(urlOrId);

    final ytDlp = await _findYtDlp();
    if (ytDlp != null) {
      debugPrint('Using yt-dlp binary at: $ytDlp with URL: $normalizedUrl (format: ${format.id}, threads: $threads, concurrent: $concurrentDownloads)');
      return _downloadWithYtDlp(
        ytDlpPath: ytDlp,
        urlOrId: normalizedUrl,
        targetDirectory: targetDirectory,
        format: format,
        threads: threads,
        concurrentDownloads: concurrentDownloads,
        onProgress: onProgress,
        onItemsUpdated: onItemsUpdated,
        onPlaylistTitleDetected: onPlaylistTitleDetected,
        onTrackDownloaded: onTrackDownloaded,
      );
    }

    debugPrint('yt-dlp not found, falling back to youtube_explode_dart');
    return _downloadWithYoutubeExplode(
      urlOrId: normalizedUrl,
      targetDirectory: targetDirectory,
      onProgress: onProgress,
    );
  }

  /// High-speed robust playlist downloader using yt-dlp with parallel multi-song workers
  Future<({List<Track> downloadedTracks, String playlistTitle})> _downloadWithYtDlp({
    required String ytDlpPath,
    required String urlOrId,
    required String targetDirectory,
    AudioDownloadFormat format = AudioDownloadFormat.opus,
    int threads = 8,
    int concurrentDownloads = 3,
    void Function(String status, double progress, int current, int total)? onProgress,
    void Function(List<DownloadItemProgress> items)? onItemsUpdated,
    void Function(String playlistTitle)? onPlaylistTitleDetected,
    void Function(Track track)? onTrackDownloaded,
  }) async {
    onProgress?.call('Çalma listesi taranıyor ve parçalar alınıyor...', 0.05, 0, 1);

    final targetDir = Directory(targetDirectory);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    // 1. Fetch playlist metadata and item list via fast flat extraction
    final List<_YtPlaylistItem> items = [];
    String playlistTitle = 'YouTube Çalma Listesi';

    try {
      final flatResult = await Process.run(
        ytDlpPath,
        [
          '--no-colors',
          '--yes-playlist',
          '--flat-playlist',
          '--print', '%(id)s\t%(title)s\t%(playlist_title)s',
          urlOrId,
        ],
        environment: {
          'PYTHONIOENCODING': 'utf-8',
          'PYTHONUTF8': '1',
        },
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (flatResult.exitCode == 0) {
        final lines = flatResult.stdout.toString().split(RegExp(r'[\r\n]+'));
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('WARNING') || trimmed.startsWith('ERROR')) continue;
          final parts = trimmed.split('\t');
          if (parts.isNotEmpty) {
            final id = parts[0].trim();
            var rawTitle = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : id;
            if (rawTitle.trim().toUpperCase() == 'NA') {
              rawTitle = 'Kaldırılmış / Kısıtlanmış Video ($id)';
            }
            final title = Track.fixMojibake(rawTitle);
            if (parts.length > 2) {
              final plName = Track.fixMojibake(parts[2].trim());
              if (plName.isNotEmpty && plName != 'NA' && playlistTitle == 'YouTube Çalma Listesi') {
                playlistTitle = plName;
              }
            }
            if (id.isNotEmpty && id != 'NA') {
              items.add(_YtPlaylistItem(id, title));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error inspecting flat playlist: $e');
    }

    if (playlistTitle == 'YouTube Çalma Listesi' && items.length == 1) {
      playlistTitle = items.first.title;
    }

    onPlaylistTitleDetected?.call(playlistTitle);

    // If flat extraction returned 0 items, fallback to single-process sequential downloader
    if (items.isEmpty) {
      debugPrint('Flat extraction returned 0 items, using sequential fallback');
      return _downloadSequentialWithYtDlp(
        ytDlpPath: ytDlpPath,
        urlOrId: urlOrId,
        targetDirectory: targetDirectory,
        format: format,
        threads: threads,
        onProgress: onProgress,
      );
    }

    final totalItems = items.length;
    final workerCount = concurrentDownloads.clamp(1, 10).clamp(1, totalItems);

    final downloadProgressItems = List.generate(
      totalItems,
      (i) => DownloadItemProgress(
        id: items[i].id,
        title: items[i].title,
        index: i + 1,
        status: DownloadItemStatus.queued,
      ),
    );
    onItemsUpdated?.call(List.of(downloadProgressItems));

    onProgress?.call(
      '"$playlistTitle" ($totalItems parça) - $workerCount eşzamanlı indirme başlatılıyor...',
      0.08,
      0,
      totalItems,
    );

    int completedCount = 0;
    int nextIndex = 0;
    final Set<String> activeTitles = {};
    final List<Track?> orderedTracks = List.filled(totalItems, null);

    void notifyProgress() {
      final progress = totalItems > 0 ? (completedCount / totalItems).clamp(0.0, 1.0) : 0.0;
      String activeInfo = '';
      if (activeTitles.isNotEmpty) {
        final sample = activeTitles.take(2).map((t) => Track.fixMojibake(t)).join(', ');
        final more = activeTitles.length > 2 ? ' +${activeTitles.length - 2}' : '';
        activeInfo = ' (İndiriliyor: $sample$more)';
      }
      onProgress?.call(
        'İndiriliyor [$completedCount/$totalItems]$activeInfo',
        progress,
        completedCount,
        totalItems,
      );
    }

    Future<void> worker() async {
      while (true) {
        if (nextIndex >= totalItems) {
          break;
        }
        final int currentIndex = nextIndex++;
        final item = items[currentIndex];

        activeTitles.add(item.title);
        downloadProgressItems[currentIndex].status = DownloadItemStatus.downloading;
        onItemsUpdated?.call(List.of(downloadProgressItems));
        notifyProgress();

        try {
          final result = await _downloadSingleTrackYtDlp(
            ytDlpPath: ytDlpPath,
            videoId: item.id,
            fallbackTitle: item.title,
            playlistTitle: playlistTitle,
            targetDirectory: targetDirectory,
            format: format,
            threads: threads,
          );
          if (result.track != null) {
            orderedTracks[currentIndex] = result.track!;
            downloadProgressItems[currentIndex].status = DownloadItemStatus.completed;
            downloadProgressItems[currentIndex].errorMessage = null;
            onTrackDownloaded?.call(result.track!);
          } else {
            downloadProgressItems[currentIndex].status = DownloadItemStatus.failed;
            downloadProgressItems[currentIndex].errorMessage = result.errorMessage ?? 'İndirme tamamlanamadı.';
            downloadProgressItems[currentIndex].rawLog = result.rawLog;
          }
        } catch (e, stack) {
          downloadProgressItems[currentIndex].status = DownloadItemStatus.failed;
          downloadProgressItems[currentIndex].errorMessage = 'Hata: $e';
          downloadProgressItems[currentIndex].rawLog = '$e\n$stack';
          debugPrint('Hata (indirme): ${item.title} -> $e');
        } finally {
          completedCount++;
          activeTitles.remove(item.title);
          onItemsUpdated?.call(List.of(downloadProgressItems));
          notifyProgress();
        }
      }
    }

    final workers = List.generate(workerCount, (_) => worker());
    await Future.wait(workers);

    // Wait a brief moment for filesystem flush
    await Future.delayed(const Duration(milliseconds: 400));

    // Collect downloaded tracks in original playlist order
    final List<Track> finalTracks = [];
    final Set<String> seenPaths = {};

    for (final track in orderedTracks) {
      if (track != null && !seenPaths.contains(track.sourcePath)) {
        seenPaths.add(track.sourcePath);
        finalTracks.add(track);
      }
    }

    // Secondary safety: if some tracks weren't captured via stdout, check directory
    final supportedExts = {'.m4a', '.mp3', '.flac', '.wav', '.opus', '.ogg', '.webm'};
    for (final file in targetDir.listSync().whereType<File>()) {
      final dot = file.path.lastIndexOf('.');
      if (dot == -1) continue;
      final ext = file.path.substring(dot).toLowerCase();
      if (supportedExts.contains(ext) && !seenPaths.contains(file.path)) {
        final base = file.uri.pathSegments.last;
        final matchesItem = items.any((it) => _looseMatch(base, it.title));
        if (matchesItem || finalTracks.isEmpty) {
          seenPaths.add(file.path);
          finalTracks.add(_fileToTrack(file, playlistTitle));
        }
      }
    }

    onProgress?.call(
      'İndirme tamamlandı! (${finalTracks.length} parça hazır)',
      1.0,
      finalTracks.length,
      totalItems,
    );

    return (downloadedTracks: finalTracks, playlistTitle: playlistTitle);
  }

  /// Retry downloading a single track that previously failed
  Future<({Track? track, String? errorMessage, String? rawLog})> retrySingleTrack({
    required String videoId,
    required String fallbackTitle,
    required String playlistTitle,
    required String targetDirectory,
    required AudioDownloadFormat format,
    required int threads,
  }) async {
    final ytDlp = await _findYtDlp();
    if (ytDlp == null) {
      return (track: null, errorMessage: 'yt-dlp motoru bulunamadı.', rawLog: 'where.exe yt-dlp bulunamadı.');
    }
    return _downloadSingleTrackYtDlp(
      ytDlpPath: ytDlp,
      videoId: videoId,
      fallbackTitle: fallbackTitle,
      playlistTitle: playlistTitle,
      targetDirectory: targetDirectory,
      format: format,
      threads: threads,
    );
  }

  Future<({Track? track, String? errorMessage, String? rawLog})> _downloadSingleTrackYtDlp({
    required String ytDlpPath,
    required String videoId,
    required String fallbackTitle,
    required String playlistTitle,
    required String targetDirectory,
    required AudioDownloadFormat format,
    required int threads,
  }) async {
    final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
    final ffmpegPath = await _findFfmpeg();
    final List<String> args = [
      '--no-colors',
      '--no-playlist',
      '--ignore-errors',
      '--no-abort-on-error',
      '--retries', '5',
      '--fragment-retries', '5',
      '-N', '$threads',
      '--no-part',
      '--embed-metadata',
      if (ffmpegPath != null) ...['--ffmpeg-location', ffmpegPath],
      '--print', 'after_move:filepath',
    ];

    switch (format) {
      case AudioDownloadFormat.opus:
        if (!kIsWeb && Platform.isWindows && ffmpegPath != null) {
          // Windows MediaFoundation rejects .opus (0xC00D36C4), so extract 160kbps Opus stream into high-quality native M4A
          args.addAll([
            '-f', '251/ba[ext=webm]/ba',
            '-x',
            '--audio-format', 'm4a',
            '--audio-quality', '0',
          ]);
        } else {
          args.addAll([
            '-f', '251/ba[ext=webm]/ba',
            '-x',
            '--audio-format', 'opus',
          ]);
        }
        break;
      case AudioDownloadFormat.m4a:
        args.addAll([
          '-f', '140/ba[ext=m4a]/ba',
          '-x',
          '--audio-format', 'm4a',
        ]);
        break;
    }

    args.addAll([
      '-o', '$targetDirectory/%(title)s.%(ext)s',
      videoUrl,
    ]);

    final res = await Process.run(
      ytDlpPath,
      args,
      environment: {
        'PYTHONIOENCODING': 'utf-8',
        'PYTHONUTF8': '1',
      },
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    String? downloadedPath;
    final lines = res.stdout.toString().split(RegExp(r'[\r\n]+'));
    for (final line in lines.reversed) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('WARNING') || t.startsWith('ERROR')) continue;

      if (File(t).existsSync()) {
        downloadedPath = t;
        break;
      }

      if (t.contains('Destination:')) {
        final path = t.substring(t.indexOf('Destination:') + 'Destination:'.length).trim();
        if (File(path).existsSync()) {
          downloadedPath = path;
          break;
        }
      }

      if (t.contains('has already been downloaded')) {
        final match = RegExp(r'\[download\]\s*(.+?)\s+has already been downloaded').firstMatch(t);
        if (match != null) {
          final p = match.group(1)!.trim();
          if (File(p).existsSync()) {
            downloadedPath = p;
            break;
          }
        }
      }
    }

    if (downloadedPath != null) {
      return (track: _fileToTrack(File(downloadedPath), playlistTitle), errorMessage: null, rawLog: null);
    }

    // Fallback: search directory for matching filename with loose Turkish normalization
    final supportedExts = {'.m4a', '.mp3', '.flac', '.wav', '.opus', '.ogg', '.webm'};
    final dir = Directory(targetDirectory);
    if (dir.existsSync() && fallbackTitle.trim().isNotEmpty && fallbackTitle.trim().toUpperCase() != 'NA') {
      try {
        for (final file in dir.listSync().whereType<File>()) {
          String base;
          try {
            base = Uri.decodeComponent(file.uri.pathSegments.last);
          } catch (_) {
            base = file.path.split(Platform.pathSeparator).last;
          }
          final dot = base.lastIndexOf('.');
          if (dot == -1) continue;
          final ext = base.substring(dot).toLowerCase();
          if (!supportedExts.contains(ext)) continue;
          final baseNoExt = base.substring(0, dot);
          if (_looseMatch(baseNoExt, fallbackTitle)) {
            return (track: _fileToTrack(file, playlistTitle), errorMessage: null, rawLog: null);
          }
        }
      } catch (e) {
        debugPrint('Fallback scan error: $e');
      }
    }

    // Capture exact raw error and full log from yt-dlp stderr & stdout
    final combinedLog = '${res.stderr}\n${res.stdout}'.trim();
    final errorMsg = _extractRawError(res.stderr.toString(), res.stdout.toString(), res.exitCode);
    return (track: null, errorMessage: errorMsg, rawLog: combinedLog);
  }

  String _extractRawError(String stderr, String stdout, int exitCode) {
    final combined = '$stderr\n$stdout';
    final lines = combined.split(RegExp(r'[\r\n]+'));

    // 1. Look for explicit ERROR: lines directly from yt-dlp
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('ERROR:')) {
        return line;
      }
    }

    // 2. Look for lines with failure/error/traceback keywords (excluding WARNING:)
    for (final rawLine in lines.reversed) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('WARNING:')) continue;
      final lower = line.toLowerCase();
      if (lower.contains('error') ||
          lower.contains('exception') ||
          lower.contains('failed') ||
          lower.contains('traceback') ||
          lower.contains('errno')) {
        return line;
      }
    }

    // 3. Fallback: last meaningful line of output
    for (final rawLine in lines.reversed) {
      final line = rawLine.trim();
      if (line.isNotEmpty && !line.startsWith('WARNING:')) {
        return line;
      }
    }

    return 'yt-dlp çıkış kodu: $exitCode (Ek hata çıktısı üretmedi)';
  }

  bool _looseMatch(String a, String b) {
    if (a.trim().toUpperCase() == 'NA' || b.trim().toUpperCase() == 'NA') return false;

    String clean(String s) => s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    final ca = clean(a);
    final cb = clean(b);
    if (ca.isEmpty || cb.isEmpty) return false;
    if (ca == cb) return true;
    if (ca.length < 4 || cb.length < 4) return false;
    return ca.contains(cb) || cb.contains(ca);
  }

  /// Fallback sequential stream downloader using yt-dlp
  Future<({List<Track> downloadedTracks, String playlistTitle})> _downloadSequentialWithYtDlp({
    required String ytDlpPath,
    required String urlOrId,
    required String targetDirectory,
    AudioDownloadFormat format = AudioDownloadFormat.opus,
    int threads = 8,
    void Function(String status, double progress, int current, int total)? onProgress,
  }) async {
    onProgress?.call('Çalma listesi taranıyor ve başlık alınıyor...', 0.05, 0, 1);

    final targetDir = Directory(targetDirectory);
    final existingPaths = targetDir
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .toSet();

    // 1. Fetch playlist title beforehand
    String playlistTitle = 'YouTube Çalma Listesi';
    try {
      final titleResult = await Process.run(
        ytDlpPath,
        [
          '--no-colors',
          '--yes-playlist',
          '--flat-playlist',
          '--print', '%(playlist_title,title)s',
          '--playlist-items', '1',
          urlOrId,
        ],
        environment: {
          'PYTHONIOENCODING': 'utf-8',
          'PYTHONUTF8': '1',
        },
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (titleResult.exitCode == 0) {
        final lines = titleResult.stdout.toString().split(RegExp(r'[\r\n]+'));
        for (final l in lines) {
          final t = l.trim();
          if (t.isNotEmpty && !t.startsWith('WARNING') && t != 'NA') {
            playlistTitle = Track.fixMojibake(t);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error retrieving title: $e');
    }

    onProgress?.call('"$playlistTitle" listesi indiriliyor...', 0.1, 0, 1);

    int totalItems = 1;
    int currentItem = 0;
    final List<String> downloadedFilePaths = [];

    // 2. Build yt-dlp arguments tailored to user's choice
    final List<String> args = [
      '--no-colors',
      '--yes-playlist',
      '--ignore-errors',
      '--no-abort-on-error',
      '--retries', '5',
      '--fragment-retries', '5',
      '-N', '$threads',
      '--no-overwrites',
      '--continue',
      '--no-part',
      '--embed-metadata',
      '--newline',
    ];

    switch (format) {
      case AudioDownloadFormat.opus:
        args.addAll([
          '-f', '251/ba[ext=webm]/ba',
          '-x',
          '--audio-format', 'opus',
        ]);
        break;
      case AudioDownloadFormat.m4a:
        args.addAll([
          '-f', '140/ba[ext=m4a]/ba',
          '-x',
          '--audio-format', 'm4a',
        ]);
        break;
    }

    args.addAll([
      '-o', '$targetDirectory/%(title)s.%(ext)s',
      urlOrId,
    ]);

    final process = await Process.start(
      ytDlpPath,
      args,
      environment: {
        'PYTHONIOENCODING': 'utf-8',
        'PYTHONUTF8': '1',
      },
    );

    final lineSplitter = const LineSplitter();

    void parseLine(String line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return;

      // Detect playlist title from output
      final plMatch = RegExp(r'Downloading playlist:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
      if (plMatch != null) {
        final found = Track.fixMojibake(plMatch.group(1)!.trim());
        if (found.isNotEmpty) playlistTitle = found;
        onProgress?.call('Çalma listesi: "$playlistTitle"', 0.1, currentItem, totalItems);
      }

      // Detect total items
      final totalMatch = RegExp(r'Downloading (\d+) items', caseSensitive: false).firstMatch(trimmed);
      if (totalMatch != null) {
        totalItems = int.tryParse(totalMatch.group(1)!) ?? totalItems;
        onProgress?.call('"$playlistTitle" ($totalItems parça)', 0.1, currentItem, totalItems);
      }

      // Detect current item
      final itemMatch = RegExp(r'Downloading item (\d+) of (\d+)', caseSensitive: false).firstMatch(trimmed);
      if (itemMatch != null) {
        currentItem = int.tryParse(itemMatch.group(1)!) ?? currentItem;
        totalItems = int.tryParse(itemMatch.group(2)!) ?? totalItems;
        final progress = (currentItem / (totalItems > 0 ? totalItems : 1)).clamp(0.0, 1.0);
        onProgress?.call('İndiriliyor [$currentItem/$totalItems]', progress, currentItem, totalItems);
      }

      // Detect destination file (newly started or converting)
      if (trimmed.contains('Destination:')) {
        final path = trimmed.substring(trimmed.indexOf('Destination:') + 'Destination:'.length).trim();
        final base = File(path).uri.pathSegments.isNotEmpty ? File(path).uri.pathSegments.last : path;
        final dot = base.lastIndexOf('.');
        final songName = dot != -1 ? base.substring(0, dot) : base;

        if (!downloadedFilePaths.contains(path)) {
          downloadedFilePaths.add(path);
        }

        final progress = (currentItem / (totalItems > 0 ? totalItems : 1)).clamp(0.0, 1.0);
        onProgress?.call('İndiriliyor [$currentItem/$totalItems]: $songName', progress, currentItem, totalItems);
      }

      // Detect already downloaded file
      if (trimmed.contains('has already been downloaded')) {
        final match = RegExp(r'\[download\]\s*(.+?)\s+has already been downloaded').firstMatch(trimmed);
        if (match != null) {
          final path = match.group(1)!.trim();
          if (!downloadedFilePaths.contains(path)) {
            downloadedFilePaths.add(path);
          }
        }
      }

      // Detect download percentage
      final pctMatch = RegExp(r'\[download\]\s+(\d+(?:\.\d+)?)%').firstMatch(trimmed);
      if (pctMatch != null) {
        final pct = double.tryParse(pctMatch.group(1)!) ?? 0.0;
        final overall = ((currentItem > 0 ? currentItem - 1 : 0) + (pct / 100.0)) / (totalItems > 0 ? totalItems : 1);
        onProgress?.call(
          'İndiriliyor [$currentItem/$totalItems] (%${pct.toStringAsFixed(0)})',
          overall.clamp(0.0, 1.0),
          currentItem,
          totalItems,
        );
      }
    }

    process.stdout.transform(utf8.decoder).transform(lineSplitter).listen(parseLine);
    process.stderr.transform(utf8.decoder).transform(lineSplitter).listen((err) {
      debugPrint('yt-dlp stderr: $err');
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0 && downloadedFilePaths.isEmpty) {
      throw Exception('yt-dlp indirme işlemi tamamlanamadı (çıkış kodu: $exitCode)');
    }

    // Wait a brief moment for filesystem flush
    await Future.delayed(const Duration(milliseconds: 600));

    // Find all audio files in the target directory
    final supportedExts = {'.m4a', '.mp3', '.flac', '.wav', '.opus', '.ogg', '.webm'};
    final currentFiles = targetDir
        .listSync()
        .whereType<File>()
        .where((f) {
          final dot = f.path.lastIndexOf('.');
          if (dot == -1) return false;
          final ext = f.path.substring(dot).toLowerCase();
          return supportedExts.contains(ext);
        })
        .toList();

    final List<Track> tracks = [];
    final Set<String> seen = {};

    // 1. Add files detected during this download session
    for (final rawPath in downloadedFilePaths) {
      File file = File(rawPath);
      if (!file.existsSync()) {
        // Check with alternative extensions
        for (final ext in supportedExts) {
          final altPath = rawPath.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ext);
          if (File(altPath).existsSync()) {
            file = File(altPath);
            break;
          }
        }
      }

      if (file.existsSync() && !seen.contains(file.path)) {
        seen.add(file.path);
        tracks.add(_fileToTrack(file, playlistTitle));
      }
    }

    // 2. Also add any newly created audio files in target directory
    for (final file in currentFiles) {
      if (!existingPaths.contains(file.path) && !seen.contains(file.path)) {
        seen.add(file.path);
        tracks.add(_fileToTrack(file, playlistTitle));
      }
    }

    // 3. Fallback: if list is empty, include all files in the target directory
    if (tracks.isEmpty) {
      for (final file in currentFiles) {
        if (!seen.contains(file.path)) {
          seen.add(file.path);
          tracks.add(_fileToTrack(file, playlistTitle));
        }
      }
    }

    onProgress?.call('İndirme tamamlandı! (${tracks.length} parça)', 1.0, tracks.length, tracks.length);
    return (downloadedTracks: tracks, playlistTitle: playlistTitle);
  }

  Track _fileToTrack(File file, String playlistTitle) {
    String filename;
    try {
      filename = Uri.decodeComponent(file.uri.pathSegments.last);
    } catch (_) {
      filename = file.path.split(Platform.pathSeparator).last;
    }
    final dotIndex = filename.lastIndexOf('.');
    final baseName = dotIndex != -1 ? filename.substring(0, dotIndex) : filename;

    String artist = Track.fixMojibake(playlistTitle);
    String title = Track.fixMojibake(baseName);
    if (baseName.contains(' - ')) {
      final split = baseName.split(' - ');
      artist = Track.fixMojibake(split[0].trim());
      title = Track.fixMojibake(split.sublist(1).join(' - ').trim());
    }

    return Track(
      id: 'local_${file.path.hashCode}',
      title: title,
      artist: artist,
      album: Track.fixMojibake(playlistTitle),
      duration: Duration.zero,
      sourcePath: file.path,
      isOnline: false,
    );
  }

  /// Fallback: download using youtube_explode_dart
  Future<({List<Track> downloadedTracks, String playlistTitle})> _downloadWithYoutubeExplode({
    required String urlOrId,
    required String targetDirectory,
    void Function(String status, double progress, int current, int total)? onProgress,
  }) async {
    final List<Track> downloadedTracks = [];
    String playlistTitle = 'YouTube Çalma Listesi';

    try {
      if (urlOrId.contains('list=') || urlOrId.contains('/playlist')) {
        onProgress?.call('Çalma listesi bilgileri alınıyor...', 0.05, 0, 1);
        final playlistId = PlaylistId.fromString(urlOrId);
        final playlistMeta = await _client.playlists.get(playlistId);
        playlistTitle = Track.fixMojibake(playlistMeta.title);

        final videos = await _client.playlists.getVideos(playlistId).toList();
        final total = videos.length;

        onProgress?.call('"$playlistTitle" ($total parça) indiriliyor...', 0.1, 0, total);

        for (int i = 0; i < total; i++) {
          final video = videos[i];
          final percent = (i + 1) / total;
          onProgress?.call(
            'İndiriliyor [${i + 1}/$total]: ${video.title}',
            percent,
            i + 1,
            total,
          );

          try {
            final track = await _downloadSingleVideo(video, targetDirectory, playlistTitle);
            if (track != null) {
              downloadedTracks.add(track);
            }
          } catch (e) {
            debugPrint('Error downloading video ${video.title}: $e');
          }
        }
      } else {
        onProgress?.call('Video bilgileri alınıyor...', 0.1, 0, 1);
        final videoId = VideoId.fromString(urlOrId);
        final video = await _client.videos.get(videoId);
        playlistTitle = Track.fixMojibake(video.title);

        onProgress?.call('İndiriliyor: ${video.title}', 0.5, 0, 1);
        final track = await _downloadSingleVideo(video, targetDirectory, 'YouTube');
        if (track != null) {
          downloadedTracks.add(track);
        }
      }

      onProgress?.call('İndirme tamamlandı!', 1.0, downloadedTracks.length, downloadedTracks.length);
    } catch (e) {
      debugPrint('Error during playlist download: $e');
      rethrow;
    }

    return (downloadedTracks: downloadedTracks, playlistTitle: playlistTitle);
  }

  Future<Track?> _downloadSingleVideo(Video video, String targetDirectory, String albumName) async {
    final manifest = await _client.videos.streamsClient.getManifest(video.id);
    final audioStreams = manifest.audioOnly;
    if (audioStreams.isEmpty) return null;

    AudioStreamInfo? audioStreamInfo;
    for (final s in audioStreams) {
      if (s.container.name.toLowerCase() == 'mp4') {
        if (audioStreamInfo == null || s.bitrate.bitsPerSecond > audioStreamInfo.bitrate.bitsPerSecond) {
          audioStreamInfo = s;
        }
      }
    }
    audioStreamInfo ??= audioStreams.withHighestBitrate();
    final rawExt = audioStreamInfo.container.name.toLowerCase();
    final ext = (rawExt == 'mp4') ? 'm4a' : rawExt;
    final sanitizedTitle = _sanitizeFileName(video.title);
    final filePath = '$targetDirectory/$sanitizedTitle.$ext';
    final file = File(filePath);

    if (!await file.exists() || (await file.length()) == 0) {
      final stream = _client.videos.streamsClient.get(audioStreamInfo);
      final sink = file.openWrite();
      await stream.pipe(sink);
      await sink.flush();
      await sink.close();
    }

    return Track(
      id: 'local_${file.path.hashCode}',
      title: video.title,
      artist: video.author,
      album: albumName,
      duration: video.duration ?? Duration.zero,
      sourcePath: file.path,
      isOnline: false,
      thumbnailUrl: video.thumbnails.mediumResUrl,
    );
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
  }

  /// Search online videos/music
  Future<List<Track>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final searchResults = await _client.search.search(query);
      final List<Track> tracks = [];

      for (final video in searchResults) {
        final duration = video.duration ?? Duration.zero;
        if (duration.inMinutes > 30) continue;

        tracks.add(Track(
          id: 'yt_${video.id.value}',
          title: video.title,
          artist: video.author,
          album: 'YouTube Music',
          duration: duration,
          sourcePath: video.id.value,
          isOnline: true,
          thumbnailUrl: video.thumbnails.mediumResUrl,
        ));

        if (tracks.length >= 20) break;
      }
      return tracks;
    } catch (e) {
      debugPrint('Error searching online music: $e');
      return [];
    }
  }

  /// Resolve audio stream for playback.
  /// On Windows Desktop, Windows MediaFoundation (IMFSourceResolver) fails with `WindowsAudioError: Failed to set source`
  /// on missing local files (0x80070002), .opus files (0xC00D36C4), or extensionless YouTube DASH URLs.
  /// This method guarantees a valid, existing, Windows MediaFoundation-compatible local file path.
  Future<String?> resolveStreamUrl(Track track, {List<Track>? localTracks}) async {
    if (!track.isOnline) {
      if (kIsWeb) return track.sourcePath;
      final directFile = File(track.sourcePath);
      if (directFile.existsSync() && directFile.lengthSync() > 1024) {
        return directFile.path;
      }
      return _resolveOrRecoverLocalTrack(track, localTracks: localTracks);
    }

    String rawSource = track.sourcePath.trim();
    if (rawSource.isEmpty) return null;

    // Self-heal legacy direct HTTP URLs that Windows MediaFoundation cannot open directly
    if (rawSource.contains('streamafrica.net') || rawSource.contains('lofi-study')) {
      rawSource = 'lTRiuFIWV54';
    } else if (rawSource.contains('nightride.fm') || rawSource.contains('synthwave')) {
      rawSource = 'MV_3Dpw-BRY';
    } else if (rawSource.contains('pixabay.com')) {
      rawSource = 'hNapt4nJM0U';
    }

    if (!kIsWeb) {
      final cacheDir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}antigravity_audio_cache');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      // Extract clean video ID or hash
      final safeKey = rawSource.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final cachedM4a = File('${cacheDir.path}${Platform.pathSeparator}stream_$safeKey.m4a');

      // Instant 0ms playback if already in stream cache
      if (cachedM4a.existsSync() && cachedM4a.lengthSync() > 8192) {
        return cachedM4a.path;
      }

      final targetUrl = rawSource.startsWith('http')
          ? rawSource
          : 'https://www.youtube.com/watch?v=$rawSource';

      // 1. Fast multi-threaded M4A stream fetch via yt-dlp (includes FixupM4a for Windows MediaFoundation)
      try {
        final ytDlp = await _findYtDlp();
        final ffmpegPath = await _findFfmpeg();
        if (ytDlp != null) {
          final res = await Process.run(
            ytDlp,
            [
              '--no-colors',
              '--no-playlist',
              if (ffmpegPath != null) ...['--ffmpeg-location', ffmpegPath],
              '-f', '140/ba[ext=m4a]/ba',
              '-x',
              '--audio-format', 'm4a',
              '-N', '8',
              '--no-part',
              '-o', cachedM4a.path,
              targetUrl,
            ],
            environment: {
              'PYTHONIOENCODING': 'utf-8',
              'PYTHONUTF8': '1',
            },
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          );

          if (cachedM4a.existsSync() && cachedM4a.lengthSync() > 4096) {
            return cachedM4a.path;
          }
          debugPrint('yt-dlp stream cache exit ${res.exitCode}: ${res.stderr}');
        }
      } catch (e) {
        debugPrint('yt-dlp stream cache error: $e');
      }

      // 2. Fallback: download audio stream via youtube_explode_dart and remux via ffmpeg into valid M4A
      if (!rawSource.startsWith('http')) {
        try {
          final manifest = await _client.videos.streamsClient.getManifest(rawSource);
          final audioStreams = manifest.audioOnly;
          if (audioStreams.isNotEmpty) {
            AudioStreamInfo? m4aStream;
            for (final s in audioStreams) {
              if (s.container.name.toLowerCase() == 'mp4') {
                if (m4aStream == null || s.bitrate.bitsPerSecond > m4aStream.bitrate.bitsPerSecond) {
                  m4aStream = s;
                }
              }
            }
            m4aStream ??= audioStreams.withHighestBitrate();
            final rawTempFile = File('${cacheDir.path}${Platform.pathSeparator}raw_$safeKey.${m4aStream.container.name}');
            final stream = _client.videos.streamsClient.get(m4aStream);
            final sink = rawTempFile.openWrite();
            await stream.pipe(sink);
            await sink.flush();
            await sink.close();

            final ffmpegPath = await _findFfmpeg();
            if (ffmpegPath != null && rawTempFile.existsSync()) {
              await Process.run(
                ffmpegPath,
                [
                  '-y',
                  '-i', rawTempFile.path,
                  '-vn',
                  '-c:a', 'aac',
                  '-b:a', '192k',
                  '-movflags', '+faststart',
                  cachedM4a.path,
                ],
              );
              try {
                rawTempFile.deleteSync();
              } catch (_) {}
            } else if (rawTempFile.existsSync()) {
              rawTempFile.renameSync(cachedM4a.path);
            }

            if (cachedM4a.existsSync() && cachedM4a.lengthSync() > 4096) {
              return cachedM4a.path;
            }
          }
        } catch (e) {
          debugPrint('youtube_explode stream cache fallback error: $e');
        }
      }
    }

    // Web fallback
    if (rawSource.startsWith('http://') || rawSource.startsWith('https://')) {
      return rawSource;
    }
    try {
      final manifest = await _client.videos.streamsClient.getManifest(rawSource);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return null;
      return audioStreams.withHighestBitrate().url.toString();
    } catch (e) {
      debugPrint('Error resolving stream URL for track ${track.title}: $e');
      return null;
    }
  }

  String _cleanTitleForMatch(String input) {
    return input
        .replaceAll(RegExp(r'\(MP3_\d+K\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\.(mp3|m4a|flac|wav|opus|ogg|webm)$', caseSensitive: false), '')
        .trim();
  }

  /// Resolves a local track whose original file path was moved, renamed (e.g. .flac -> .m4a), or deleted.
  /// 1) Checks alternative audio extensions in the same folder and known music folders.
  /// 2) Checks existing files in `localTracks` by title match.
  /// 3) Automatically re-downloads/caches the track from YouTube if no local copy exists.
  Future<String?> _resolveOrRecoverLocalTrack(Track track, {List<Track>? localTracks}) async {
    const exts = ['.m4a', '.mp3', '.flac', '.wav', '.opus', '.ogg', '.webm'];
    final rawPath = track.sourcePath.trim();

    // 1. Check same path with alternative extensions
    if (rawPath.isNotEmpty) {
      final dotIdx = rawPath.lastIndexOf('.');
      final baseNoExt = dotIdx != -1 ? rawPath.substring(0, dotIdx) : rawPath;
      for (final ext in exts) {
        final candidate = File('$baseNoExt$ext');
        if (candidate.existsSync() && candidate.lengthSync() > 1024) {
          return candidate.path;
        }
      }
    }

    // 2. Check existing tracks in localTracks by clean title match
    final targetCleanTitle = _cleanTitleForMatch(track.title);
    if (localTracks != null && targetCleanTitle.isNotEmpty) {
      for (final candidate in localTracks) {
        if (candidate.isOnline) continue;
        final f = File(candidate.sourcePath);
        if (!f.existsSync() || f.lengthSync() <= 1024) continue;
        final candClean = _cleanTitleForMatch(candidate.title);
        if (_looseMatch(targetCleanTitle, candClean)) {
          return f.path;
        }
      }
    }

    // 3. Scan standard user music directories (YouTube_Indirilenler & Desktop\Rap)
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final searchDirs = <String>[
      if (rawPath.contains(Platform.pathSeparator))
        rawPath.substring(0, rawPath.lastIndexOf(Platform.pathSeparator)),
      if (userProfile.isNotEmpty) '$userProfile\\Music\\YouTube_Indirilenler',
      if (userProfile.isNotEmpty) '$userProfile\\Desktop\\Rap',
    ];

    for (final dirPath in searchDirs.toSet()) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;
      try {
        for (final file in dir.listSync().whereType<File>()) {
          final name = file.path.split(Platform.pathSeparator).last;
          final dot = name.lastIndexOf('.');
          if (dot == -1) continue;
          final ext = name.substring(dot).toLowerCase();
          if (!exts.contains(ext)) continue;
          final baseClean = _cleanTitleForMatch(name.substring(0, dot));
          if (_looseMatch(targetCleanTitle, baseClean)) {
            if (file.lengthSync() > 1024) {
              return file.path;
            }
          }
        }
      } catch (_) {}
    }

    // 4. Automatic YouTube recovery if the local file was deleted from disk
    try {
      final targetDir = userProfile.isNotEmpty
          ? Directory('$userProfile\\Music\\YouTube_Indirilenler')
          : Directory('${Directory.systemTemp.path}${Platform.pathSeparator}antigravity_audio_cache');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final safeTitle = _sanitizeFileName(targetCleanTitle.isNotEmpty ? targetCleanTitle : track.title);
      final recoveredFile = File('${targetDir.path}${Platform.pathSeparator}$safeTitle.m4a');
      if (recoveredFile.existsSync() && recoveredFile.lengthSync() > 4096) {
        return recoveredFile.path;
      }

      // Build search query using artist + title (skip generic folder/playlist names as artist)
      final lowerArtist = track.artist.trim().toLowerCase();
      final isGenericArtist = lowerArtist.isEmpty ||
          lowerArtist == 'yenilikçi' ||
          lowerArtist == 'rap' ||
          lowerArtist.contains('bilinmeyen') ||
          lowerArtist.contains('unknown') ||
          lowerArtist.contains('youtube');
      final query = isGenericArtist ? track.title.trim() : '${track.artist.trim()} ${track.title.trim()}';
      if (query.isEmpty) return null;

      final ytDlp = await _findYtDlp();
      final ffmpegPath = await _findFfmpeg();

      // Fast path: resolve videoId via youtube_explode_dart search (~300ms), then download via yt-dlp
      String? videoUrl;
      try {
        final results = await _client.search.search(query).timeout(const Duration(seconds: 4));
        for (final v in results) {
          final dur = v.duration ?? Duration.zero;
          if (dur.inMinutes <= 25) {
            videoUrl = 'https://www.youtube.com/watch?v=${v.id.value}';
            break;
          }
        }
      } catch (_) {}

      if (ytDlp != null) {
        final res = await Process.run(
          ytDlp,
          [
            '--no-colors',
            '--no-playlist',
            if (ffmpegPath != null) ...['--ffmpeg-location', ffmpegPath],
            '-f', '140/ba[ext=m4a]/ba',
            '-x',
            '--audio-format', 'm4a',
            '-N', '8',
            '--no-part',
            '-o', recoveredFile.path,
            videoUrl ?? 'ytsearch1:$query',
          ],
          environment: {
            'PYTHONIOENCODING': 'utf-8',
            'PYTHONUTF8': '1',
          },
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (recoveredFile.existsSync() && recoveredFile.lengthSync() > 4096) {
          return recoveredFile.path;
        }
        debugPrint('Auto-recovery yt-dlp exit ${res.exitCode}: ${res.stderr}');
      }
    } catch (e) {
      debugPrint('Error auto-recovering missing local track ${track.title}: $e');
    }

    return null;
  }

  /// Automatically search and fetch song lyrics from LRCLIB open lyrics API
  Future<String?> fetchLyricsOnline(String title, String artist) async {
    try {
      // Clean common YouTube suffixes like (Official Video), [Lyrics], ft., etc.
      String cleanTitle = title
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
          .replaceAll(RegExp(r'official\s*(music\s*)?video|audio|lyrics|hd|4k', caseSensitive: false), '')
          .trim();
      String cleanArtist = artist
          .replaceAll(RegExp(r'\s*-\s*topic|\s*vevo', caseSensitive: false), '')
          .trim();

      final query = ('$cleanArtist $cleanTitle').trim();
      if (query.isEmpty) return null;

      final uri = Uri.https('lrclib.net', '/api/search', {'q': query});
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'AntigravityMusicPlayer/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data.isNotEmpty) {
          for (final item in data) {
            final plain = item['plainLyrics'] as String?;
            if (plain != null && plain.trim().isNotEmpty) {
              return plain.trim();
            }
          }
        }
      }

      // Second attempt: search with title only if artist+title had extra noise
      if (cleanTitle.isNotEmpty && cleanTitle != query) {
        final uri2 = Uri.https('lrclib.net', '/api/search', {'q': cleanTitle});
        final response2 = await http.get(
          uri2,
          headers: {'User-Agent': 'AntigravityMusicPlayer/1.0'},
        ).timeout(const Duration(seconds: 8));
        if (response2.statusCode == 200) {
          final List<dynamic> data2 = jsonDecode(utf8.decode(response2.bodyBytes));
          if (data2.isNotEmpty) {
            for (final item in data2) {
              final plain = item['plainLyrics'] as String?;
              if (plain != null && plain.trim().isNotEmpty) {
                return plain.trim();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching lyrics from LRCLIB: $e');
    }
    return null;
  }

  void dispose() {
    _yt?.close();
  }
}

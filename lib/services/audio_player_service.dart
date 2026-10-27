import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum RepeatMode {
  off,
  all,
  one,
}

class AudioPlayerService {
  static const List<double> eqFrequencies = [60, 230, 910, 3600, 14000];
  static const List<String> eqLabels = ['60 Hz', '230 Hz', '910 Hz', '3.6 kHz', '14 kHz'];

  static const Map<String, String> eqPresetNames = {
    'flat': 'Düz (Varsayılan)',
    'bass_boost': 'Bass Boost',
    'rap': 'Rap & Hip-Hop',
    'rock': 'Rock & Metal',
    'pop': 'Pop',
    'electronic': 'Elektronik / Dance',
    'vocal': 'Vokal / Podcast',
    'acoustic': 'Akustik',
    'classical': 'Klasik',
    'night': 'Gece Modu',
    'custom': 'Özel',
  };

  static const Map<String, List<double>> eqPresets = {
    'flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'bass_boost': [7.0, 4.5, 0.0, 1.0, 1.5],
    'rap': [6.5, 3.5, -1.5, 2.5, 4.0],
    'rock': [5.0, 2.5, -2.0, 3.5, 5.0],
    'pop': [2.5, 4.0, 2.5, 1.5, 3.5],
    'electronic': [6.0, 2.5, -1.0, 3.0, 5.5],
    'vocal': [-3.0, -1.0, 4.5, 4.0, 1.0],
    'acoustic': [3.0, 2.0, 1.0, 3.0, 3.5],
    'classical': [3.5, 1.5, -0.5, 2.0, 4.0],
    'night': [-4.0, 1.0, 2.0, -1.0, -3.5],
  };

  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  PlayerState _state = PlayerState.stopped;
  PlayerState get state => _state;
  bool get isPlaying => _state == PlayerState.playing;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  double _volume = 0.8;
  double get volume => _volume;

  double _playbackRate = 1.0;
  double get playbackRate => _playbackRate;

  double _balance = 0.0;
  double get balance => _balance;

  bool _eqEnabled = false;
  bool get eqEnabled => _eqEnabled;

  List<double> _eqBands = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> get eqBands => List.unmodifiable(_eqBands);

  String? _lastRawSourceUri;
  bool _lastIsOnline = false;

  bool get _hasActiveEqFilter => _eqEnabled && _eqBands.any((g) => g.abs() >= 0.1);

  String? _buildFfmpegEqFilter() {
    if (!_hasActiveEqFilter) return null;
    final maxBoost = _eqBands.reduce((a, b) => a > b ? a : b);
    final preampDb = maxBoost > 2.0 ? -(maxBoost * 0.55).clamp(0.0, 6.0) : 0.0;
    final List<String> filters = [];
    if (preampDb != 0.0) {
      filters.add('volume=${preampDb.toStringAsFixed(1)}dB');
    }
    for (int i = 0; i < 5 && i < _eqBands.length; i++) {
      if (_eqBands[i].abs() >= 0.1) {
        final gain = _eqBands[i].clamp(-12.0, 12.0).toStringAsFixed(1);
        filters.add('equalizer=f=${eqFrequencies[i].toInt()}:width_type=o:width=1.8:g=$gain');
      }
    }
    if (filters.isEmpty) return null;
    return filters.join(',');
  }

  AudioPlayerService() {
    _init();
  }

  void _init() {
    _player.onPlayerStateChanged.listen((s) {
      _state = s;
    });

    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
    });

    _player.onDurationChanged.listen((dur) {
      _totalDuration = dur;
    });
  }

  /// Play audio from resolved URL or local file path.
  /// Proactively converts containers unsupported by Windows MediaFoundation (.opus, .ogg, .webm, raw DASH)
  /// or applies 5-band Equalizer DSP via FFmpeg when active, and automatically falls back to FFmpeg AAC M4A transcoding if playback fails.
  Future<void> playSource({required String resolvedUri, required bool isOnline}) async {
    _lastRawSourceUri = resolvedUri;
    _lastIsOnline = isOnline;

    final isHttpUrl = resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://');
    String targetUri = resolvedUri;

    if (!kIsWeb && Platform.isWindows && !isHttpUrl) {
      if (await _needsProactiveConversion(resolvedUri) || _hasActiveEqFilter) {
        final converted = await _convertToWindowsCompatibleM4a(
          resolvedUri,
          eqFilter: _buildFfmpegEqFilter(),
        );
        if (converted != null && File(converted).existsSync()) {
          targetUri = converted;
        }
      }
    }

    try {
      final bool targetIsHttp = targetUri.startsWith('http://') || targetUri.startsWith('https://');
      final Source source = targetIsHttp ? UrlSource(targetUri) : DeviceFileSource(targetUri);

      await _player.stop();
      await _player.setVolume(_volume);
      await _player.setBalance(_balance);
      await _player.play(source);
      if (_playbackRate != 1.0) {
        try {
          await _player.setPlaybackRate(_playbackRate);
        } catch (e) {
          debugPrint('Playback rate error: $e');
        }
      }
    } catch (e) {
      debugPrint('Primary playSource failed ($e), attempting Windows MediaFoundation compatible M4A fallback...');
      if (!kIsWeb && Platform.isWindows) {
        final fallbackPath = await _convertToWindowsCompatibleM4a(
          resolvedUri,
          forceReencode: true,
          eqFilter: _buildFfmpegEqFilter(),
        );
        if (fallbackPath != null && File(fallbackPath).existsSync()) {
          try {
            await _player.release();
          } catch (_) {
            await _player.stop();
          }
          await _player.setVolume(_volume);
          await _player.setBalance(_balance);
          await _player.play(DeviceFileSource(fallbackPath));
          if (_playbackRate != 1.0) {
            try {
              await _player.setPlaybackRate(_playbackRate);
            } catch (_) {}
          }
          return;
        }
      }
      rethrow;
    }
  }

  /// Configures 5-Band Equalizer DSP and seamlessly hot-swaps active playback if requested.
  Future<void> configureEqualizer({
    required bool enabled,
    required List<double> bands,
    bool hotSwap = true,
  }) async {
    _eqEnabled = enabled;
    if (bands.length >= 5) {
      _eqBands = List<double>.from(bands.take(5));
    }

    if (hotSwap &&
        _lastRawSourceUri != null &&
        (_state == PlayerState.playing || _state == PlayerState.paused)) {
      final savedPos = _currentPosition;
      final wasPlaying = isPlaying;
      await playSource(resolvedUri: _lastRawSourceUri!, isOnline: _lastIsOnline);
      if (savedPos > Duration.zero) {
        await seek(savedPos);
      }
      if (!wasPlaying) {
        await pause();
      }
    }
  }

  Future<bool> isFfmpegInstalled() async => (await _findFfmpeg()) != null;

  /// Checks if a local file uses a container/codec that Windows MediaFoundation IMFSourceResolver rejects (0xC00D36C4).
  Future<bool> _needsProactiveConversion(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      final ext = p.extension(filePath).toLowerCase();
      if (ext == '.opus' || ext == '.ogg' || ext == '.webm' || ext == '.mkv') {
        return true;
      }

      if (file.lengthSync() >= 12) {
        final raf = file.openSync(mode: FileMode.read);
        try {
          final header = raf.readSync(12);
          if (header.length >= 12) {
            // OggS container (Opus / Vorbis) -> 0x4F 0x67 0x67 0x53
            if (header[0] == 0x4F && header[1] == 0x67 && header[2] == 0x67 && header[3] == 0x53) {
              return true;
            }
            // WebM / Matroska EBML -> 0x1A 0x45 0xDF 0xA3
            if (header[0] == 0x1A && header[1] == 0x45 && header[2] == 0xDF && header[3] == 0xA3) {
              return true;
            }
            // Un-remuxed YouTube DASH fragmented MP4 -> "ftypdash" at bytes 4..11
            if (header[4] == 0x66 &&
                header[5] == 0x74 &&
                header[6] == 0x79 &&
                header[7] == 0x70 &&
                header[8] == 0x64 &&
                header[9] == 0x61 &&
                header[10] == 0x73 &&
                header[11] == 0x68) {
              return true;
            }
          }
        } finally {
          raf.closeSync();
        }
      }
    } catch (_) {}
    return false;
  }

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

  /// Converts unsupported containers (e.g. .opus, .webm, .ogg, or raw streams) or applies Equalizer DSP into a Windows MediaFoundation native .m4a file
  Future<String?> _convertToWindowsCompatibleM4a(
    String inputUri, {
    bool forceReencode = false,
    String? eqFilter,
  }) async {
    try {
      final isHttp = inputUri.startsWith('http://') || inputUri.startsWith('https://');
      if (!isHttp && !File(inputUri).existsSync()) {
        return null;
      }

      final ffmpegPath = await _findFfmpeg();
      if (ffmpegPath == null) return null;

      final cacheDir = Directory(p.join(Directory.systemTemp.path, 'antigravity_audio_cache'));
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final fileName = (eqFilter != null && eqFilter.isNotEmpty)
          ? 'eq_${inputUri.hashCode.abs()}_${eqFilter.hashCode.abs()}.m4a'
          : 'compat_${inputUri.hashCode.abs()}.m4a';
      final outPath = p.join(cacheDir.path, fileName);
      final outFile = File(outPath);
      if (!forceReencode && outFile.existsSync() && outFile.lengthSync() > 4096) {
        return outPath;
      }

      final res = await Process.run(
        ffmpegPath,
        [
          '-y',
          '-i', inputUri,
          '-vn',
          if (eqFilter != null && eqFilter.isNotEmpty) ...['-af', eqFilter],
          '-c:a', 'aac',
          '-b:a', '192k',
          '-ar', '44100',
          '-ac', '2',
          '-movflags', '+faststart',
          outPath,
        ],
      );

      if (res.exitCode == 0 && outFile.existsSync() && outFile.lengthSync() > 1024) {
        return outPath;
      }
    } catch (e) {
      debugPrint('FFmpeg compatibility fallback error: $e');
    }
    return null;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
    if (_playbackRate != 1.0) {
      try {
        await _player.setPlaybackRate(_playbackRate);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPosition = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate.clamp(0.25, 2.5);
    try {
      await _player.setPlaybackRate(_playbackRate);
    } catch (e) {
      debugPrint('Error setting playback rate: $e');
    }
  }

  Future<void> setBalance(double bal) async {
    _balance = bal.clamp(-1.0, 1.0);
    try {
      await _player.setBalance(_balance);
    } catch (e) {
      debugPrint('Error setting stereo balance: $e');
    }
  }

  void dispose() {
    _player.dispose().ignore();
  }
}

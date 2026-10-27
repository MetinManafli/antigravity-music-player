import 'dart:async';
import 'dart:io' show Platform, Process, File, Directory;
import 'dart:ui' show Size;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/download_item.dart';
import '../services/audio_player_service.dart';
import '../services/file_picker_service.dart';
import '../services/online_music_service.dart';
import '../services/storage_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final FilePickerService _filePickerService = FilePickerService();
  final OnlineMusicService _onlineMusicService = OnlineMusicService();
  final StorageService _storageService = StorageService();

  // Playback state
  Track? _currentTrack;
  Track? get currentTrack => _currentTrack;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  double _volume = 0.8;
  double get volume => _volume;

  double _previousVolume = 0.8;
  bool get isMuted => _volume == 0.0;

  double _playbackRate = 1.0;
  double get playbackRate => _playbackRate;

  double _balance = 0.0;
  double get balance => _balance;

  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;

  RepeatMode _repeatMode = RepeatMode.off;
  RepeatMode get repeatMode => _repeatMode;

  bool _isMiniPlayer = false;
  bool get isMiniPlayer => _isMiniPlayer;

  bool _isFetchingLyrics = false;
  bool get isFetchingLyrics => _isFetchingLyrics;

  // Equalizer State
  bool _eqEnabled = false;
  bool get eqEnabled => _eqEnabled;

  String _eqPreset = 'flat';
  String get eqPreset => _eqPreset;

  List<double> _eqBands = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> get eqBands => List.unmodifiable(_eqBands);

  bool _isProcessingEq = false;
  bool get isProcessingEq => _isProcessingEq;

  // App & Engine Settings State
  String _customDownloadDir = '';
  String get customDownloadDir => _customDownloadDir;

  bool _showVisualizer = true;
  bool get showVisualizer => _showVisualizer;

  bool _autoFetchLyrics = true;
  bool get autoFetchLyrics => _autoFetchLyrics;

  double _audioCacheSizeMb = 0.0;
  double get audioCacheSizeMb => _audioCacheSizeMb;

  bool _isFfmpegAvailable = true;
  bool get isFfmpegAvailable => _isFfmpegAvailable;

  bool _isYtDlpAvailable = true;
  bool get isYtDlpAvailable => _isYtDlpAvailable;

  // A-B Loop State
  Duration? _loopStartA;
  Duration? get loopStartA => _loopStartA;

  Duration? _loopEndB;
  Duration? get loopEndB => _loopEndB;

  bool get isABLoopActive => _loopStartA != null && _loopEndB != null;

  // Sleep Timer State
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  bool _stopAfterCurrentTrack = false;
  bool get stopAfterCurrentTrack => _stopAfterCurrentTrack;

  bool get isSleepTimerActive => _sleepTimerRemaining != null || _stopAfterCurrentTrack;

  // Queue
  List<Track> _queue = [];
  List<Track> get queue => List.unmodifiable(_queue);
  List<Track> _originalQueue = [];

  int _currentIndex = -1;
  int get currentIndex => _currentIndex;

  // Collections
  List<Track> _localTracks = [];
  List<Track> get localTracks => List.unmodifiable(_localTracks);

  List<Track> _favorites = [];
  List<Track> get favorites => List.unmodifiable(_favorites);

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  List<Track> _recentTracks = [];
  List<Track> get recentTracks => List.unmodifiable(_recentTracks);

  // YouTube Playlist Downloader State
  bool _isDownloadingPlaylist = false;
  bool get isDownloadingPlaylist => _isDownloadingPlaylist;

  String _downloadStatus = '';
  String get downloadStatus => _downloadStatus;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  int _downloadCurrent = 0;
  int get downloadCurrent => _downloadCurrent;

  int _downloadTotal = 0;
  int get downloadTotal => _downloadTotal;

  List<DownloadItemProgress> _downloadItems = [];
  List<DownloadItemProgress> get downloadItems => List.unmodifiable(_downloadItems);
  String? _lastDownloadDirectory;

  Playlist? _lastCreatedPlaylist;
  Playlist? get lastCreatedPlaylist => _lastCreatedPlaylist;

  AudioDownloadFormat _downloadFormat = AudioDownloadFormat.opus;
  AudioDownloadFormat get downloadFormat => _downloadFormat;

  int _downloadThreads = 8;
  int get downloadThreads => _downloadThreads;

  int _concurrentDownloads = 3;
  int get concurrentDownloads => _concurrentDownloads;

  Future<void> setDownloadFormat(AudioDownloadFormat format) async {
    _downloadFormat = format;
    await _storageService.saveDownloadFormat(format.id);
    notifyListeners();
  }

  Future<void> setDownloadThreads(int threads) async {
    _downloadThreads = threads;
    await _storageService.saveDownloadThreads(threads);
    notifyListeners();
  }

  Future<void> setConcurrentDownloads(int count) async {
    _concurrentDownloads = count.clamp(1, 10);
    await _storageService.saveConcurrentDownloads(_concurrentDownloads);
    notifyListeners();
  }

  String get defaultDownloadDirectory {
    if (!kIsWeb && Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      if (userProfile.isNotEmpty) {
        return '$userProfile\\Music\\YouTube_Indirilenler';
      }
    }
    return 'YouTube_Indirilenler';
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearErrorMessage() {
    _errorMessage = null;
  }

  PlayerViewModel() {
    _init();
  }

  Future<void> _init() async {
    await _storageService.init();

    // Load persisted data
    _localTracks = await _storageService.loadLocalTracks();
    _favorites = await _storageService.loadFavorites();
    _playlists = await _storageService.loadPlaylists();
    _recentTracks = await _storageService.loadRecentTracks();
    _volume = await _storageService.loadVolume();
    _playbackRate = await _storageService.loadPlaybackRate();
    _balance = await _storageService.loadBalance();
    _isShuffle = await _storageService.loadShuffle();
    final repIndex = await _storageService.loadRepeatMode();
    _repeatMode = RepeatMode.values[repIndex.clamp(0, RepeatMode.values.length - 1)];

    // Load Equalizer & App Settings
    _eqEnabled = await _storageService.loadEqEnabled();
    _eqPreset = await _storageService.loadEqPreset();
    _eqBands = await _storageService.loadEqBands();
    _customDownloadDir = await _storageService.loadCustomDownloadDir();
    _showVisualizer = await _storageService.loadShowVisualizer();
    _autoFetchLyrics = await _storageService.loadAutoFetchLyrics();

    // Restore last queue & active track
    final savedQueue = await _storageService.loadLastQueue();
    final savedTrackId = await _storageService.loadLastTrackId();
    if (savedQueue.isNotEmpty) {
      _queue = savedQueue;
      _originalQueue = List.from(savedQueue);
      if (savedTrackId != null) {
        final idx = _queue.indexWhere((t) => t.id == savedTrackId);
        if (idx != -1) {
          _currentIndex = idx;
          _currentTrack = _queue[idx];
          _totalDuration = _currentTrack!.duration;
        }
      }
    }

    // Self-healing: automatically repair any existing mojibake in loaded tracks & playlists
    bool tracksRepaired = false;
    for (int i = 0; i < _localTracks.length; i++) {
      final t = _localTracks[i];
      final cleanTitle = Track.fixMojibake(t.title);
      final cleanArtist = Track.fixMojibake(t.artist);
      if (cleanTitle != t.title || cleanArtist != t.artist) {
        _localTracks[i] = t.copyWith(title: cleanTitle, artist: cleanArtist);
        tracksRepaired = true;
      }
    }
    if (tracksRepaired) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    bool plRepaired = false;
    for (final p in _playlists) {
      final cleanName = Track.fixMojibake(p.name);
      if (cleanName != p.name) {
        p.name = cleanName;
        plRepaired = true;
      }
      for (int i = 0; i < p.tracks.length; i++) {
        final t = p.tracks[i];
        final cleanTitle = Track.fixMojibake(t.title);
        final cleanArtist = Track.fixMojibake(t.artist);
        if (cleanTitle != t.title || cleanArtist != t.artist) {
          p.tracks[i] = t.copyWith(title: cleanTitle, artist: cleanArtist);
          plRepaired = true;
        }
      }
    }
    if (plRepaired) {
      await _storageService.savePlaylists(_playlists);
    }

    if (!kIsWeb) {
      await _selfHealMissingLocalPaths();
      unawaited(refreshAudioCacheSize());
      unawaited(checkExternalEngines());
    }

    final savedFmt = await _storageService.loadDownloadFormat();
    if (savedFmt != null) {
      _downloadFormat = AudioDownloadFormat.fromId(savedFmt);
    }
    _downloadThreads = await _storageService.loadDownloadThreads();
    _concurrentDownloads = await _storageService.loadConcurrentDownloads();

    await _audioPlayerService.setVolume(_volume);
    await _audioPlayerService.setPlaybackRate(_playbackRate);
    await _audioPlayerService.setBalance(_balance);
    await _audioPlayerService.configureEqualizer(
      enabled: _eqEnabled,
      bands: _eqBands,
      hotSwap: false,
    );

    // Audio service listeners
    _audioPlayerService.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
      notifyListeners();
    });

    _audioPlayerService.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      // Check A-B Loop
      if (_loopStartA != null && _loopEndB != null && pos >= _loopEndB!) {
        seek(_loopStartA!);
      }
      notifyListeners();
    });

    _audioPlayerService.onDurationChanged.listen((dur) {
      _totalDuration = dur;
      if (dur > Duration.zero && _currentTrack != null && _currentTrack!.duration == Duration.zero) {
        _syncTrackDuration(_currentTrack!, dur);
      }
      notifyListeners();
    });

    _audioPlayerService.onPlayerComplete.listen((_) {
      _handleTrackCompleted();
    });

    notifyListeners();
  }

  String _normalizeTitleKey(String raw) {
    return raw
        .replaceAll(RegExp(r'\(MP3_\d+K\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\.(mp3|m4a|flac|wav|opus|ogg|webm)$', caseSensitive: false), '')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Automatically relinks any local track whose file extension changed (e.g. .flac -> .m4a)
  /// or whose audio file already exists in another local folder.
  Future<int> _selfHealMissingLocalPaths() async {
    int healedCount = 0;
    const exts = ['.m4a', '.mp3', '.flac', '.wav', '.opus', '.ogg', '.webm'];
    final Map<String, String> existingByTitleKey = {};

    for (final t in _localTracks) {
      if (t.isOnline) continue;
      final f = File(t.sourcePath);
      if (f.existsSync() && f.lengthSync() > 1024) {
        final key = _normalizeTitleKey(t.title);
        if (key.isNotEmpty) {
          existingByTitleKey[key] = f.path;
        }
      }
    }

    String? findReplacementPath(Track t) {
      if (t.isOnline) return null;
      final currentFile = File(t.sourcePath);
      if (currentFile.existsSync() && currentFile.lengthSync() > 1024) return null;

      final dot = t.sourcePath.lastIndexOf('.');
      final baseNoExt = dot != -1 ? t.sourcePath.substring(0, dot) : t.sourcePath;
      for (final ext in exts) {
        final cand = File('$baseNoExt$ext');
        if (cand.existsSync() && cand.lengthSync() > 1024) {
          return cand.path;
        }
      }

      final key = _normalizeTitleKey(t.title);
      if (key.isNotEmpty && existingByTitleKey.containsKey(key)) {
        return existingByTitleKey[key];
      }
      return null;
    }

    bool localUpdated = false;
    for (int i = 0; i < _localTracks.length; i++) {
      final rep = findReplacementPath(_localTracks[i]);
      if (rep != null && rep != _localTracks[i].sourcePath) {
        _localTracks[i] = _localTracks[i].copyWith(sourcePath: rep);
        localUpdated = true;
        healedCount++;
      }
    }
    if (localUpdated) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    bool plUpdated = false;
    for (final pl in _playlists) {
      for (int i = 0; i < pl.tracks.length; i++) {
        final rep = findReplacementPath(pl.tracks[i]);
        if (rep != null && rep != pl.tracks[i].sourcePath) {
          pl.tracks[i] = pl.tracks[i].copyWith(sourcePath: rep);
          plUpdated = true;
          healedCount++;
        }
      }
    }
    if (plUpdated) {
      await _storageService.savePlaylists(_playlists);
    }

    bool recUpdated = false;
    for (int i = 0; i < _recentTracks.length; i++) {
      final rep = findReplacementPath(_recentTracks[i]);
      if (rep != null && rep != _recentTracks[i].sourcePath) {
        _recentTracks[i] = _recentTracks[i].copyWith(sourcePath: rep);
        recUpdated = true;
      }
    }
    if (recUpdated) {
      await _storageService.saveRecentTracks(_recentTracks);
    }

    bool queueUpdated = false;
    for (int i = 0; i < _queue.length; i++) {
      final rep = findReplacementPath(_queue[i]);
      if (rep != null && rep != _queue[i].sourcePath) {
        _queue[i] = _queue[i].copyWith(sourcePath: rep);
        queueUpdated = true;
      }
    }
    for (int i = 0; i < _originalQueue.length; i++) {
      final rep = findReplacementPath(_originalQueue[i]);
      if (rep != null && rep != _originalQueue[i].sourcePath) {
        _originalQueue[i] = _originalQueue[i].copyWith(sourcePath: rep);
      }
    }
    if (_currentTrack != null) {
      final rep = findReplacementPath(_currentTrack!);
      if (rep != null && rep != _currentTrack!.sourcePath) {
        _currentTrack = _currentTrack!.copyWith(sourcePath: rep);
        queueUpdated = true;
      }
    }
    if (queueUpdated) {
      await _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
    }
    return healedCount;
  }

  Future<void> _relinkTrackSourcePath(Track target, String newSourcePath) async {
    final oldPath = target.sourcePath;
    if (_currentTrack?.id == target.id || _currentTrack?.sourcePath == oldPath) {
      _currentTrack = _currentTrack!.copyWith(sourcePath: newSourcePath);
    }

    bool localChanged = false;
    for (int i = 0; i < _localTracks.length; i++) {
      if (_localTracks[i].id == target.id || _localTracks[i].sourcePath == oldPath) {
        _localTracks[i] = _localTracks[i].copyWith(sourcePath: newSourcePath);
        localChanged = true;
      }
    }
    if (localChanged) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    bool plChanged = false;
    for (final pl in _playlists) {
      for (int i = 0; i < pl.tracks.length; i++) {
        if (pl.tracks[i].id == target.id || pl.tracks[i].sourcePath == oldPath) {
          pl.tracks[i] = pl.tracks[i].copyWith(sourcePath: newSourcePath);
          plChanged = true;
        }
      }
    }
    if (plChanged) {
      await _storageService.savePlaylists(_playlists);
    }

    bool recChanged = false;
    for (int i = 0; i < _recentTracks.length; i++) {
      if (_recentTracks[i].id == target.id || _recentTracks[i].sourcePath == oldPath) {
        _recentTracks[i] = _recentTracks[i].copyWith(sourcePath: newSourcePath);
        recChanged = true;
      }
    }
    if (recChanged) {
      await _storageService.saveRecentTracks(_recentTracks);
    }

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].id == target.id || _queue[i].sourcePath == oldPath) {
        _queue[i] = _queue[i].copyWith(sourcePath: newSourcePath);
      }
    }
    for (int i = 0; i < _originalQueue.length; i++) {
      if (_originalQueue[i].id == target.id || _originalQueue[i].sourcePath == oldPath) {
        _originalQueue[i] = _originalQueue[i].copyWith(sourcePath: newSourcePath);
      }
    }
  }

  Future<void> _syncTrackDuration(Track target, Duration realDuration) async {
    final updated = target.copyWith(duration: realDuration);
    if (_currentTrack?.id == target.id) {
      _currentTrack = updated;
    }
    bool localChanged = false;
    for (int i = 0; i < _localTracks.length; i++) {
      if (_localTracks[i].id == target.id || _localTracks[i].sourcePath == target.sourcePath) {
        _localTracks[i] = _localTracks[i].copyWith(duration: realDuration);
        localChanged = true;
      }
    }
    if (localChanged) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    bool plChanged = false;
    for (final pl in _playlists) {
      for (int i = 0; i < pl.tracks.length; i++) {
        if (pl.tracks[i].id == target.id || pl.tracks[i].sourcePath == target.sourcePath) {
          pl.tracks[i] = pl.tracks[i].copyWith(duration: realDuration);
          plChanged = true;
        }
      }
    }
    if (plChanged) {
      await _storageService.savePlaylists(_playlists);
    }

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].id == target.id || _queue[i].sourcePath == target.sourcePath) {
        _queue[i] = _queue[i].copyWith(duration: realDuration);
      }
    }
  }

  Future<void> _incrementPlayCount(Track target) async {
    final newCount = target.playCount + 1;
    final updated = target.copyWith(playCount: newCount);
    if (_currentTrack?.id == target.id) {
      _currentTrack = updated;
    }

    bool localChanged = false;
    for (int i = 0; i < _localTracks.length; i++) {
      if (_localTracks[i].id == target.id || _localTracks[i].sourcePath == target.sourcePath) {
        _localTracks[i] = _localTracks[i].copyWith(playCount: _localTracks[i].playCount + 1);
        localChanged = true;
      }
    }
    if (localChanged) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].id == target.id) {
        _queue[i] = _queue[i].copyWith(playCount: newCount);
      }
    }
  }

  // --- Playback Controls ---

  Future<void> playTrack(Track track, {List<Track>? newQueue}) async {
    _isLoading = true;
    _errorMessage = null;
    clearABLoop();
    notifyListeners();

    try {
      if (newQueue != null && newQueue.isNotEmpty) {
        _originalQueue = List.from(newQueue);
        if (!_originalQueue.any((t) => t.id == track.id)) {
          _originalQueue.insert(0, track);
        }
        if (_isShuffle && _originalQueue.length > 1) {
          final rest = _originalQueue.where((t) => t.id != track.id).toList()..shuffle();
          _queue = [track, ...rest];
          _currentIndex = 0;
        } else {
          _queue = List.from(_originalQueue);
          _currentIndex = _queue.indexWhere((t) => t.id == track.id);
        }
      } else {
        if (_queue.isEmpty && _originalQueue.isEmpty) {
          _originalQueue = _localTracks.isNotEmpty ? List.from(_localTracks) : [track];
          if (!_originalQueue.any((t) => t.id == track.id)) {
            _originalQueue.insert(0, track);
          }
        }
        if (!_queue.any((t) => t.id == track.id)) {
          _queue.add(track);
        }
        if (!_originalQueue.any((t) => t.id == track.id)) {
          _originalQueue.add(track);
        }
        _currentIndex = _queue.indexWhere((t) => t.id == track.id);
      }

      _currentTrack = track;

      // Increment play count & add to recents
      await _incrementPlayCount(track);
      _addToRecents(_currentTrack!);
      await _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);

      // Resolve stream URL (or recover/relink missing local file)
      final resolvedUri = await _onlineMusicService.resolveStreamUrl(
        track,
        localTracks: _localTracks,
      );
      if (resolvedUri == null || resolvedUri.isEmpty) {
        throw Exception('Müzik kaynağı çözümlenemedi.');
      }

      if (!kIsWeb && !track.isOnline && resolvedUri != track.sourcePath && File(resolvedUri).existsSync()) {
        await _relinkTrackSourcePath(track, resolvedUri);
      }

      await _audioPlayerService.playSource(
        resolvedUri: resolvedUri,
        isOnline: track.isOnline,
      );

      _isLoading = false;
      notifyListeners();

      if (!kIsWeb) {
        unawaited(refreshAudioCacheSize());
      }
      if (_autoFetchLyrics && (track.lyrics == null || track.lyrics!.trim().isEmpty)) {
        unawaited(fetchOnlineLyrics(track));
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Oynatma hatası: ${e.toString()}';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) {
      if (_queue.isNotEmpty) {
        await playTrack(_queue.first);
      } else if (_localTracks.isNotEmpty) {
        await playTrack(_localTracks.first, newQueue: _localTracks);
      }
      return;
    }

    if (_isPlaying) {
      await _audioPlayerService.pause();
    } else {
      if (_audioPlayerService.state == PlayerState.stopped || _audioPlayerService.state == PlayerState.completed) {
        await playTrack(_currentTrack!);
      } else {
        await _audioPlayerService.resume();
      }
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_currentIndex + 1 < _queue.length) {
      await playTrack(_queue[_currentIndex + 1]);
    } else if (_repeatMode == RepeatMode.all || (_isShuffle && _queue.length > 1)) {
      await playTrack(_queue.first);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    // If played more than 3 seconds, restart current track
    if (_currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex - 1 >= 0) {
      await playTrack(_queue[_currentIndex - 1]);
    } else if (_repeatMode == RepeatMode.all) {
      await playTrack(_queue.last);
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  Future<void> seekRelative(Duration offset) async {
    if (_totalDuration == Duration.zero) return;
    final targetMs = (_currentPosition + offset).inMilliseconds.clamp(0, _totalDuration.inMilliseconds);
    await seek(Duration(milliseconds: targetMs));
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _audioPlayerService.setVolume(_volume);
    await _storageService.saveVolume(_volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (isMuted) {
      await setVolume(_previousVolume > 0 ? _previousVolume : 0.8);
    } else {
      _previousVolume = _volume;
      await setVolume(0.0);
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate.clamp(0.5, 2.0);
    await _audioPlayerService.setPlaybackRate(_playbackRate);
    await _storageService.savePlaybackRate(_playbackRate);
    notifyListeners();
  }

  Future<void> setBalance(double bal) async {
    _balance = bal.clamp(-1.0, 1.0);
    await _audioPlayerService.setBalance(_balance);
    await _storageService.saveBalance(_balance);
    notifyListeners();
  }

  Future<void> resetAudioEffects() async {
    await setPlaybackRate(1.0);
    await setBalance(0.0);
    await resetEqualizer();
    clearABLoop();
  }

  // --- 5-Band Graphic Equalizer DSP Controls ---

  Future<void> toggleEqualizer([bool? enabled]) async {
    _eqEnabled = enabled ?? !_eqEnabled;
    await _storageService.saveEqEnabled(_eqEnabled);
    notifyListeners();
    await applyEqualizerChanges();
  }

  Future<void> setEqPreset(String presetKey) async {
    if (AudioPlayerService.eqPresets.containsKey(presetKey)) {
      _eqPreset = presetKey;
      _eqBands = List<double>.from(AudioPlayerService.eqPresets[presetKey]!);
      if (presetKey != 'flat' && !_eqEnabled) {
        _eqEnabled = true;
        await _storageService.saveEqEnabled(true);
      }
      await _storageService.saveEqPreset(_eqPreset);
      await _storageService.saveEqBands(_eqBands);
      notifyListeners();
      await applyEqualizerChanges();
    } else if (presetKey == 'custom') {
      _eqPreset = 'custom';
      await _storageService.saveEqPreset(_eqPreset);
      notifyListeners();
    }
  }

  Future<void> setEqBand(int index, double gainDb, {bool applyNow = true}) async {
    if (index < 0 || index >= 5) return;
    _eqBands[index] = gainDb.clamp(-12.0, 12.0);
    _eqPreset = 'custom';
    if (!_eqEnabled) {
      _eqEnabled = true;
      await _storageService.saveEqEnabled(true);
    }
    await _storageService.saveEqPreset(_eqPreset);
    await _storageService.saveEqBands(_eqBands);
    notifyListeners();
    if (applyNow) {
      await applyEqualizerChanges();
    }
  }

  Future<void> applyEqualizerChanges() async {
    _isProcessingEq = true;
    notifyListeners();
    try {
      await _audioPlayerService.configureEqualizer(
        enabled: _eqEnabled,
        bands: _eqBands,
        hotSwap: true,
      );
      if (!kIsWeb) {
        unawaited(refreshAudioCacheSize());
      }
    } finally {
      _isProcessingEq = false;
      notifyListeners();
    }
  }

  Future<void> resetEqualizer() async {
    _eqPreset = 'flat';
    _eqBands = [0.0, 0.0, 0.0, 0.0, 0.0];
    await _storageService.saveEqPreset(_eqPreset);
    await _storageService.saveEqBands(_eqBands);
    notifyListeners();
    await applyEqualizerChanges();
  }

  // --- A-B Loop Controls ---

  void setLoopPointA([Duration? pos]) {
    _loopStartA = pos ?? _currentPosition;
    if (_loopEndB != null && _loopEndB! <= _loopStartA!) {
      _loopEndB = null;
    }
    notifyListeners();
  }

  void setLoopPointB([Duration? pos]) {
    final candidate = pos ?? _currentPosition;
    _loopStartA ??= Duration.zero;
    if (candidate > _loopStartA!) {
      _loopEndB = candidate;
    }
    notifyListeners();
  }

  void clearABLoop() {
    if (_loopStartA != null || _loopEndB != null) {
      _loopStartA = null;
      _loopEndB = null;
      notifyListeners();
    }
  }

  // --- Sleep Timer Controls ---

  void setSleepTimer(Duration? duration, {bool afterCurrentTrack = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _stopAfterCurrentTrack = afterCurrentTrack;

    if (duration == null || afterCurrentTrack) {
      _sleepTimerRemaining = null;
      notifyListeners();
      return;
    }

    _sleepTimerRemaining = duration;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemaining == null) {
        timer.cancel();
        return;
      }
      final nextSec = _sleepTimerRemaining!.inSeconds - 1;
      if (nextSec <= 0) {
        timer.cancel();
        _sleepTimer = null;
        _sleepTimerRemaining = null;
        _audioPlayerService.pause();
        notifyListeners();
      } else {
        _sleepTimerRemaining = Duration(seconds: nextSec);
        notifyListeners();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerRemaining = null;
    _stopAfterCurrentTrack = false;
    notifyListeners();
  }

  // --- Queue Management ---

  void playNextInQueue(Track track) {
    if (_queue.isEmpty || _currentTrack == null) {
      playTrack(track);
      return;
    }
    final existingIdx = _queue.indexWhere((t) => t.id == track.id);
    if (existingIdx != -1) {
      if (existingIdx == _currentIndex) return;
      _queue.removeAt(existingIdx);
      if (existingIdx < _currentIndex) {
        _currentIndex--;
      }
    }
    final insertPos = (_currentIndex + 1).clamp(0, _queue.length);
    _queue.insert(insertPos, track);
    if (!_originalQueue.any((t) => t.id == track.id)) {
      _originalQueue.add(track);
    }
    _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
    notifyListeners();
  }

  void addToQueue(Track track) {
    if (_queue.isEmpty && _currentTrack == null) {
      playTrack(track);
      return;
    }
    if (!_queue.any((t) => t.id == track.id)) {
      _queue.add(track);
      if (!_originalQueue.any((t) => t.id == track.id)) {
        _originalQueue.add(track);
      }
      _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
      notifyListeners();
    }
  }

  void removeFromQueueAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) return; // Don't remove currently playing track
    final removed = _queue.removeAt(index);
    _originalQueue.removeWhere((t) => t.id == removed.id);
    if (index < _currentIndex) {
      _currentIndex--;
    }
    _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, _queue.length - 1);

    final currentId = _currentTrack?.id;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);

    if (currentId != null) {
      _currentIndex = _queue.indexWhere((t) => t.id == currentId);
    }
    _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
    notifyListeners();
  }

  void clearUpcomingQueue() {
    if (_currentTrack == null) {
      _queue.clear();
      _originalQueue.clear();
      _currentIndex = -1;
    } else {
      _queue = [_currentTrack!];
      _originalQueue = [_currentTrack!];
      _currentIndex = 0;
    }
    _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      if (_queue.length > 1) {
        _originalQueue = List.from(_queue);
        if (_currentTrack != null) {
          final rest = _queue.where((t) => t.id != _currentTrack!.id).toList()..shuffle();
          _queue = [_currentTrack!, ...rest];
          _currentIndex = 0;
        } else {
          _queue.shuffle();
        }
      }
    } else {
      if (_originalQueue.isNotEmpty) {
        _queue = List.from(_originalQueue);
        if (_currentTrack != null) {
          final idx = _queue.indexWhere((t) => t.id == _currentTrack!.id);
          if (idx != -1) {
            _currentIndex = idx;
          } else {
            _queue.insert(0, _currentTrack!);
            _currentIndex = 0;
          }
        } else {
          _currentIndex = 0;
        }
      }
    }
    await _storageService.saveShuffle(_isShuffle);
    await _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);
    notifyListeners();
  }

  Future<void> toggleRepeatMode() async {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    await _storageService.saveRepeatMode(_repeatMode.index);
    notifyListeners();
  }

  void _handleTrackCompleted() {
    if (_stopAfterCurrentTrack) {
      _stopAfterCurrentTrack = false;
      _audioPlayerService.pause();
      notifyListeners();
      return;
    }
    if (_repeatMode == RepeatMode.one && _currentTrack != null) {
      playTrack(_currentTrack!);
    } else {
      next();
    }
  }

  // --- Local Music Import ---

  Future<List<Track>> pickAudioFiles() async {
    return _filePickerService.pickAudioFiles();
  }

  Future<int> pickLocalFiles() async {
    final picked = await _filePickerService.pickAudioFiles();
    if (picked.isEmpty) return 0;

    int addedCount = 0;
    for (final track in picked) {
      if (!_localTracks.any((t) => t.sourcePath == track.sourcePath)) {
        _localTracks.add(track);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await _storageService.saveLocalTracks(_localTracks);
      notifyListeners();
    }
    return addedCount;
  }

  Future<int> pickLocalFolder() async {
    final scanned = await _filePickerService.pickFolderAndScan();
    if (scanned.isEmpty) return 0;

    int addedCount = 0;
    for (final track in scanned) {
      if (!_localTracks.any((t) => t.sourcePath == track.sourcePath)) {
        _localTracks.add(track);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await _storageService.saveLocalTracks(_localTracks);
      notifyListeners();
    }
    return addedCount;
  }

  Future<void> removeTrackFromLibrary(Track track) async {
    _localTracks.removeWhere((t) => t.id == track.id);
    await _storageService.saveLocalTracks(_localTracks);
    notifyListeners();
  }

  // --- YouTube Playlist Downloader ---

  Future<bool> downloadYouTubePlaylist(
    String urlOrId, {
    String? customDir,
    AudioDownloadFormat? format,
    int? threads,
    int? concurrentDownloads,
  }) async {
    final cleanInput = urlOrId.trim();
    if (cleanInput.isEmpty) return false;

    _isDownloadingPlaylist = true;
    _downloadStatus = 'İndirme başlatılıyor...';
    _downloadProgress = 0.0;
    _downloadCurrent = 0;
    _downloadTotal = 1;
    _downloadItems = [];
    _errorMessage = null;
    notifyListeners();

    try {
      final targetDir = (customDir != null && customDir.trim().isNotEmpty)
          ? customDir.trim()
          : (_customDownloadDir.trim().isNotEmpty
              ? _customDownloadDir.trim()
              : defaultDownloadDirectory);
      _lastDownloadDirectory = targetDir;

      Playlist? activePlaylist;

      final result = await _onlineMusicService.downloadPlaylist(
        urlOrId: cleanInput,
        targetDirectory: targetDir,
        format: format ?? _downloadFormat,
        threads: threads ?? _downloadThreads,
        concurrentDownloads: concurrentDownloads ?? _concurrentDownloads,
        onProgress: (status, progress, current, total) {
          _downloadStatus = status;
          _downloadProgress = progress;
          _downloadCurrent = current;
          _downloadTotal = total;
          notifyListeners();
        },
        onItemsUpdated: (items) {
          _downloadItems = items;
          notifyListeners();
        },
        onPlaylistTitleDetected: (title) async {
          // Immediately create playlist so it appears in "Çalma Listeleri" right away!
          if (activePlaylist == null) {
            activePlaylist = Playlist(
              id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
              name: title,
              tracks: [],
            );
            _playlists.add(activePlaylist!);
            _lastCreatedPlaylist = activePlaylist;
            await _storageService.savePlaylists(_playlists);
            notifyListeners();
          }
        },
        onTrackDownloaded: (track) async {
          // Add to local library immediately as each song finishes
          if (!_localTracks.any((t) => t.sourcePath == track.sourcePath)) {
            _localTracks.add(track);
            await _storageService.saveLocalTracks(_localTracks);
          }
          // Add to active playlist immediately so user can play it while others download
          if (activePlaylist != null && !activePlaylist!.tracks.any((t) => t.sourcePath == track.sourcePath)) {
            activePlaylist!.tracks.add(track);
            await _storageService.savePlaylists(_playlists);
          }
          notifyListeners();
        },
      );

      // Final synchronization after all parallel downloads complete
      if (activePlaylist == null && result.downloadedTracks.isNotEmpty) {
        activePlaylist = Playlist(
          id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
          name: Track.fixMojibake(result.playlistTitle),
          tracks: result.downloadedTracks,
        );
        _playlists.add(activePlaylist!);
        await _storageService.savePlaylists(_playlists);
      } else if (activePlaylist != null) {
        activePlaylist!.name = Track.fixMojibake(result.playlistTitle);
        activePlaylist!.tracks = result.downloadedTracks;
        await _storageService.savePlaylists(_playlists);
      }

      int newAdded = 0;
      for (final track in result.downloadedTracks) {
        if (!_localTracks.any((t) => t.sourcePath == track.sourcePath)) {
          _localTracks.add(track);
          newAdded++;
        }
      }
      if (newAdded > 0) {
        await _storageService.saveLocalTracks(_localTracks);
      }

      _lastCreatedPlaylist = activePlaylist;
      _isDownloadingPlaylist = false;
      final failedCount = _downloadItems.where((i) => i.status == DownloadItemStatus.failed).length;
      if (failedCount > 0) {
        _downloadStatus = 'Tamamlandı! ${result.downloadedTracks.length} parça eklendi ($failedCount parça YouTube engeli/telif nedeniyle indirilemedi).';
      } else {
        _downloadStatus = 'Tamamlandı! "${result.playlistTitle}" kütüphaneye ve çalma listelerine eklendi.';
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isDownloadingPlaylist = false;
      _downloadStatus = 'Hata: $e';
      _errorMessage = 'YouTube indirme hatası: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> retryDownloadItem(DownloadItemProgress item) async {
    final idx = _downloadItems.indexWhere((i) => i.id == item.id);
    if (idx == -1) return false;

    _downloadItems[idx].status = DownloadItemStatus.downloading;
    _downloadItems[idx].errorMessage = null;
    notifyListeners();

    try {
      final targetDir = _lastDownloadDirectory ??
          (_customDownloadDir.trim().isNotEmpty
              ? _customDownloadDir.trim()
              : defaultDownloadDirectory);
      final plTitle = _lastCreatedPlaylist?.name ?? 'YouTube İndirilenler';

      final res = await _onlineMusicService.retrySingleTrack(
        videoId: item.id,
        fallbackTitle: item.title,
        playlistTitle: plTitle,
        targetDirectory: targetDir,
        format: _downloadFormat,
        threads: _downloadThreads,
      );

      if (res.track != null) {
        _downloadItems[idx].status = DownloadItemStatus.completed;
        _downloadItems[idx].errorMessage = null;
        _downloadItems[idx].rawLog = null;

        // Add to local tracks if not already present
        if (!_localTracks.any((t) => t.sourcePath == res.track!.sourcePath)) {
          _localTracks.add(res.track!);
          await _storageService.saveLocalTracks(_localTracks);
        }

        // Add to active playlist
        if (_lastCreatedPlaylist != null && !_lastCreatedPlaylist!.tracks.any((t) => t.sourcePath == res.track!.sourcePath)) {
          _lastCreatedPlaylist!.tracks.add(res.track!);
          await _storageService.savePlaylists(_playlists);
        }

        notifyListeners();
        return true;
      } else {
        _downloadItems[idx].status = DownloadItemStatus.failed;
        _downloadItems[idx].errorMessage = res.errorMessage ?? 'Tekrar deneme başarısız oldu.';
        _downloadItems[idx].rawLog = res.rawLog;
        notifyListeners();
        return false;
      }
    } catch (e, stack) {
      _downloadItems[idx].status = DownloadItemStatus.failed;
      _downloadItems[idx].errorMessage = 'Hata: $e';
      _downloadItems[idx].rawLog = '$e\n$stack';
      notifyListeners();
      return false;
    }
  }

  Future<void> retryAllFailedDownloads() async {
    final failed = _downloadItems.where((i) => i.status == DownloadItemStatus.failed).toList();
    for (final item in failed) {
      await retryDownloadItem(item);
    }
  }

  // --- Favorites ---

  bool isFavorite(Track track) {
    return _favorites.any((t) => t.id == track.id);
  }

  Future<void> toggleFavorite(Track track) async {
    final index = _favorites.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      _favorites.removeAt(index);
      track.isFavorite = false;
    } else {
      track.isFavorite = true;
      _favorites.add(track);
    }
    await _storageService.saveFavorites(_favorites);
    notifyListeners();
  }

  // --- Playlists ---

  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    if (playlist.tracks.isEmpty) return;
    final index = (startIndex >= 0 && startIndex < playlist.tracks.length) ? startIndex : 0;
    await playTrack(playlist.tracks[index], newQueue: playlist.tracks);
  }

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    final newPlaylist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
    );
    _playlists.add(newPlaylist);
    await _storageService.savePlaylists(_playlists);
    notifyListeners();
    return newPlaylist;
  }

  Future<Playlist> createPlaylistWithTracks(String name, List<Track> tracks, {String? description}) async {
    final newPlaylist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      tracks: List.of(tracks),
    );
    _playlists.add(newPlaylist);
    await _storageService.savePlaylists(_playlists);

    bool localAdded = false;
    for (final track in tracks) {
      if (!track.isOnline &&
          !_localTracks.any((t) => t.id == track.id || t.sourcePath == track.sourcePath)) {
        _localTracks.add(track);
        localAdded = true;
      }
    }
    if (localAdded) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    notifyListeners();
    return newPlaylist;
  }

  Future<int> addTracksToPlaylist(String playlistId, List<Track> tracks) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return 0;

    final playlist = _playlists[index];
    int added = 0;
    bool localAdded = false;
    for (final track in tracks) {
      if (!playlist.tracks.any((t) => t.sourcePath == track.sourcePath)) {
        playlist.tracks.add(track);
        added++;
      }
      if (!track.isOnline &&
          !_localTracks.any((t) => t.id == track.id || t.sourcePath == track.sourcePath)) {
        _localTracks.add(track);
        localAdded = true;
      }
    }
    if (localAdded) {
      await _storageService.saveLocalTracks(_localTracks);
    }
    if (added > 0 || localAdded) {
      if (added > 0) {
        await _storageService.savePlaylists(_playlists);
      }
      notifyListeners();
    }
    return added;
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _storageService.savePlaylists(_playlists);
    notifyListeners();
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.tracks.any((t) => t.id == track.id)) {
      playlist.tracks.add(track);
      await _storageService.savePlaylists(_playlists);
      notifyListeners();
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, Track track) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.tracks.removeWhere((t) => t.id == track.id);
    await _storageService.savePlaylists(_playlists);
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName, {String? description}) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx].name = Track.fixMojibake(newName.trim());
    if (description != null) {
      _playlists[idx].description = description.trim();
    }
    await _storageService.savePlaylists(_playlists);
    notifyListeners();
  }

  Future<void> reorderPlaylistTracks(String playlistId, int oldIndex, int newIndex) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final tracks = _playlists[idx].tracks;
    if (oldIndex < 0 || oldIndex >= tracks.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, tracks.length - 1);
    final item = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, item);
    await _storageService.savePlaylists(_playlists);
    notifyListeners();
  }

  Future<String?> exportPlaylistAsM3U(Playlist playlist) async {
    return _filePickerService.exportPlaylistToM3U(playlist);
  }

  Future<Playlist?> importPlaylistFromM3U() async {
    final pl = await _filePickerService.importM3UPlaylist();
    if (pl != null) {
      _playlists.add(pl);
      await _storageService.savePlaylists(_playlists);
      // Also add local tracks to library if not already present
      bool addedLocal = false;
      for (final t in pl.tracks) {
        if (!t.isOnline && !_localTracks.any((lt) => lt.sourcePath == t.sourcePath)) {
          _localTracks.add(t);
          addedLocal = true;
        }
      }
      if (addedLocal) {
        await _storageService.saveLocalTracks(_localTracks);
      }
      notifyListeners();
    }
    return pl;
  }

  // --- Track Metadata Editing & File Operations ---

  Future<void> updateTrackMetadata(
    Track target, {
    required String title,
    required String artist,
    String? album,
    bool clearAlbum = false,
    String? lyrics,
    bool clearLyrics = false,
  }) async {
    final cleanTitle = Track.fixMojibake(title.trim());
    final cleanArtist = Track.fixMojibake(artist.trim());
    final shouldClearAlbum = clearAlbum || (album != null && album.trim().isEmpty);
    final cleanAlbum = (!shouldClearAlbum && album != null) ? Track.fixMojibake(album.trim()) : null;
    final shouldClearLyrics = clearLyrics || (lyrics != null && lyrics.trim().isEmpty);
    final cleanLyrics = (!shouldClearLyrics && lyrics != null) ? lyrics.trim() : null;

    Track applyChanges(Track t) {
      return t.copyWith(
        title: cleanTitle.isNotEmpty ? cleanTitle : t.title,
        artist: cleanArtist.isNotEmpty ? cleanArtist : t.artist,
        album: cleanAlbum,
        clearAlbum: shouldClearAlbum,
        lyrics: cleanLyrics,
        clearLyrics: shouldClearLyrics,
      );
    }

    if (_currentTrack != null &&
        (_currentTrack!.id == target.id || _currentTrack!.sourcePath == target.sourcePath)) {
      _currentTrack = applyChanges(_currentTrack!);
    }

    bool localModified = false;
    for (int i = 0; i < _localTracks.length; i++) {
      if (_localTracks[i].id == target.id || _localTracks[i].sourcePath == target.sourcePath) {
        _localTracks[i] = applyChanges(_localTracks[i]);
        localModified = true;
      }
    }
    if (localModified) {
      await _storageService.saveLocalTracks(_localTracks);
    }

    bool favModified = false;
    for (int i = 0; i < _favorites.length; i++) {
      if (_favorites[i].id == target.id || _favorites[i].sourcePath == target.sourcePath) {
        _favorites[i] = applyChanges(_favorites[i]);
        favModified = true;
      }
    }
    if (favModified) {
      await _storageService.saveFavorites(_favorites);
    }

    bool plModified = false;
    for (final pl in _playlists) {
      for (int i = 0; i < pl.tracks.length; i++) {
        if (pl.tracks[i].id == target.id || pl.tracks[i].sourcePath == target.sourcePath) {
          pl.tracks[i] = applyChanges(pl.tracks[i]);
          plModified = true;
        }
      }
    }
    if (plModified) {
      await _storageService.savePlaylists(_playlists);
    }

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].id == target.id || _queue[i].sourcePath == target.sourcePath) {
        _queue[i] = applyChanges(_queue[i]);
      }
    }

    for (int i = 0; i < _originalQueue.length; i++) {
      if (_originalQueue[i].id == target.id || _originalQueue[i].sourcePath == target.sourcePath) {
        _originalQueue[i] = applyChanges(_originalQueue[i]);
      }
    }
    await _storageService.saveLastSession(queue: _queue, currentTrackId: _currentTrack?.id);

    for (int i = 0; i < _recentTracks.length; i++) {
      if (_recentTracks[i].id == target.id || _recentTracks[i].sourcePath == target.sourcePath) {
        _recentTracks[i] = applyChanges(_recentTracks[i]);
      }
    }
    await _storageService.saveRecentTracks(_recentTracks);
    notifyListeners();
  }

  Future<bool> revealInExplorer(Track track) async {
    if (kIsWeb || track.isOnline || track.sourcePath.isEmpty) return false;
    try {
      if (Platform.isWindows) {
        final file = File(track.sourcePath);
        if (await file.exists()) {
          await Process.run('explorer.exe', ['/select,${track.sourcePath}']);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error revealing file in Explorer: $e');
    }
    return false;
  }

  // --- Recents ---

  void _addToRecents(Track track) {
    _recentTracks.removeWhere((t) => t.id == track.id);
    _recentTracks.insert(0, track);
    if (_recentTracks.length > 50) {
      _recentTracks = _recentTracks.sublist(0, 50);
    }
    _storageService.saveRecentTracks(_recentTracks);
  }

  Future<void> clearRecentHistory() async {
    _recentTracks.clear();
    await _storageService.saveRecentTracks(_recentTracks);
    notifyListeners();
  }

  // --- Lyrics, Mini Player & App Settings / Maintenance ---

  Future<String?> fetchOnlineLyrics(Track track) async {
    if (_isFetchingLyrics) return null;
    _isFetchingLyrics = true;
    notifyListeners();

    try {
      final lyrics = await _onlineMusicService.fetchLyricsOnline(track.title, track.artist);
      if (lyrics != null && lyrics.trim().isNotEmpty) {
        await updateTrackMetadata(
          track,
          title: track.title,
          artist: track.artist,
          album: track.album,
          lyrics: lyrics,
        );
      }
      _isFetchingLyrics = false;
      notifyListeners();
      return lyrics;
    } catch (_) {
      _isFetchingLyrics = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> pickCustomDownloadDir() async {
    if (kIsWeb) return;
    try {
      final selected = await FilePicker.getDirectoryPath(
        dialogTitle: 'İndirme Klasörü Seçin',
      );
      if (selected != null && selected.trim().isNotEmpty) {
        _customDownloadDir = selected.trim();
        await _storageService.saveCustomDownloadDir(_customDownloadDir);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking custom download directory: $e');
    }
  }

  Future<void> openDownloadDirInExplorer() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      final dirPath = _customDownloadDir.trim().isNotEmpty
          ? _customDownloadDir.trim()
          : defaultDownloadDirectory;
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      await Process.run('explorer.exe', [dir.path]);
    } catch (e) {
      debugPrint('Error opening download directory in Explorer: $e');
    }
  }

  Future<void> setShowVisualizer(bool value) async {
    _showVisualizer = value;
    await _storageService.saveShowVisualizer(value);
    notifyListeners();
  }

  Future<void> setAutoFetchLyrics(bool value) async {
    _autoFetchLyrics = value;
    await _storageService.saveAutoFetchLyrics(value);
    notifyListeners();
  }

  Future<void> refreshAudioCacheSize() async {
    if (kIsWeb) return;
    try {
      final cacheDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}antigravity_audio_cache',
      );
      if (!cacheDir.existsSync()) {
        _audioCacheSizeMb = 0.0;
        notifyListeners();
        return;
      }
      int totalBytes = 0;
      for (final entity in cacheDir.listSync()) {
        if (entity is File) {
          try {
            totalBytes += entity.lengthSync();
          } catch (_) {}
        }
      }
      _audioCacheSizeMb = totalBytes / (1024 * 1024);
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating audio cache size: $e');
    }
  }

  Future<int> clearAudioCache() async {
    if (kIsWeb) return 0;
    int deletedCount = 0;
    try {
      final cacheDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}antigravity_audio_cache',
      );
      if (cacheDir.existsSync()) {
        for (final entity in cacheDir.listSync()) {
          if (entity is File) {
            try {
              entity.deleteSync();
              deletedCount++;
            } catch (_) {
              // Ignore currently playing/locked cache file
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing audio cache: $e');
    }
    await refreshAudioCacheSize();
    return deletedCount;
  }

  Future<int> runLibraryMaintenance() async {
    int fixedCount = 0;
    if (!kIsWeb) {
      fixedCount += await _selfHealMissingLocalPaths();
    }

    bool localModified = false;
    for (int i = 0; i < _localTracks.length; i++) {
      final t = _localTracks[i];
      final cleanTitle = Track.fixMojibake(t.title);
      final cleanArtist = Track.fixMojibake(t.artist);
      final cleanAlbum = t.album != null ? Track.fixMojibake(t.album!) : null;
      if (cleanTitle != t.title || cleanArtist != t.artist || cleanAlbum != t.album) {
        _localTracks[i] = t.copyWith(title: cleanTitle, artist: cleanArtist, album: cleanAlbum);
        localModified = true;
        fixedCount++;
      }
    }

    // Deduplicate localTracks by sourcePath
    final seenPaths = <String>{};
    final deduped = <Track>[];
    for (final t in _localTracks) {
      if (seenPaths.add(t.sourcePath)) {
        deduped.add(t);
      } else {
        fixedCount++;
        localModified = true;
      }
    }
    if (localModified) {
      _localTracks = deduped;
      await _storageService.saveLocalTracks(_localTracks);
    }

    bool plModified = false;
    for (final pl in _playlists) {
      final cleanName = Track.fixMojibake(pl.name);
      if (cleanName != pl.name) {
        pl.name = cleanName;
        plModified = true;
        fixedCount++;
      }
      for (int i = 0; i < pl.tracks.length; i++) {
        final t = pl.tracks[i];
        final cleanTitle = Track.fixMojibake(t.title);
        final cleanArtist = Track.fixMojibake(t.artist);
        if (cleanTitle != t.title || cleanArtist != t.artist) {
          pl.tracks[i] = t.copyWith(title: cleanTitle, artist: cleanArtist);
          plModified = true;
          fixedCount++;
        }
      }
    }
    if (plModified) {
      await _storageService.savePlaylists(_playlists);
    }

    notifyListeners();
    return fixedCount;
  }

  Future<void> resetAllSettingsToDefault() async {
    _eqEnabled = false;
    _eqPreset = 'flat';
    _eqBands = [0.0, 0.0, 0.0, 0.0, 0.0];
    await _storageService.saveEqEnabled(false);
    await _storageService.saveEqPreset('flat');
    await _storageService.saveEqBands(_eqBands);
    await _audioPlayerService.configureEqualizer(
      enabled: false,
      bands: _eqBands,
      hotSwap: true,
    );

    await setPlaybackRate(1.0);
    await setBalance(0.0);
    await setVolume(0.8);
    clearABLoop();

    _customDownloadDir = '';
    await _storageService.saveCustomDownloadDir('');
    await setDownloadFormat(AudioDownloadFormat.opus);
    await setDownloadThreads(8);
    await setConcurrentDownloads(3);
    await setShowVisualizer(true);
    await setAutoFetchLyrics(true);
    notifyListeners();
  }

  Future<void> checkExternalEngines() async {
    if (kIsWeb) {
      _isFfmpegAvailable = false;
      _isYtDlpAvailable = false;
      notifyListeners();
      return;
    }
    _isFfmpegAvailable = await _audioPlayerService.isFfmpegInstalled();
    _isYtDlpAvailable = await _checkYtDlpInstalled();
    notifyListeners();
  }

  Future<bool> _checkYtDlpInstalled() async {
    try {
      final res = await Process.run('where.exe', ['yt-dlp']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split(RegExp(r'[\r\n]+'));
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && File(trimmed).existsSync()) {
            return true;
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
      if (File(p).existsSync()) return true;
    }
    return false;
  }

  Future<void> toggleMiniPlayerMode() async {
    _isMiniPlayer = !_isMiniPlayer;
    notifyListeners();

    if (!kIsWeb && Platform.isWindows) {
      try {
        await windowManager.ensureInitialized();
        if (_isMiniPlayer) {
          await windowManager.setMinimumSize(const Size(360, 180));
          await windowManager.setSize(const Size(420, 210));
          await windowManager.setAlwaysOnTop(true);
        } else {
          await windowManager.setAlwaysOnTop(false);
          await windowManager.setMinimumSize(const Size(800, 600));
          await windowManager.setSize(const Size(1220, 780));
          await windowManager.center();
        }
      } catch (e) {
        debugPrint('Mini player window resize warning: $e');
      }
    }
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sleepTimer?.cancel();
    _audioPlayerService.dispose();
    _onlineMusicService.dispose();
    super.dispose();
  }
}

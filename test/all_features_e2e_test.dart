import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:antigravity_music/main.dart';
import 'package:antigravity_music/models/track.dart';
import 'package:antigravity_music/models/playlist.dart';
import 'package:antigravity_music/services/audio_player_service.dart';
import 'package:antigravity_music/services/file_picker_service.dart';
import 'package:antigravity_music/services/online_music_service.dart';
import 'package:antigravity_music/viewmodels/player_viewmodel.dart';

class FakeAudioplayersPlatform extends AudioplayersPlatformInterface {
  final Map<String, StreamController<AudioEvent>> _controllers = {};

  @override
  Future<void> create(String playerId) async {
    _controllers.putIfAbsent(playerId, () => StreamController<AudioEvent>.broadcast());
  }

  @override
  Future<void> dispose(String playerId) async {
    await _controllers[playerId]?.close();
    _controllers.remove(playerId);
  }

  @override
  Future<void> emitError(String playerId, String code, String message) async {}

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;

  @override
  Future<int?> getDuration(String playerId) async => 210000;

  @override
  Stream<AudioEvent> getEventStream(String playerId) {
    return _controllers.putIfAbsent(playerId, () => StreamController<AudioEvent>.broadcast()).stream;
  }

  @override
  Future<void> pause(String playerId) async {}

  @override
  Future<void> release(String playerId) async {}

  @override
  Future<void> resume(String playerId) async {}

  @override
  Future<void> seek(String playerId, Duration position) async {
    _controllers[playerId]?.add(const AudioEvent(eventType: AudioEventType.seekComplete));
  }

  @override
  Future<void> setAudioContext(String playerId, AudioContext context) async {}

  @override
  Future<void> setBalance(String playerId, double balance) async {}

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes, {String? mimeType}) async {
    _controllers[playerId]?.add(const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true));
  }

  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal, String? mimeType}) async {
    _controllers[playerId]?.add(const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true));
    _controllers[playerId]?.add(const AudioEvent(eventType: AudioEventType.duration, duration: Duration(seconds: 210)));
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {}

  @override
  Future<void> stop(String playerId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleLocalFile1;
  late File sampleLocalFile2;
  late File sampleLocalFile3;
  late File sampleLocalFile4;

  setUpAll(() {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();

    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall call) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall call) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      (MethodCall call) async => true,
    );

    // Create temporary mock audio files (> 1024 bytes) so local file checks pass
    tempDir = Directory.systemTemp.createTempSync('antigravity_test_media_');
    final dummyBytes = Uint8List(2048);
    sampleLocalFile1 = File('${tempDir.path}/track1.mp3')..writeAsBytesSync(dummyBytes);
    sampleLocalFile2 = File('${tempDir.path}/track2.mp3')..writeAsBytesSync(dummyBytes);
    sampleLocalFile3 = File('${tempDir.path}/track3.mp3')..writeAsBytesSync(dummyBytes);
    sampleLocalFile4 = File('${tempDir.path}/track4.mp3')..writeAsBytesSync(dummyBytes);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Track createSampleTrack(String id, String title, String artist, String album, String path, {Duration? duration}) {
    return Track(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration ?? const Duration(minutes: 3, seconds: 30),
      sourcePath: path,
      isOnline: false,
      addedAt: DateTime(2025, 1, int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1),
    );
  }

  Future<PlayerViewModel> createTestViewModel({
    List<Track>? initialQueue,
    String? activeTrackId,
    List<Track>? localTracks,
    List<Track>? favorites,
    List<Playlist>? playlists,
    List<Track>? recentTracks,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (initialQueue != null)
        'app_last_queue': jsonEncode(initialQueue.map((t) => t.toJson()).toList()),
      'app_last_track_id': ?activeTrackId,
      if (localTracks != null)
        'app_local_tracks': jsonEncode(localTracks.map((t) => t.toJson()).toList()),
      if (favorites != null)
        'app_favorites': jsonEncode(favorites.map((t) => t.toJson()).toList()),
      if (playlists != null)
        'app_playlists': jsonEncode(playlists.map((p) => p.toJson()).toList()),
      if (recentTracks != null)
        'app_recent_tracks': jsonEncode(recentTracks.map((t) => t.toJson()).toList()),
    });
    final vm = PlayerViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return vm;
  }

  group('1. Player & Bottom Bar Controls', () {
    test('Play, Pause, Resume, togglePlayPause', () async {
      final t1 = createSampleTrack('1', 'Şarkı 1', 'Sanatçı 1', 'Albüm 1', sampleLocalFile1.path);
      final vm = await createTestViewModel(initialQueue: [t1], activeTrackId: t1.id);

      expect(vm.currentTrack?.id, '1');
      expect(vm.currentIndex, 0);

      // Play track
      await vm.playTrack(t1);
      expect(vm.currentTrack?.id, '1');
      expect(vm.recentTracks.any((t) => t.id == '1'), isTrue);

      // Pause
      await vm.pause();
      // Resume
      await vm.resume();

      // togglePlayPause
      await vm.togglePlayPause();
      await vm.togglePlayPause();

      vm.dispose();
    });

    test('Next & Previous navigation with repeat mode and playback position logic', () async {
      final t1 = createSampleTrack('1', 'A', 'Art 1', 'Alb 1', sampleLocalFile1.path);
      final t2 = createSampleTrack('2', 'B', 'Art 2', 'Alb 2', sampleLocalFile2.path);
      final t3 = createSampleTrack('3', 'C', 'Art 3', 'Alb 3', sampleLocalFile3.path);

      final vm = await createTestViewModel(
        initialQueue: [t1, t2, t3],
        activeTrackId: t1.id,
      );

      expect(vm.currentIndex, 0);
      expect(vm.currentTrack?.id, '1');

      // Next -> Track 2
      await vm.next();
      expect(vm.currentIndex, 1);
      expect(vm.currentTrack?.id, '2');

      // Next -> Track 3
      await vm.next();
      expect(vm.currentIndex, 2);
      expect(vm.currentTrack?.id, '3');

      // End of queue with repeatMode == off -> remains at end
      await vm.next();
      expect(vm.currentIndex, 2);

      // Switch repeatMode to all -> Next wraps around to index 0 (Track 1)
      await vm.toggleRepeatMode(); // off -> all
      expect(vm.repeatMode, RepeatMode.all);
      await vm.next();
      expect(vm.currentIndex, 0);
      expect(vm.currentTrack?.id, '1');

      // Previous from index 0 with repeatMode == all wraps to last (Track 3)
      await vm.previous();
      expect(vm.currentIndex, 2);
      expect(vm.currentTrack?.id, '3');

      // Previous from index 2 goes to index 1 (Track 2)
      await vm.previous();
      expect(vm.currentIndex, 1);
      expect(vm.currentTrack?.id, '2');

      vm.dispose();
    });

    test('Shuffle Mode with Queue Preservation: toggling preserves active track at index 0 and restores original queue', () async {
      final t1 = createSampleTrack('1', 'T1', 'A1', 'Alb1', sampleLocalFile1.path);
      final t2 = createSampleTrack('2', 'T2', 'A2', 'Alb2', sampleLocalFile2.path);
      final t3 = createSampleTrack('3', 'T3', 'A3', 'Alb3', sampleLocalFile3.path);
      final t4 = createSampleTrack('4', 'T4', 'A4', 'Alb4', sampleLocalFile4.path);

      final vm = await createTestViewModel(
        initialQueue: [t1, t2, t3, t4],
        activeTrackId: t2.id,
      );

      expect(vm.isShuffle, isFalse);
      expect(vm.currentIndex, 1);
      expect(vm.currentTrack?.id, '2');

      // Enable shuffle: active track '2' moves to index 0, all 4 elements stay in queue
      await vm.toggleShuffle();
      expect(vm.isShuffle, isTrue);
      expect(vm.currentIndex, 0);
      expect(vm.queue.first.id, '2');
      expect(vm.queue.map((t) => t.id).toSet(), {'1', '2', '3', '4'});

      // Disable shuffle: original queue restored [1, 2, 3, 4] and currentIndex == 1 restored
      await vm.toggleShuffle();
      expect(vm.isShuffle, isFalse);
      expect(vm.queue.map((t) => t.id).toList(), ['1', '2', '3', '4']);
      expect(vm.currentIndex, 1);
      expect(vm.currentTrack?.id, '2');

      vm.dispose();
    });

    test('Repeat Modes: off -> all -> one -> off', () async {
      final vm = await createTestViewModel();
      expect(vm.repeatMode, RepeatMode.off);

      await vm.toggleRepeatMode();
      expect(vm.repeatMode, RepeatMode.all);

      await vm.toggleRepeatMode();
      expect(vm.repeatMode, RepeatMode.one);

      await vm.toggleRepeatMode();
      expect(vm.repeatMode, RepeatMode.off);

      vm.dispose();
    });

    test('Volume & Mute controls with clamping and restore', () async {
      final vm = await createTestViewModel();

      await vm.setVolume(0.65);
      expect(vm.volume, 0.65);
      expect(vm.isMuted, isFalse);

      // Clamping
      await vm.setVolume(1.8);
      expect(vm.volume, 1.0);
      await vm.setVolume(-0.4);
      expect(vm.volume, 0.0);
      expect(vm.isMuted, isTrue);

      // Set to 0.70 then mute toggle
      await vm.setVolume(0.70);
      expect(vm.volume, 0.70);

      await vm.toggleMute();
      expect(vm.volume, 0.0);
      expect(vm.isMuted, isTrue);

      await vm.toggleMute();
      expect(vm.volume, 0.70);
      expect(vm.isMuted, isFalse);

      vm.dispose();
    });

    test('Seeking and Mini Player Mode toggle', () async {
      final vm = await createTestViewModel();

      // Seek calls
      await vm.seek(const Duration(seconds: 45));
      await vm.seekRelative(const Duration(seconds: 10));

      // Mini Player toggle
      expect(vm.isMiniPlayer, isFalse);
      await vm.toggleMiniPlayerMode();
      expect(vm.isMiniPlayer, isTrue);
      await vm.toggleMiniPlayerMode();
      expect(vm.isMiniPlayer, isFalse);

      vm.dispose();
    });
  });

  group('2. 5-Band Graphic Equalizer', () {
    test('Toggle Equalizer, apply all presets, individual band adjustment, clamping, and reset', () async {
      final vm = await createTestViewModel();

      expect(vm.eqEnabled, isFalse);
      expect(vm.eqPreset, 'flat');
      expect(vm.eqBands, [0.0, 0.0, 0.0, 0.0, 0.0]);

      // Toggle Equalizer
      await vm.toggleEqualizer(true);
      expect(vm.eqEnabled, isTrue);
      await vm.toggleEqualizer(false);
      expect(vm.eqEnabled, isFalse);

      // Verify all presets can be applied
      final presetKeys = [
        'flat',
        'bass_boost',
        'rap',
        'rock',
        'pop',
        'electronic',
        'vocal',
        'acoustic',
        'classical',
        'night',
      ];

      for (final key in presetKeys) {
        await vm.setEqPreset(key);
        if (key != 'flat') {
          expect(vm.eqEnabled, isTrue);
        }
        expect(vm.eqPreset, key);
        final expectedBands = AudioPlayerService.eqPresets[key]!;
        expect(vm.eqBands, equals(expectedBands));
      }

      // Individual band adjustment across 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
      await vm.setEqBand(0, 5.5);
      expect(vm.eqPreset, 'custom');
      expect(vm.eqBands[0], 5.5);

      await vm.setEqBand(1, -3.0);
      expect(vm.eqBands[1], -3.0);

      await vm.setEqBand(2, 2.5);
      expect(vm.eqBands[2], 2.5);

      await vm.setEqBand(3, 4.0);
      expect(vm.eqBands[3], 4.0);

      await vm.setEqBand(4, -1.5);
      expect(vm.eqBands[4], -1.5);

      // Clamping between -12dB and +12dB
      await vm.setEqBand(0, 25.0);
      expect(vm.eqBands[0], 12.0);

      await vm.setEqBand(1, -30.0);
      expect(vm.eqBands[1], -12.0);

      // Reset Equalizer
      await vm.resetEqualizer();
      expect(vm.eqPreset, 'flat');
      expect(vm.eqBands, [0.0, 0.0, 0.0, 0.0, 0.0]);

      vm.dispose();
    });

    test('Verify FFmpeg filter string generation and anti-clipping preamp calculation', () {
      // Disabled -> null
      expect(AudioPlayerService.buildFfmpegEqFilterString(false, [5.0, 2.0, 0.0, 1.0, 2.0]), isNull);

      // All flat (0.0) -> null
      expect(AudioPlayerService.buildFfmpegEqFilterString(true, [0.0, 0.0, 0.0, 0.0, 0.0]), isNull);

      // Bass boost [7.0, 4.5, 0.0, 1.0, 1.5]
      // Max boost = 7.0 (> 2.0), preampDb = -(7.0 * 0.55) = -3.85 clamped -> -3.9 dB
      final filter = AudioPlayerService.buildFfmpegEqFilterString(
        true,
        [7.0, 4.5, 0.0, 1.0, 1.5],
      );

      expect(filter, isNotNull);
      expect(filter, contains('volume=-3.9dB'));
      expect(filter, contains('equalizer=f=60:width_type=o:width=1.8:g=7.0'));
      expect(filter, contains('equalizer=f=230:width_type=o:width=1.8:g=4.5'));
      expect(filter, contains('equalizer=f=3600:width_type=o:width=1.8:g=1.0'));
      expect(filter, contains('equalizer=f=14000:width_type=o:width=1.8:g=1.5'));
      // 910 Hz band is 0.0 dB -> should not be included in filter string
      expect(filter, isNot(contains('equalizer=f=910:')));
    });
  });

  group('3. Audio Effects, A-B Loop & Sleep Timer', () {
    test('Playback speed rates (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x)', () async {
      final vm = await createTestViewModel();

      final rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
      for (final r in rates) {
        await vm.setPlaybackRate(r);
        expect(vm.playbackRate, r);
      }

      vm.dispose();
    });

    test('Stereo balance (-1.0 left, 0.0 center, 1.0 right)', () async {
      final vm = await createTestViewModel();

      await vm.setBalance(-1.0);
      expect(vm.balance, -1.0);

      await vm.setBalance(1.0);
      expect(vm.balance, 1.0);

      await vm.setBalance(0.0);
      expect(vm.balance, 0.0);

      vm.dispose();
    });

    test('A-B Loop: setLoopPointA, setLoopPointB, invalid B handling, clearABLoop', () async {
      final vm = await createTestViewModel();

      expect(vm.isABLoopActive, isFalse);
      expect(vm.loopStartA, isNull);
      expect(vm.loopEndB, isNull);

      // Set Point A (10s)
      vm.setLoopPointA(const Duration(seconds: 10));
      expect(vm.loopStartA, const Duration(seconds: 10));
      expect(vm.isABLoopActive, isFalse);

      // Invalid Point B (<= A) is ignored
      vm.setLoopPointB(const Duration(seconds: 8));
      expect(vm.loopEndB, isNull);
      expect(vm.isABLoopActive, isFalse);

      // Valid Point B (20s)
      vm.setLoopPointB(const Duration(seconds: 20));
      expect(vm.loopEndB, const Duration(seconds: 20));
      expect(vm.isABLoopActive, isTrue);

      // Setting Point A beyond Point B resets Point B
      vm.setLoopPointA(const Duration(seconds: 25));
      expect(vm.loopStartA, const Duration(seconds: 25));
      expect(vm.loopEndB, isNull);
      expect(vm.isABLoopActive, isFalse);

      // Clear Loop
      vm.setLoopPointB(const Duration(seconds: 35));
      expect(vm.isABLoopActive, isTrue);
      vm.clearABLoop();
      expect(vm.loopStartA, isNull);
      expect(vm.loopEndB, isNull);
      expect(vm.isABLoopActive, isFalse);

      vm.dispose();
    });

    test('Sleep Timer: duration timer, stop after current track, and cancel', () async {
      final vm = await createTestViewModel();

      // Duration timer
      vm.setSleepTimer(const Duration(minutes: 15));
      expect(vm.isSleepTimerActive, isTrue);
      expect(vm.sleepTimerRemaining, const Duration(minutes: 15));
      expect(vm.stopAfterCurrentTrack, isFalse);

      // Stop after current track
      vm.setSleepTimer(null, stopAfterCurrent: true);
      expect(vm.isSleepTimerActive, isTrue);
      expect(vm.sleepTimerRemaining, isNull);
      expect(vm.stopAfterCurrentTrack, isTrue);

      // Cancel
      vm.cancelSleepTimer();
      expect(vm.isSleepTimerActive, isFalse);
      expect(vm.sleepTimerRemaining, isNull);
      expect(vm.stopAfterCurrentTrack, isFalse);

      vm.dispose();
    });
  });

  group('4. Play Queue Management', () {
    test('addToQueue, playNextInQueue, removeFromQueueAt, reorderQueue, clearUpcomingQueue', () async {
      final t1 = createSampleTrack('1', 'Şarkı 1', 'Sanatçı 1', 'Albüm 1', sampleLocalFile1.path);
      final t2 = createSampleTrack('2', 'Şarkı 2', 'Sanatçı 2', 'Albüm 2', sampleLocalFile2.path);
      final t3 = createSampleTrack('3', 'Şarkı 3', 'Sanatçı 3', 'Albüm 3', sampleLocalFile3.path);
      final t4 = createSampleTrack('4', 'Şarkı 4', 'Sanatçı 4', 'Albüm 4', sampleLocalFile4.path);

      final vm = await createTestViewModel(initialQueue: [t1], activeTrackId: t1.id);

      expect(vm.queue.map((t) => t.id).toList(), ['1']);
      expect(vm.currentIndex, 0);

      // addToQueue appends and prevents duplicate
      vm.addToQueue(t2);
      vm.addToQueue(t2);
      vm.addToQueue(t3);
      expect(vm.queue.map((t) => t.id).toList(), ['1', '2', '3']);

      // playNextInQueue adds immediately after current track (index 1)
      vm.playNextInQueue(t4);
      expect(vm.queue.map((t) => t.id).toList(), ['1', '4', '2', '3']);

      // playNextInQueue with existing track shifts it next
      vm.playNextInQueue(t3);
      expect(vm.queue.map((t) => t.id).toList(), ['1', '3', '4', '2']);

      // reorderQueue: move track at index 3 to index 0 (shifts currentIndex from 0 to 1)
      vm.reorderQueue(3, 0);
      expect(vm.queue.map((t) => t.id).toList(), ['2', '1', '3', '4']);
      expect(vm.currentIndex, 1);
      expect(vm.currentTrack?.id, '1');

      // removeFromQueueAt: current track cannot be removed
      vm.removeFromQueueAt(1);
      expect(vm.queue.map((t) => t.id).toList(), ['2', '1', '3', '4']);
      expect(vm.currentIndex, 1);

      // removeFromQueueAt: removing track before current track shifts currentIndex
      vm.removeFromQueueAt(0);
      expect(vm.queue.map((t) => t.id).toList(), ['1', '3', '4']);
      expect(vm.currentIndex, 0);

      // clearUpcomingQueue: keeps active track, removes upcoming
      vm.clearUpcomingQueue();
      expect(vm.queue.map((t) => t.id).toList(), ['1']);
      expect(vm.currentIndex, 0);

      vm.dispose();
    });
  });

  group('5. Library & Track Management', () {
    test('Library Sorting (LibrarySortMode.title, artist, addedNewest, duration)', () async {
      final t1 = Track(
        id: '1',
        title: 'Zerrin',
        artist: 'Berna',
        duration: const Duration(seconds: 120),
        sourcePath: sampleLocalFile1.path,
        addedAt: DateTime(2025, 1, 1),
      );
      final t2 = Track(
        id: '2',
        title: 'Ahmet',
        artist: 'Zeki',
        duration: const Duration(seconds: 300),
        sourcePath: sampleLocalFile2.path,
        addedAt: DateTime(2025, 1, 5),
      );
      final t3 = Track(
        id: '3',
        title: 'Mert',
        artist: 'Can',
        duration: const Duration(seconds: 200),
        sourcePath: sampleLocalFile3.path,
        addedAt: DateTime(2025, 1, 3),
      );

      final vm = await createTestViewModel(localTracks: [t1, t2, t3]);

      // Title sort
      final sortedByTitle = vm.sortTracks(vm.localTracks, LibrarySortMode.title);
      expect(sortedByTitle.map((t) => t.title).toList(), ['Ahmet', 'Mert', 'Zerrin']);

      // Artist sort
      final sortedByArtist = vm.sortTracks(vm.localTracks, LibrarySortMode.artist);
      expect(sortedByArtist.map((t) => t.artist).toList(), ['Berna', 'Can', 'Zeki']);

      // Added newest
      final sortedByNewest = vm.sortTracks(vm.localTracks, LibrarySortMode.addedNewest);
      expect(sortedByNewest.map((t) => t.id).toList(), ['2', '3', '1']);

      // Duration desc
      final sortedByDuration = vm.sortTracks(vm.localTracks, LibrarySortMode.duration);
      expect(sortedByDuration.map((t) => t.id).toList(), ['2', '3', '1']);

      vm.dispose();
    });

    test('Local Search / Filtering (setSearchQuery, filterTracks, clearing search query)', () async {
      final t1 = createSampleTrack('1', 'Kuşlar Uçuyor', 'Sezen Aksu', 'Gülümse', sampleLocalFile1.path);
      final t2 = createSampleTrack('2', 'Paramparça', 'Teoman', 'O', sampleLocalFile2.path);
      final t3 = createSampleTrack('3', 'Fırtına', 'Mor ve Ötesi', 'Gül Kendine', sampleLocalFile3.path);

      final vm = await createTestViewModel(localTracks: [t1, t2, t3]);

      // Search by title
      vm.setSearchQuery('uçuyor');
      expect(vm.searchQuery, 'uçuyor');
      var results = vm.filterTracks(vm.localTracks);
      expect(results.length, 1);
      expect(results.first.id, '1');

      // Search by artist
      vm.setSearchQuery('Teoman');
      results = vm.filterTracks(vm.localTracks);
      expect(results.length, 1);
      expect(results.first.id, '2');

      // Search by album
      vm.setSearchQuery('Gülümse');
      results = vm.filterTracks(vm.localTracks);
      expect(results.length, 1);
      expect(results.first.id, '1');

      // Clear search query
      vm.clearSearchQuery();
      expect(vm.searchQuery, isEmpty);
      results = vm.filterTracks(vm.localTracks);
      expect(results.length, 3);

      vm.dispose();
    });

    test('Track Metadata Editing and clearing metadata fields', () async {
      final t1 = createSampleTrack('1', 'Eski Şarkı', 'Eski Sanatçı', 'Eski Albüm', sampleLocalFile1.path);
      final vm = await createTestViewModel(
        localTracks: [t1],
        initialQueue: [t1],
        activeTrackId: t1.id,
        favorites: [t1],
      );

      await vm.updateTrackMetadata(
        t1,
        title: 'Yeni Şarkı',
        artist: 'Yeni Sanatçı',
        album: 'Yeni Albüm',
        lyrics: 'Nakarat sözleri burada',
      );

      expect(vm.localTracks.first.title, 'Yeni Şarkı');
      expect(vm.localTracks.first.artist, 'Yeni Sanatçı');
      expect(vm.localTracks.first.album, 'Yeni Albüm');
      expect(vm.localTracks.first.lyrics, 'Nakarat sözleri burada');
      expect(vm.favorites.first.title, 'Yeni Şarkı');
      expect(vm.currentTrack?.title, 'Yeni Şarkı');

      // Clear album and lyrics
      await vm.updateTrackMetadata(
        vm.localTracks.first,
        title: 'Yeni Şarkı',
        artist: 'Yeni Sanatçı',
        clearAlbum: true,
        clearLyrics: true,
      );

      expect(vm.localTracks.first.album, isNull);
      expect(vm.localTracks.first.lyrics, isNull);

      vm.dispose();
    });

    test('Mojibake Turkish Character Repair (Track.fixMojibake)', () {
      expect(Track.fixMojibake('FÄ±rtÄ±nam'), 'Fırtınam');
      expect(Track.fixMojibake('KaktÃ¼s'), 'Kaktüs');
      expect(Track.fixMojibake('ÅžarkÄ±'), 'Şarkı');
      expect(Track.fixMojibake('DÃ¼ÅŸler Ãœlkesi'), 'Düşler Ülkesi');
      expect(Track.fixMojibake('Ä°stanbul'), 'İstanbul');
      expect(Track.fixMojibake('GÃ¶kyÃ¼zÃ¼'), 'Gökyüzü');
      expect(Track.fixMojibake('Temiz Türkçe Başlık 123'), 'Temiz Türkçe Başlık 123');
      expect(Track.fixMojibake(''), '');
    });

    test('Reveal in Explorer for local files vs invalid/online files', () async {
      final vm = await createTestViewModel();

      // Real existing local file
      final localTrack = createSampleTrack('loc_1', 'Local', 'Art', 'Alb', sampleLocalFile1.path);
      final resultSuccess = await vm.revealInExplorer(localTrack);
      expect(resultSuccess, isTrue);

      // Non-existent file
      final missingTrack = createSampleTrack('loc_2', 'Missing', 'Art', 'Alb', 'C:/Music/does_not_exist_9999.mp3');
      final resultMissing = await vm.revealInExplorer(missingTrack);
      expect(resultMissing, isFalse);

      // Online track
      final onlineTrack = Track(
        id: 'on_1',
        title: 'Online',
        artist: 'Web',
        duration: Duration.zero,
        sourcePath: 'dQw4w9WgXcQ',
        isOnline: true,
      );
      final resultOnline = await vm.revealInExplorer(onlineTrack);
      expect(resultOnline, isFalse);

      vm.dispose();
    });
  });

  group('6. Playlists & M3U8 Export/Import', () {
    test('Create, Add/Remove tracks, Rename, Export M3U8, Import M3U8 and Delete Playlist', () async {
      final t1 = createSampleTrack('1', 'Şarkı 1', 'Sanatçı 1', 'Albüm 1', sampleLocalFile1.path);
      final t2 = createSampleTrack('2', 'Şarkı 2', 'Sanatçı 2', 'Albüm 2', sampleLocalFile2.path);

      final vm = await createTestViewModel(localTracks: [t1, t2]);

      // Create Playlist
      final pl = await vm.createPlaylist('Türkçe Rock', description: 'En iyi rock klasikleri');
      expect(vm.playlists.length, 1);
      expect(vm.playlists.first.name, 'Türkçe Rock');
      expect(vm.playlists.first.description, 'En iyi rock klasikleri');

      // Add track to playlist
      await vm.addTrackToPlaylist(pl.id, t1);
      await vm.addTrackToPlaylist(pl.id, t2);
      expect(vm.playlists.first.tracks.length, 2);

      // Rename playlist (with mojibake healing)
      await vm.renamePlaylist(pl.id, 'TÃ¼rkÃ§e Rock Favorileri', description: 'Güncellendi');
      expect(vm.playlists.first.name, 'Türkçe Rock Favorileri');
      expect(vm.playlists.first.description, 'Güncellendi');

      // Remove track from playlist
      await vm.removeTrackFromPlaylist(pl.id, t2);
      expect(vm.playlists.first.tracks.length, 1);
      expect(vm.playlists.first.tracks.first.id, '1');

      // Defensive test: adding or removing track with invalid playlistId should safely do nothing
      await vm.addTrackToPlaylist('non_existent_pl', t2);
      await vm.removeTrackFromPlaylist('non_existent_pl', t1);
      expect(vm.playlists.first.tracks.length, 1);

      // Verify M3U8 content builder
      final m3uContent = FilePickerService.buildM3UContent(vm.playlists.first);
      expect(m3uContent, contains('#EXTM3U'));
      expect(m3uContent, contains('#PLAYLIST:Türkçe Rock Favorileri'));
      expect(m3uContent, contains('#EXTINF:210,Sanatçı 1 - Şarkı 1'));
      expect(m3uContent, contains(sampleLocalFile1.path));

      // Verify M3U8 parser
      final parsedPlaylist = FilePickerService.parseM3UContent(
        content: m3uContent,
        defaultName: 'Varsayilan',
      );
      expect(parsedPlaylist.name, 'Türkçe Rock Favorileri');
      expect(parsedPlaylist.tracks.length, 1);
      expect(parsedPlaylist.tracks.first.title, 'Şarkı 1');
      expect(parsedPlaylist.tracks.first.artist, 'Sanatçı 1');
      expect(parsedPlaylist.tracks.first.sourcePath, sampleLocalFile1.path);

      // Delete Playlist
      await vm.deletePlaylist(pl.id);
      expect(vm.playlists.isEmpty, isTrue);

      vm.dispose();
    });
  });

  group('7. Favorites & History', () {
    test('Favorites toggle and Recent History tracking and clearing', () async {
      final t1 = createSampleTrack('1', 'Şarkı 1', 'Sanatçı 1', 'Albüm 1', sampleLocalFile1.path);
      final t2 = createSampleTrack('2', 'Şarkı 2', 'Sanatçı 2', 'Albüm 2', sampleLocalFile2.path);

      final vm = await createTestViewModel(localTracks: [t1, t2]);

      expect(vm.isFavorite(t1), isFalse);
      expect(vm.favorites.isEmpty, isTrue);

      // Add to favorites
      await vm.toggleFavorite(t1);
      expect(vm.isFavorite(t1), isTrue);
      expect(vm.favorites.length, 1);
      expect(vm.favorites.first.id, '1');

      // Remove from favorites
      await vm.toggleFavorite(t1);
      expect(vm.isFavorite(t1), isFalse);
      expect(vm.favorites.isEmpty, isTrue);

      // Play track adds to recent history
      await vm.playTrack(t1);
      await vm.playTrack(t2);
      expect(vm.recentTracks.length, 2);
      expect(vm.recentTracks.first.id, '2');

      // Clear recent history
      await vm.clearRecentHistory();
      expect(vm.recentTracks.isEmpty, isTrue);

      vm.dispose();
    });
  });

  group('8. Settings & Maintenance', () {
    test('Settings toggles, download preferences, audio cache, maintenance, and reset', () async {
      final vm = await createTestViewModel();

      // Audio visualizer toggle
      expect(vm.showVisualizer, isTrue);
      await vm.setShowVisualizer(false);
      expect(vm.showVisualizer, isFalse);

      // Auto fetch lyrics toggle
      expect(vm.autoFetchLyrics, isTrue);
      await vm.setAutoFetchLyrics(false);
      expect(vm.autoFetchLyrics, isFalse);

      // Download preferences
      await vm.setDownloadFormat(AudioDownloadFormat.m4a);
      expect(vm.downloadFormat, AudioDownloadFormat.m4a);
      await vm.setDownloadFormat(AudioDownloadFormat.opus);
      expect(vm.downloadFormat, AudioDownloadFormat.opus);
      await vm.setDownloadThreads(16);
      expect(vm.downloadThreads, 16);
      await vm.setConcurrentDownloads(5);
      expect(vm.concurrentDownloads, 5);

      // Cache size and clear cache
      await vm.refreshAudioCacheSize();
      final clearedCount = await vm.clearAudioCache();
      expect(clearedCount, isNonNegative);

      // Library maintenance self-healing
      final tMoji = Track(
        id: 'm1',
        title: 'KaktÃ¼s',
        artist: 'Åžebnem',
        duration: Duration.zero,
        sourcePath: sampleLocalFile1.path,
      );
      final plMoji = Playlist(
        id: 'pm1',
        name: 'TÃ¼rkÃ§e Rock',
        tracks: [tMoji],
      );
      final vm2 = await createTestViewModel(
        localTracks: [tMoji],
        playlists: [plMoji],
      );
      final fixed = await vm2.runLibraryMaintenance();
      expect(fixed, isNonNegative);
      expect(vm2.localTracks.first.title, 'Kaktüs');
      expect(vm2.localTracks.first.artist, 'Şebnem');
      expect(vm2.playlists.first.name, 'Türkçe Rock');
      vm2.dispose();

      // Reset all settings to default
      await vm.resetAllSettingsToDefault();
      expect(vm.eqEnabled, isFalse);
      expect(vm.eqPreset, 'flat');
      expect(vm.playbackRate, 1.0);
      expect(vm.balance, 0.0);
      expect(vm.volume, 0.8);
      expect(vm.downloadFormat, AudioDownloadFormat.opus);
      expect(vm.downloadThreads, 8);
      expect(vm.concurrentDownloads, 3);
      expect(vm.showVisualizer, isTrue);
      expect(vm.autoFetchLyrics, isTrue);

      // Engine checks
      await vm.checkExternalEngines();

      vm.dispose();
    });
  });

  group('9. YouTube Downloader Core', () {
    test('URL Normalization for playlists, videos, music.youtube.com and raw IDs', () {
      final service = OnlineMusicService();

      // Playlist in watch URL
      expect(
        service.normalizeYouTubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL1234567890abcdef'),
        'https://www.youtube.com/playlist?list=PL1234567890abcdef',
      );

      // Single video
      expect(
        service.normalizeYouTubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      // Music.youtube.com URL
      expect(
        service.normalizeYouTubeUrl('https://music.youtube.com/watch?v=dQw4w9WgXcQ'),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      // Raw playlist ID
      expect(
        service.normalizeYouTubeUrl('PLrawPlaylistId999'),
        'https://www.youtube.com/playlist?list=PLrawPlaylistId999',
      );

      // Album ID
      expect(
        service.normalizeYouTubeUrl('OLAK5uy_testAlbumListId'),
        'https://www.youtube.com/playlist?list=OLAK5uy_testAlbumListId',
      );

      // Empty input
      expect(service.normalizeYouTubeUrl('   '), '');

      service.dispose();
    });
  });

  group('10. Navigation & UI Layout', () {
    testWidgets('Full 6-Tab navigation at 1280x800 with zero RenderFlex overflows', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlayerViewModel()),
          ],
          child: const AntigravityMusicApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // 6 Navigation tabs
      final navTabs = [
        'Kütüphanem',
        'YouTube İndirici',
        'Favoriler',
        'Çalma Listeleri',
        'Son Çalınanlar',
        'Ayarlar',
      ];

      for (final tab in navTabs) {
        expect(find.text(tab), findsWidgets);
      }

      // Tap through each of the 6 tabs and verify zero RenderFlex overflow
      for (final tab in navTabs) {
        await tester.tap(find.text(tab).first);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'Tab "$tab" threw an exception or overflowed');
      }

      // Verify Ayarlar section components
      await tester.tap(find.text('Ayarlar').first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Ayarlar & Stüdyo Ekolayzer'), findsOneWidget);
      expect(find.text('Bass Boost'), findsOneWidget);
    });
  });
}

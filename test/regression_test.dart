import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_music/models/track.dart';
import 'package:antigravity_music/models/playlist.dart';
import 'package:antigravity_music/models/download_item.dart';
import 'package:antigravity_music/services/online_music_service.dart';
import 'package:antigravity_music/viewmodels/player_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall call) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall call) async => 1,
    );
  });

  group('1. Eski Özellikler (Regresyon Koruması)', () {
    test('Track.fixMojibake Türkçe bozuk karakterleri doğru düzeltmeli', () {
      expect(Track.fixMojibake('FÄ±rtÄ±nam'), 'Fırtınam');
      expect(Track.fixMojibake('KaktÃ¼s'), 'Kaktüs');
      expect(Track.fixMojibake('ÅžarkÄ±'), 'Şarkı');
      expect(Track.fixMojibake('DÃ¼ÅŸler Ãœlkesi'), 'Düşler Ülkesi');
      expect(Track.fixMojibake('Normal Metin 123'), 'Normal Metin 123');
      expect(Track.fixMojibake(''), '');
    });

    test('Track ve Playlist JSON serileştirme ve geriye dönük uyumluluk', () {
      // playCount ve lyrics alanı olmayan eski sürüm JSON kaydı
      final legacyTrackJson = <String, dynamic>{
        'id': 'legacy_1',
        'title': 'FÄ±rtÄ±nam',
        'artist': 'Åžebnem Ferah',
        'album': 'Kelimeler Yetse',
        'durationMs': 245000,
        'sourcePath': 'C:/Music/firtinam.mp3',
        'isOnline': false,
        'isFavorite': true,
        'addedAt': '2025-01-01T12:00:00.000Z',
      };

      final trackFromLegacy = Track.fromJson(legacyTrackJson);
      expect(trackFromLegacy.id, 'legacy_1');
      expect(trackFromLegacy.title, 'Fırtınam');
      expect(trackFromLegacy.artist, 'Şebnem Ferah');
      expect(trackFromLegacy.playCount, 0);
      expect(trackFromLegacy.lyrics, isNull);
      expect(trackFromLegacy.duration, const Duration(milliseconds: 245000));
      expect(trackFromLegacy.isFavorite, isTrue);

      // Yeni alanlarla tam serileştirme döngüsü (toJson -> fromJson)
      final updatedTrack = trackFromLegacy.copyWith(
        playCount: 12,
        lyrics: 'Nakarat sözleri...',
      );
      final roundTripTrack = Track.fromJson(updatedTrack.toJson());
      expect(roundTripTrack.playCount, 12);
      expect(roundTripTrack.lyrics, 'Nakarat sözleri...');
      expect(roundTripTrack.title, 'Fırtınam');

      // Playlist toJson / fromJson döngüsü ve mojibake onarımı
      final playlist = Playlist(
        id: 'pl_100',
        name: 'TÃ¼rkÃ§e KayÄ±tlar',
        description: 'En sevilen ÅŸarkÄ±lar',
        tracks: [roundTripTrack],
      );
      final playlistFromJson = Playlist.fromJson(playlist.toJson());
      expect(playlistFromJson.id, 'pl_100');
      expect(playlistFromJson.name, 'Türkçe Kayıtlar');
      expect(playlistFromJson.description, 'En sevilen şarkılar');
      expect(playlistFromJson.tracks.length, 1);
      expect(playlistFromJson.tracks.first.playCount, 12);
      expect(playlistFromJson.tracks.first.lyrics, 'Nakarat sözleri...');
    });

    test('OnlineMusicService.normalizeYouTubeUrl farklı URL formatlarını normalize etmeli', () {
      final service = OnlineMusicService();

      expect(
        service.normalizeYouTubeUrl(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL1234567890abcdef',
        ),
        'https://www.youtube.com/playlist?list=PL1234567890abcdef',
      );

      expect(
        service.normalizeYouTubeUrl(
          'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      expect(
        service.normalizeYouTubeUrl(
          'https://music.youtube.com/playlist?list=PLabcdef12345',
        ),
        'https://www.youtube.com/playlist?list=PLabcdef12345',
      );

      expect(
        service.normalizeYouTubeUrl('PLrawPlaylistId999'),
        'https://www.youtube.com/playlist?list=PLrawPlaylistId999',
      );

      expect(
        service.normalizeYouTubeUrl('OLAK5uy_testAlbumListId'),
        'https://www.youtube.com/playlist?list=OLAK5uy_testAlbumListId',
      );

      expect(service.normalizeYouTubeUrl('   '), '');
      service.dispose();
    });

    test('DownloadItemProgress durum geçişleri ve ham log saklama', () {
      final item = DownloadItemProgress(
        id: 'vid_01',
        title: 'KaktÃ¼s - ÅžarkÄ±',
        index: 1,
      );

      expect(item.title, 'Kaktüs - Şarkı');
      expect(item.status, DownloadItemStatus.queued);
      expect(item.errorMessage, isNull);
      expect(item.rawLog, isNull);

      item.status = DownloadItemStatus.downloading;
      expect(item.status, DownloadItemStatus.downloading);

      item.status = DownloadItemStatus.failed;
      item.errorMessage = 'ERROR: Video unavailable';
      item.rawLog = 'stderr: ERROR: Video unavailable\nstdout: [youtube] vid_01';
      expect(item.status, DownloadItemStatus.failed);
      expect(item.errorMessage, contains('Video unavailable'));
      expect(item.rawLog, contains('stderr: ERROR:'));

      item.status = DownloadItemStatus.completed;
      item.errorMessage = null;
      item.rawLog = null;
      expect(item.status, DownloadItemStatus.completed);
      expect(item.errorMessage, isNull);
      expect(item.rawLog, isNull);
    });
  });

  group('2. Yeni Özellikler (PlayerViewModel)', () {
    late Track track1;
    late Track track2;
    late Track track3;
    late Track track4;

    setUp(() {
      track1 = Track(
        id: 't1',
        title: 'Şarkı 1',
        artist: 'Sanatçı A',
        album: 'Albüm 1',
        duration: const Duration(minutes: 3),
        sourcePath: 'C:/Music/sarki1.mp3',
      );
      track2 = Track(
        id: 't2',
        title: 'Şarkı 2',
        artist: 'Sanatçı B',
        album: 'Albüm 2',
        duration: const Duration(minutes: 4),
        sourcePath: 'C:/Music/sarki2.mp3',
      );
      track3 = Track(
        id: 't3',
        title: 'Şarkı 3',
        artist: 'Sanatçı C',
        album: 'Albüm 3',
        duration: const Duration(minutes: 5),
        sourcePath: 'C:/Music/sarki3.mp3',
      );
      track4 = Track(
        id: 't4',
        title: 'Şarkı 4',
        artist: 'Sanatçı D',
        album: 'Albüm 4',
        duration: const Duration(minutes: 2),
        sourcePath: 'C:/Music/sarki4.mp3',
      );
    });

    Future<PlayerViewModel> createInitializedViewModel({
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

    test('Kuyruk yönetimi: addToQueue, playNextInQueue, reorderQueue, removeFromQueueAt, clearUpcomingQueue', () async {
      final vm = await createInitializedViewModel(
        initialQueue: [track1],
        activeTrackId: track1.id,
      );

      expect(vm.queue.map((t) => t.id).toList(), ['t1']);
      expect(vm.currentTrack?.id, 't1');
      expect(vm.currentIndex, 0);

      // addToQueue: sona ekler ve mükerrer eklemeyi engeller
      vm.addToQueue(track2);
      vm.addToQueue(track2);
      vm.addToQueue(track3);
      expect(vm.queue.map((t) => t.id).toList(), ['t1', 't2', 't3']);

      // playNextInQueue: aktif şarkının hemen sonrasına (index 1) ekler
      vm.playNextInQueue(track4);
      expect(vm.queue.map((t) => t.id).toList(), ['t1', 't4', 't2', 't3']);

      // Zaten kuyrukta olan şarkı için playNextInQueue çağrıldığında sırasını aktif şarkının sonrasına taşır
      vm.playNextInQueue(track3);
      expect(vm.queue.map((t) => t.id).toList(), ['t1', 't3', 't4', 't2']);

      // reorderQueue: son sıradaki şarkıyı en başa taşıma (currentIndex güncellenmeli)
      vm.reorderQueue(3, 0);
      expect(vm.queue.map((t) => t.id).toList(), ['t2', 't1', 't3', 't4']);
      expect(vm.currentIndex, 1);

      // removeFromQueueAt: o an çalan şarkı (currentIndex == 1) silinememeli
      vm.removeFromQueueAt(1);
      expect(vm.queue.map((t) => t.id).toList(), ['t2', 't1', 't3', 't4']);

      // Aktif şarkıdan önceki bir eleman silindiğinde currentIndex kaymalı
      vm.removeFromQueueAt(0);
      expect(vm.queue.map((t) => t.id).toList(), ['t1', 't3', 't4']);
      expect(vm.currentIndex, 0);

      // clearUpcomingQueue: yalnızca aktif şarkıyı korur
      vm.clearUpcomingQueue();
      expect(vm.queue.map((t) => t.id).toList(), ['t1']);
      expect(vm.currentIndex, 0);

      vm.dispose();
    });

    test('Shuffle (Karıştır): toggleShuffle aktif şarkıyı koruyup sırayı karıştırmalı ve kapatıldığında orijinal sırayı geri yüklemeli', () async {
      final vm = await createInitializedViewModel(
        initialQueue: [track1, track2, track3, track4],
        activeTrackId: track2.id,
      );

      expect(vm.isShuffle, isFalse);
      expect(vm.currentIndex, 1);
      expect(vm.currentTrack?.id, 't2');

      // Shuffle açıldığında aktif şarkı (t2) index 0'a geçmeli ve tüm parçalar kuyrukta kalmalı
      await vm.toggleShuffle();
      expect(vm.isShuffle, isTrue);
      expect(vm.currentIndex, 0);
      expect(vm.queue.first.id, 't2');
      expect(vm.queue.map((t) => t.id).toSet(), {'t1', 't2', 't3', 't4'});

      // Shuffle kapatıldığında orijinal sıra [t1, t2, t3, t4] ve currentIndex == 1 geri yüklenmeli
      await vm.toggleShuffle();
      expect(vm.isShuffle, isFalse);
      expect(vm.queue.map((t) => t.id).toList(), ['t1', 't2', 't3', 't4']);
      expect(vm.currentIndex, 1);

      vm.dispose();
    });

    test('createPlaylistWithTracks ve addTracksToPlaylist yerel şarkıları localTracks koleksiyonuna da eklemeli', () async {
      final vm = await createInitializedViewModel(localTracks: [track1]);
      expect(vm.localTracks.map((t) => t.id).toList(), ['t1']);

      final pl = await vm.createPlaylistWithTracks('Yeni Liste', [track1, track2]);
      expect(pl.tracks.length, 2);
      expect(vm.localTracks.map((t) => t.id).toList(), ['t1', 't2']);

      final addedCount = await vm.addTracksToPlaylist(pl.id, [track3, track4]);
      expect(addedCount, 2);
      expect(vm.localTracks.map((t) => t.id).toList(), ['t1', 't2', 't3', 't4']);

      vm.dispose();
    });

    test('A-B Loop: setLoopPointA, setLoopPointB ve clearABLoop kontrolleri', () async {
      final vm = await createInitializedViewModel();

      expect(vm.isABLoopActive, isFalse);
      expect(vm.loopStartA, isNull);
      expect(vm.loopEndB, isNull);

      vm.setLoopPointA(const Duration(seconds: 10));
      expect(vm.loopStartA, const Duration(seconds: 10));
      expect(vm.isABLoopActive, isFalse);

      // B noktası A'dan küçük veya eşitse kabul edilmemeli
      vm.setLoopPointB(const Duration(seconds: 5));
      expect(vm.loopEndB, isNull);
      expect(vm.isABLoopActive, isFalse);

      // Geçerli B noktası (> A)
      vm.setLoopPointB(const Duration(seconds: 25));
      expect(vm.loopEndB, const Duration(seconds: 25));
      expect(vm.isABLoopActive, isTrue);

      // A noktası mevcut B noktasından ileri alınırsa B sıfırlanmalı
      vm.setLoopPointA(const Duration(seconds: 30));
      expect(vm.loopStartA, const Duration(seconds: 30));
      expect(vm.loopEndB, isNull);
      expect(vm.isABLoopActive, isFalse);

      // Tekrar geçerli B ataması ve temizleme
      vm.setLoopPointB(const Duration(seconds: 45));
      expect(vm.isABLoopActive, isTrue);

      vm.clearABLoop();
      expect(vm.loopStartA, isNull);
      expect(vm.loopEndB, isNull);
      expect(vm.isABLoopActive, isFalse);

      vm.dispose();
    });

    test('Uyku Zamanlayıcısı: setSleepTimer ve cancelSleepTimer kontrolleri', () async {
      final vm = await createInitializedViewModel();

      expect(vm.isSleepTimerActive, isFalse);
      expect(vm.sleepTimerRemaining, isNull);
      expect(vm.stopAfterCurrentTrack, isFalse);

      // Süreli uyku zamanlayıcısı
      vm.setSleepTimer(const Duration(minutes: 15));
      expect(vm.isSleepTimerActive, isTrue);
      expect(vm.sleepTimerRemaining, const Duration(minutes: 15));
      expect(vm.stopAfterCurrentTrack, isFalse);

      // Şarkı bitince durdur modu
      vm.setSleepTimer(null, afterCurrentTrack: true);
      expect(vm.isSleepTimerActive, isTrue);
      expect(vm.sleepTimerRemaining, isNull);
      expect(vm.stopAfterCurrentTrack, isTrue);

      // İptal etme
      vm.cancelSleepTimer();
      expect(vm.isSleepTimerActive, isFalse);
      expect(vm.sleepTimerRemaining, isNull);
      expect(vm.stopAfterCurrentTrack, isFalse);

      vm.dispose();
    });

    test('updateTrackMetadata ve renamePlaylist tüm koleksiyonları güncellemeli ve boş alanları temizleyebilmeli', () async {
      final initialPlaylist = Playlist(
        id: 'pl_1',
        name: 'Eski Liste',
        tracks: [track1],
      );

      final vm = await createInitializedViewModel(
        initialQueue: [track1],
        activeTrackId: track1.id,
        localTracks: [track1],
        favorites: [track1],
        playlists: [initialPlaylist],
        recentTracks: [track1],
      );

      await vm.updateTrackMetadata(
        track1,
        title: 'FÄ±rtÄ±nam (Akustik)',
        artist: 'Åžebnem Ferah',
        album: 'KaktÃ¼s',
        lyrics: 'Test şarkı sözü satırı',
      );

      expect(vm.currentTrack?.title, 'Fırtınam (Akustik)');
      expect(vm.currentTrack?.artist, 'Şebnem Ferah');
      expect(vm.currentTrack?.album, 'Kaktüs');
      expect(vm.currentTrack?.lyrics, 'Test şarkı sözü satırı');

      expect(vm.localTracks.first.title, 'Fırtınam (Akustik)');
      expect(vm.favorites.first.artist, 'Şebnem Ferah');
      expect(vm.playlists.first.tracks.first.album, 'Kaktüs');
      expect(vm.queue.first.lyrics, 'Test şarkı sözü satırı');
      expect(vm.recentTracks.first.title, 'Fırtınam (Akustik)');

      // Albüm ve şarkı sözlerini temizleme (clearAlbum / clearLyrics)
      await vm.updateTrackMetadata(
        vm.currentTrack!,
        title: 'Fırtınam (Akustik)',
        artist: 'Şebnem Ferah',
        clearAlbum: true,
        clearLyrics: true,
      );
      expect(vm.currentTrack?.album, isNull);
      expect(vm.currentTrack?.lyrics, isNull);
      expect(vm.localTracks.first.album, isNull);
      expect(vm.localTracks.first.lyrics, isNull);

      // Çalma listesi yeniden adlandırma (mojibake düzeltmeli)
      await vm.renamePlaylist(
        'pl_1',
        '  Favori ÅžarkÄ±larÄ±m  ',
        description: 'Güncel açıklama',
      );

      expect(vm.playlists.first.name, 'Favori Şarkılarım');
      expect(vm.playlists.first.description, 'Güncel açıklama');

      vm.dispose();
    });

    test('5-Bant Grafik Ekolayzer: toggleEqualizer, setEqPreset, setEqBand ve resetEqualizer kontrolleri', () async {
      final vm = await createInitializedViewModel();

      expect(vm.eqEnabled, isFalse);
      expect(vm.eqPreset, 'flat');
      expect(vm.eqBands, [0.0, 0.0, 0.0, 0.0, 0.0]);

      // toggleEqualizer
      await vm.toggleEqualizer();
      expect(vm.eqEnabled, isTrue);
      await vm.toggleEqualizer(false);
      expect(vm.eqEnabled, isFalse);

      // setEqPreset('bass_boost') otomatik olarak eqEnabled'ı true yapmalı ve bantları yüklemeli
      await vm.setEqPreset('bass_boost');
      expect(vm.eqEnabled, isTrue);
      expect(vm.eqPreset, 'bass_boost');
      expect(vm.eqBands, [7.0, 4.5, 0.0, 1.0, 1.5]);

      // setEqBand(0, 8.5) preset'i 'custom' yapmalı ve bandı güncellemelidi
      await vm.setEqBand(0, 8.5);
      expect(vm.eqPreset, 'custom');
      expect(vm.eqBands[0], 8.5);
      expect(vm.eqBands.sublist(1), [4.5, 0.0, 1.0, 1.5]);

      // Sınır değer (clamp -12..+12 dB) kontrolü
      await vm.setEqBand(2, 20.0);
      expect(vm.eqBands[2], 12.0);
      await vm.setEqBand(3, -18.0);
      expect(vm.eqBands[3], -12.0);

      // resetEqualizer tüm 5 bandı 0.0'a ve preset'i 'flat'e döndürmeli
      await vm.resetEqualizer();
      expect(vm.eqPreset, 'flat');
      expect(vm.eqBands, [0.0, 0.0, 0.0, 0.0, 0.0]);

      vm.dispose();
    });

    test('Ayarlar durumu: setShowVisualizer, setAutoFetchLyrics ve resetAllSettingsToDefault kontrolleri', () async {
      final vm = await createInitializedViewModel();

      expect(vm.showVisualizer, isTrue);
      expect(vm.autoFetchLyrics, isTrue);

      await vm.setShowVisualizer(false);
      expect(vm.showVisualizer, isFalse);

      await vm.setAutoFetchLyrics(false);
      expect(vm.autoFetchLyrics, isFalse);

      // Ekolayzer, hız, denge ve indirme ayarlarını değiştirip resetAllSettingsToDefault ile sıfırlama
      await vm.setEqPreset('rock');
      await vm.setPlaybackRate(1.5);
      await vm.setBalance(-0.5);
      await vm.setVolume(0.4);
      await vm.setDownloadThreads(16);
      await vm.setConcurrentDownloads(6);
      vm.setLoopPointA(const Duration(seconds: 5));
      vm.setLoopPointB(const Duration(seconds: 15));

      expect(vm.eqEnabled, isTrue);
      expect(vm.eqPreset, 'rock');
      expect(vm.isABLoopActive, isTrue);

      await vm.resetAllSettingsToDefault();

      expect(vm.eqEnabled, isFalse);
      expect(vm.eqPreset, 'flat');
      expect(vm.eqBands, [0.0, 0.0, 0.0, 0.0, 0.0]);
      expect(vm.playbackRate, 1.0);
      expect(vm.balance, 0.0);
      expect(vm.volume, 0.8);
      expect(vm.isABLoopActive, isFalse);
      expect(vm.downloadFormat, AudioDownloadFormat.opus);
      expect(vm.downloadThreads, 8);
      expect(vm.concurrentDownloads, 3);
      expect(vm.showVisualizer, isTrue);
      expect(vm.autoFetchLyrics, isTrue);

      vm.dispose();
    });
  });
}

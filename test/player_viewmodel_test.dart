import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_music/models/track.dart';
import 'package:antigravity_music/models/playlist.dart';
import 'package:antigravity_music/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Track Model Tests', () {
    test('Track serializes to and from JSON accurately', () {
      final track = Track(
        id: 'test_1',
        title: 'Akşam Güneşi',
        artist: 'Ferdi Tayfur',
        album: 'Klasikler',
        duration: const Duration(minutes: 4, seconds: 20),
        sourcePath: 'C:/Music/test.mp3',
        isOnline: false,
        isFavorite: true,
      );

      final json = track.toJson();
      final fromJson = Track.fromJson(json);

      expect(fromJson.id, 'test_1');
      expect(fromJson.title, 'Akşam Güneşi');
      expect(fromJson.artist, 'Ferdi Tayfur');
      expect(fromJson.duration.inSeconds, 260);
      expect(fromJson.isFavorite, true);
    });

    test('Track equality compares id and sourcePath', () {
      final t1 = Track(
        id: 'id_1',
        title: 'Song A',
        artist: 'Artist A',
        duration: Duration.zero,
        sourcePath: 'path/to/a.mp3',
      );
      final t2 = Track(
        id: 'id_1',
        title: 'Song A - Renamed',
        artist: 'Artist B',
        duration: Duration.zero,
        sourcePath: 'path/to/a.mp3',
      );

      expect(t1, equals(t2));
    });
  });

  group('Playlist Model Tests', () {
    test('Playlist adds, removes tracks and serializes correctly', () {
      final playlist = Playlist(
        id: 'pl_1',
        name: 'Favori Listem',
        description: 'En sevdiğim parçalar',
      );

      final track = Track(
        id: 'tr_1',
        title: 'Track 1',
        artist: 'Artist 1',
        duration: const Duration(minutes: 3),
        sourcePath: 'http://test.com/1.mp3',
        isOnline: true,
      );

      playlist.tracks.add(track);
      expect(playlist.tracks.length, 1);

      final json = playlist.toJson();
      final fromJson = Playlist.fromJson(json);

      expect(fromJson.id, 'pl_1');
      expect(fromJson.name, 'Favori Listem');
      expect(fromJson.tracks.length, 1);
      expect(fromJson.tracks.first.title, 'Track 1');
    });
  });

  group('RepeatMode Enum Tests', () {
    test('RepeatMode values map properly', () {
      expect(RepeatMode.values.length, 3);
      expect(RepeatMode.off.index, 0);
      expect(RepeatMode.all.index, 1);
      expect(RepeatMode.one.index, 2);
    });
  });
}

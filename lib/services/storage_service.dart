import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';

class StorageService {
  static const String _keyLocalTracks = 'app_local_tracks';
  static const String _keyFavorites = 'app_favorites';
  static const String _keyPlaylists = 'app_playlists';
  static const String _keyRecentTracks = 'app_recent_tracks';
  static const String _keyVolume = 'app_volume';
  static const String _keyShuffle = 'app_shuffle';
  static const String _keyRepeatMode = 'app_repeat_mode';
  static const String _keyPlaybackRate = 'app_playback_rate';
  static const String _keyBalance = 'app_balance';
  static const String _keyLastQueue = 'app_last_queue';
  static const String _keyLastTrackId = 'app_last_track_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Local Tracks ---
  Future<void> saveLocalTracks(List<Track> tracks) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = tracks.map((t) => t.toJson()).toList();
    await prefs.setString(_keyLocalTracks, jsonEncode(jsonList));
  }

  Future<List<Track>> loadLocalTracks() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyLocalTracks);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Track.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Favorites ---
  Future<void> saveFavorites(List<Track> favorites) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = favorites.map((t) => t.toJson()).toList();
    await prefs.setString(_keyFavorites, jsonEncode(jsonList));
  }

  Future<List<Track>> loadFavorites() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFavorites);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Track.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Playlists ---
  Future<void> savePlaylists(List<Playlist> playlists) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = playlists.map((p) => p.toJson()).toList();
    await prefs.setString(_keyPlaylists, jsonEncode(jsonList));
  }

  Future<List<Playlist>> loadPlaylists() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPlaylists);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Playlist.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Recent Tracks ---
  Future<void> saveRecentTracks(List<Track> recents) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = recents.take(50).map((t) => t.toJson()).toList();
    await prefs.setString(_keyRecentTracks, jsonEncode(jsonList));
  }

  Future<List<Track>> loadRecentTracks() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyRecentTracks);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Track.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Preferences ---
  Future<void> saveVolume(double volume) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, volume);
  }

  Future<double> loadVolume() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getDouble(_keyVolume) ?? 0.8;
  }

  Future<void> saveShuffle(bool shuffle) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyShuffle, shuffle);
  }

  Future<bool> loadShuffle() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_keyShuffle) ?? false;
  }

  Future<void> saveRepeatMode(int modeIndex) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt(_keyRepeatMode, modeIndex);
  }

  Future<int> loadRepeatMode() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_keyRepeatMode) ?? 0;
  }

  Future<void> savePlaybackRate(double rate) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPlaybackRate, rate);
  }

  Future<double> loadPlaybackRate() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPlaybackRate) ?? 1.0;
  }

  Future<void> saveBalance(double balance) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBalance, balance);
  }

  Future<double> loadBalance() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBalance) ?? 0.0;
  }

  Future<void> saveLastSession({required List<Track> queue, String? currentTrackId}) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = queue.take(200).map((t) => t.toJson()).toList();
    await prefs.setString(_keyLastQueue, jsonEncode(jsonList));
    if (currentTrackId != null) {
      await prefs.setString(_keyLastTrackId, currentTrackId);
    } else {
      await prefs.remove(_keyLastTrackId);
    }
  }

  Future<List<Track>> loadLastQueue() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyLastQueue);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Track.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> loadLastTrackId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyLastTrackId);
  }

  // --- Downloader Preferences ---
  static const String _keyDownloadFormat = 'app_download_format';
  static const String _keyDownloadThreads = 'app_download_threads';
  static const String _keyConcurrentDownloads = 'app_concurrent_downloads';
  static const String _keyCustomDownloadDir = 'app_custom_download_dir';

  // --- Equalizer & App Settings ---
  static const String _keyEqEnabled = 'app_eq_enabled';
  static const String _keyEqPreset = 'app_eq_preset';
  static const String _keyEqBands = 'app_eq_bands';
  static const String _keyShowVisualizer = 'app_show_visualizer';
  static const String _keyAutoFetchLyrics = 'app_auto_fetch_lyrics';

  Future<void> saveDownloadFormat(String formatId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyDownloadFormat, formatId);
  }

  Future<String?> loadDownloadFormat() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyDownloadFormat);
  }

  Future<void> saveDownloadThreads(int threads) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt(_keyDownloadThreads, threads);
  }

  Future<int> loadDownloadThreads() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_keyDownloadThreads) ?? 8;
  }

  Future<void> saveConcurrentDownloads(int count) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt(_keyConcurrentDownloads, count.clamp(1, 10));
  }

  Future<int> loadConcurrentDownloads() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_keyConcurrentDownloads) ?? 3;
  }

  Future<void> saveCustomDownloadDir(String dirPath) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomDownloadDir, dirPath);
  }

  Future<String> loadCustomDownloadDir() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomDownloadDir) ?? '';
  }

  Future<void> saveEqEnabled(bool enabled) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyEqEnabled, enabled);
  }

  Future<bool> loadEqEnabled() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_keyEqEnabled) ?? false;
  }

  Future<void> saveEqPreset(String presetKey) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyEqPreset, presetKey);
  }

  Future<String> loadEqPreset() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyEqPreset) ?? 'flat';
  }

  Future<void> saveEqBands(List<double> bands) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyEqBands, jsonEncode(bands));
  }

  Future<List<double>> loadEqBands() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyEqBands);
    if (raw == null || raw.isEmpty) return [0.0, 0.0, 0.0, 0.0, 0.0];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      if (decoded.length >= 5) {
        return decoded.take(5).map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {}
    return [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  Future<void> saveShowVisualizer(bool show) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowVisualizer, show);
  }

  Future<bool> loadShowVisualizer() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowVisualizer) ?? true;
  }

  Future<void> saveAutoFetchLyrics(bool autoFetch) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoFetchLyrics, autoFetch);
  }

  Future<bool> loadAutoFetchLyrics() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoFetchLyrics) ?? true;
  }
}

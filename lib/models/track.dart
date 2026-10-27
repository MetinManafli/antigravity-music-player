import 'dart:convert';

class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final String sourcePath;
  final bool isOnline;
  final String? thumbnailUrl;
  bool isFavorite;
  final DateTime addedAt;
  final int playCount;
  final String? lyrics;

  Track({
    required this.id,
    required String title,
    required String artist,
    String? album,
    required this.duration,
    required this.sourcePath,
    this.isOnline = false,
    this.thumbnailUrl,
    this.isFavorite = false,
    DateTime? addedAt,
    this.playCount = 0,
    this.lyrics,
  })  : title = fixMojibake(title),
        artist = fixMojibake(artist),
        album = album != null ? fixMojibake(album) : null,
        addedAt = addedAt ?? DateTime.now();

  static const Map<int, int> _cp1252ToByte = {
    0x20AC: 0x80,
    0x201A: 0x82,
    0x0192: 0x83,
    0x201E: 0x84,
    0x2026: 0x85,
    0x2020: 0x86,
    0x2021: 0x87,
    0x02C6: 0x88,
    0x2030: 0x89,
    0x0160: 0x8A,
    0x2039: 0x8B,
    0x0152: 0x8C,
    0x017D: 0x8E,
    0x2018: 0x91,
    0x2019: 0x92,
    0x201C: 0x93,
    0x201D: 0x94,
    0x2022: 0x95,
    0x2013: 0x96,
    0x2014: 0x97,
    0x02DC: 0x98,
    0x2122: 0x99,
    0x0161: 0x9A,
    0x203A: 0x9B,
    0x0153: 0x9C,
    0x017E: 0x9E,
    0x0178: 0x9F,
  };

  /// Fixes UTF-8 mojibake (e.g. FÄ±rtÄ±nam -> Fırtınam, KaktÃ¼s -> Kaktüs, ÅžarkÄ± -> Şarkı)
  static String fixMojibake(String input) {
    if (input.isEmpty) return input;
    if (input.contains('Ä') ||
        input.contains('Ã') ||
        input.contains('Å') ||
        input.contains('Â') ||
        input.contains('â')) {
      try {
        final bytes = <int>[];
        for (final codeUnit in input.runes) {
          if (codeUnit <= 0xFF) {
            bytes.add(codeUnit);
          } else if (_cp1252ToByte.containsKey(codeUnit)) {
            bytes.add(_cp1252ToByte[codeUnit]!);
          } else {
            return input;
          }
        }
        return utf8.decode(bytes);
      } catch (_) {}
    }
    return input;
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    bool clearAlbum = false,
    Duration? duration,
    String? sourcePath,
    bool? isOnline,
    String? thumbnailUrl,
    bool? isFavorite,
    DateTime? addedAt,
    int? playCount,
    String? lyrics,
    bool clearLyrics = false,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: clearAlbum ? null : (album ?? this.album),
      duration: duration ?? this.duration,
      sourcePath: sourcePath ?? this.sourcePath,
      isOnline: isOnline ?? this.isOnline,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
      playCount: playCount ?? this.playCount,
      lyrics: clearLyrics ? null : (lyrics ?? this.lyrics),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'sourcePath': sourcePath,
      'isOnline': isOnline,
      'thumbnailUrl': thumbnailUrl,
      'isFavorite': isFavorite,
      'addedAt': addedAt.toIso8601String(),
      'playCount': playCount,
      'lyrics': lyrics,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Bilinmeyen Şarkı',
      artist: json['artist'] as String? ?? 'Bilinmeyen Sanatçı',
      album: json['album'] as String?,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      sourcePath: json['sourcePath'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      playCount: json['playCount'] as int? ?? 0,
      lyrics: json['lyrics'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourcePath == other.sourcePath;

  @override
  int get hashCode => id.hashCode ^ sourcePath.hashCode;
}

import 'track.dart';

class Playlist {
  final String id;
  String name;
  String? description;
  List<Track> tracks;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required String name,
    String? description,
    List<Track>? tracks,
    DateTime? createdAt,
  })  : name = Track.fixMojibake(name),
        description = description != null ? Track.fixMojibake(description) : null,
        tracks = tracks ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    var rawTracks = json['tracks'] as List<dynamic>? ?? [];
    return Playlist(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Çalma Listesi',
      description: json['description'] as String?,
      tracks: rawTracks.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

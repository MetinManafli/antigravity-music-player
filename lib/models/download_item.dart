import 'track.dart';

enum DownloadItemStatus {
  queued,
  downloading,
  completed,
  failed,
}

class DownloadItemProgress {
  final String id;
  final String title;
  final int index;
  DownloadItemStatus status;
  String? errorMessage;
  String? rawLog;

  DownloadItemProgress({
    required this.id,
    required String title,
    required this.index,
    this.status = DownloadItemStatus.queued,
    this.errorMessage,
    this.rawLog,
  }) : title = Track.fixMojibake(title);
}

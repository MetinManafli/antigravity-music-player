enum LibrarySortMode {
  addedNewest,
  titleAsc,
  titleDesc,
  artistAsc,
  mostPlayed,
  durationDesc;

  static const LibrarySortMode title = LibrarySortMode.titleAsc;
  static const LibrarySortMode artist = LibrarySortMode.artistAsc;
  static const LibrarySortMode duration = LibrarySortMode.durationDesc;
}



class PlayListQuery {
  /*
  static Future<List<MediaItem>> FetchPlayLists() async {
    await AudioQueryService.ready!;
    List<PlaylistModel> playlists = await AudioQueryService.audioQuery
        .queryPlaylists(sortType: PlaylistSortType.PLAYLIST);
    final uniquePlaylistNames = <String>{};
    final uniquePlaylists = <PlaylistModel>[];
    for (var playlist in playlists) {
      // Skip albums that are in the blacklist
      if (!uniquePlaylistNames.contains(playlist.playlist)) {
        uniquePlaylistNames.add(playlist.playlist);
        uniquePlaylists.add(playlist);
      }
    }
  }
  */
}

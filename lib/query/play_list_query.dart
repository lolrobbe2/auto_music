import 'package:auto_music/auto_music.dart';
import 'package:auto_music/query/root_querry.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class PlayListQuery {
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
}

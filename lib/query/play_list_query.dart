import 'package:audio_service/audio_service.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/query/root_querry.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class PlayListQuery {
  static Future<List<MediaList>> FetchPlayLists() async {
    await AudioQueryService.ready!;

    List<PlaylistModel> playlists = await AudioQueryService.audioQuery
        .queryPlaylists(sortType: PlaylistSortType.PLAYLIST);

    final Set<String> uniquePlaylistNames = {};
    final List<PlaylistModel> uniquePlaylists = [];

    for (PlaylistModel playlist in playlists) {
      if (!uniquePlaylistNames.contains(playlist.playlist)) {
        uniquePlaylistNames.add(playlist.playlist);
        uniquePlaylists.add(playlist);
      }
    }

    return uniquePlaylists.map((PlaylistModel playlist) {
      return MediaList.fromMediaItem(MediaItem(
        id: playlist.id.toString(),
        title: playlist.playlist,
        playable: false,
        extras: {'playlistId': playlist.id, 'numOfSongs': playlist.numOfSongs},
      ));
    }).toList();
  }
}

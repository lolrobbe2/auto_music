import 'package:audio_service/audio_service.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/query/root_querry.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class AlbumQuery {
  static final Set<String> _albumBlacklist = {
    "Browser",
    "Download",
    "Fiters Project",
    "fxaa",
    "shaders",
    "smaa",
    "sound_recorder",
  };
  static Future<List<MediaItem>> FetchAlbums() async {
    await AudioQueryService.ready!;
    List<AlbumModel> albums = await AudioQueryService.audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
    );
    final uniqueAlbumNames = <String>{};
    final uniqueAlbums = <AlbumModel>[];

    for (var album in albums) {
      // Skip albums that are in the blacklist
      if (!_albumBlacklist.contains(album.album)) {
        if (!uniqueAlbumNames.contains(album.album)) {
          uniqueAlbumNames.add(album.album);
          uniqueAlbums.add(album);
        }
      }
    }

    final List<MediaItem> convertedItems = uniqueAlbums.map(
    (AlbumModel album) {
      return MediaItem(
        id: album.id.toString(),
        title: album.album,
        artist: album.artist,
        album: album.album,
        artUri: Uri.parse(
          'content://media/external/audio/albumart/${album.id}',
        ),
      );
    },
  ).toList();
    return convertedItems;
  }
  static Future<List<MediaList>> FetchAlbumsList() async {
    return (await FetchAlbums()).map((MediaItem album) => MediaList.fromMediaItem(album)).toList();
  }
}

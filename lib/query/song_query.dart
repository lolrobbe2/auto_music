import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:auto_music/query/root_querry.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class SongQuery {
  static Future<List<MediaItem>> FetchSongsFromAlbum(MediaItem album) async {
    await AudioQueryService.ready!;

    List<SongModel> allSongs = await AudioQueryService.audioQuery.querySongs();

    // Filter songs by album name
    List<SongModel> albumSongs = allSongs
        .where((song) => song.album == album.title)
        .toList();

    // Check for existence and convert songs to MediaItems
    List<MediaItem> mediaItems = [];
    for (var song in albumSongs) {
      // Check if the song file exists

      if (File(song.data).existsSync()) {
        mediaItems.add(
          MediaItem(
            id: song.id.toString(),
            album: album.title,
            title: song.title,
            artist: song.artist,
            genre: song.genre,
            duration: Duration(milliseconds: song.duration ?? 0),
            artUri: Uri.parse(
              'content://media/external/audio/media/${song.id}/albumart',
            ), // Set album art URI here
            extras: {
              'mediaStoreId': song.id,
              'filePath': song.data,
              'uri': song.uri,
              'track': song.track,
            },
          ),
        );
      }
    }

    // Sort the media items by track number
    mediaItems.sort(
      (a, b) => a.extras!['track']!.compareTo(b.extras!['track']!),
    );
    return mediaItems;
  }
}

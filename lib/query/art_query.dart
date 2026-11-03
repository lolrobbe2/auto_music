import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:auto_music/query/root_querry.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class ArtQuery {
  static Future<Uint8List?> FetchArtwork(
    MediaItem mediaItem, {
    int size = 512,
    int quality = 100,
  }) async {
    await AudioQueryService.ready!;

    try {
      final Uri? artUri = mediaItem.artUri;

      // First try to retrieve album artwork from its content URI.
      if (artUri != null &&
          artUri.scheme == 'content' &&
          artUri.pathSegments.length >= 2 &&
          artUri.pathSegments[artUri.pathSegments.length - 2] == 'albumart') {
        final int? albumId = int.tryParse(artUri.pathSegments.last);

        if (albumId != null) {
          return await AudioQueryService.audioQuery.queryArtwork(
            albumId,
            ArtworkType.ALBUM,
            format: ArtworkFormat.JPEG,
            size: size,
            quality: quality,
          );
        }
      }

      // Fallback: use the MediaItem ID as an audio ID.
      final int? audioId = int.tryParse(mediaItem.id);

      if (audioId == null) {
        return null;
      }

      return await AudioQueryService.audioQuery.queryArtwork(
        audioId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: size,
        quality: quality,
      );
    } catch (exception) {
      return null;
    }
  }
}

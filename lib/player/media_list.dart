import 'package:audio_service/audio_service.dart';
import 'package:auto_music/player/auto_media_item.dart';
import 'package:flutter/widgets.dart';

class MediaList extends AutoMediaItem {
  MediaList._({
    required String name,
    required IconData icon,
    required Uri? artUri,
  }) : name = name,
       icon = icon,
       super(
         id: name,
         title: name,
         artUri: artUri,
         playable: false,
       );

  static Future<MediaList> create({
    required String name,
    required IconData icon,
  }) async {
    final AutoMediaItem item = await AutoMediaItem.create(
      id: name,
      title: name,
      icon: icon,
      playable: false,
    );

    return MediaList._(
      name: name,
      icon: icon,
      artUri: item.artUri,
    );
  }

  final String name;
  final IconData icon;

  final Map<String, MediaItem> _items = <String, MediaItem>{};

  Iterable<MediaItem> get items => _items.values;

  MediaItem? get(String name) => _items[name];

  MediaItem? find(bool Function(MediaItem item) predicate) {
    for (final MediaItem item in _items.values) {
      if (predicate(item)) {
        return item;
      }
    }
    return null;
  }

  Iterable<MediaItem> findByTitle(String title) {
    final String query = title.trim().toLowerCase();

    return _items.values.where(
      (MediaItem item) => item.title.toLowerCase().contains(query),
    );
  }

  Future<({bool found, List<MediaItem> children})> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    if (parentMediaId == id) {
      return (found: true, children: _items.values.toList());
    }

    for (final MediaItem item in _items.values) {
      if (item is MediaList) {
        final result = await item.getChildren(parentMediaId, options);

        if (result.found) {
          return result;
        }
      }
    }

    return (found: false, children: <MediaItem>[]);
  }

  void add(MediaItem mediaItem) {
    _items[mediaItem.id] = mediaItem;
  }
}

extension MediaListSearchExtensions on MediaList {
  Iterable<MediaItem> findByAlbum(String album) {
    final String query = album.trim().toLowerCase();

    return items.where(
      (MediaItem item) => item.album?.toLowerCase().contains(query) ?? false,
    );
  }

  Iterable<MediaItem> findByArtist(String artist) {
    final String query = artist.trim().toLowerCase();

    return items.where(
      (MediaItem item) => item.artist?.toLowerCase().contains(query) ?? false,
    );
  }

  Iterable<MediaItem> findByGenre(String genre) {
    final String query = genre.trim().toLowerCase();

    return items.where(
      (MediaItem item) => item.genre?.toLowerCase().contains(query) ?? false,
    );
  }
}
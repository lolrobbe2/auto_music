import 'package:audio_service/audio_service.dart';

class MediaList extends MediaItem {
  MediaList({required this.name})
    : super(id: name, title: name, playable: false);

  final Map<String, MediaItem> _items = new Map();
  final String name;
  MediaItem? get(String name) {
    return _items[name];
  }

  MediaItem? find(bool Function(MediaItem item) predicate) {
    for (MediaItem item in _items.values) {
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
}

extension MediaListSearchExtensions on MediaList {
  Iterable<MediaItem> findByTitle(String title) {
    final String query = title.trim().toLowerCase();

    return _items.values.where(
      (MediaItem item) => item.title.toLowerCase().contains(query),
    );
  }

  Iterable<MediaItem> findByAlbum(String album) {
    final String query = album.trim().toLowerCase();

    return _items.values.where(
      (MediaItem item) => item.album?.toLowerCase().contains(query) ?? false,
    );
  }

  Iterable<MediaItem> findByArtist(String artist) {
    final String query = artist.trim().toLowerCase();

    return _items.values.where(
      (MediaItem item) => item.artist?.toLowerCase().contains(query) ?? false,
    );
  }

  Iterable<MediaItem> findByGenre(String genre) {
    final String query = genre.trim().toLowerCase();

    return _items.values.where(
      (MediaItem item) => item.genre?.toLowerCase().contains(query) ?? false,
    );
  }
}

import 'package:audio_service/audio_service.dart';

class MediaList extends MediaItem {
  MediaList._({
    required String name,
    required String uri,
    String? id,
    String? artist,
    String? album,
    String? genre,
    Duration? duration,
    Map<String, String>? artHeaders,
    String? displayTitle,
    String? displaySubtitle,
    String? displayDescription,
    Rating? rating,
    bool? isLive,
    Map<String, dynamic>? extras,
  }) : super(
         id: id ?? name,
         title: name,
         artist: artist,
         album: album,
         genre: genre,
         duration: duration,
         artUri: Uri.parse(uri),
         artHeaders: artHeaders,
         playable: false,
         displayTitle: displayTitle,
         displaySubtitle: displaySubtitle,
         displayDescription: displayDescription,
         rating: rating,
         isLive: isLive,
         extras: extras,
       );
  static MediaList create({
    required String name,
    String? id,
    String? uri,
    String? artist,
    String? album,
  }) {
    return MediaList._(
      name: name,
      id: id,
      uri:
          uri ??
          'android.resource://com.example.auto_music/drawable/ic_album_placeholder',
      artist: artist,
      album: album,
    );
  }
  static MediaList fromMediaItem(MediaItem item) {
    return MediaList._(
      name: item.title,
      id: item.id,
      uri:
          item.artUri?.toString() ??
          'android.resource://com.example.auto_music/drawable/ic_album_placeholder',
      artist: item.artist,
      album: item.album,
      genre: item.genre,
      duration: item.duration,
      artHeaders: item.artHeaders,
      displayTitle: item.displayTitle,
      displaySubtitle: item.displaySubtitle,
      displayDescription: item.displayDescription,
      rating: item.rating,
      isLive: item.isLive,
      extras: item.extras,
    );
  }

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
  void addMultiple(List<MediaItem> mediaItems){
    mediaItems.forEach((item) => add(item));
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

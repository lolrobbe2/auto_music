import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:audio_service/audio_service.dart';
import 'package:auto_music/widgets/art_work.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum LibraryCategory { albums, artists, genres, songs }

class MetadataEditorPage extends StatefulWidget {
  final List<MediaItem> songs;
  final Future<void> Function(String path)? onSaved;

  const MetadataEditorPage({super.key, required this.songs, this.onSaved});

  @override
  State<MetadataEditorPage> createState() => _MetadataEditorPageState();
}

class _MetadataEditorPageState extends State<MetadataEditorPage> {
  // ---------------------------------------------------------------------------
  // Search and navigation
  // ---------------------------------------------------------------------------

  final TextEditingController _searchController = TextEditingController();

  LibraryCategory _category = LibraryCategory.albums;

  String? _selectedGroup;
  MediaItem? _selectedSong;

  int _selectionGeneration = 0;

  // ---------------------------------------------------------------------------
  // Album editor
  // ---------------------------------------------------------------------------

  final TextEditingController _albumNameController = TextEditingController();

  final TextEditingController _albumArtistController = TextEditingController();

  final TextEditingController _albumYearController = TextEditingController();

  final TextEditingController _albumGenreController = TextEditingController();

  final TextEditingController _albumArtworkController = TextEditingController();

  bool _applyArtworkToAll = true;
  bool _albumChanged = false;

  // ---------------------------------------------------------------------------
  // Individual track editor
  // ---------------------------------------------------------------------------

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _artistController = TextEditingController();

  final TextEditingController _trackAlbumController = TextEditingController();

  final TextEditingController _yearController = TextEditingController();

  final TextEditingController _genreController = TextEditingController();

  final TextEditingController _trackArtworkController = TextEditingController();

  bool _trackChanged = false;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool _isSaving = false;

  String? _loadError;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshSearch);

    _searchController.dispose();

    _albumNameController.dispose();
    _albumArtistController.dispose();
    _albumYearController.dispose();
    _albumGenreController.dispose();
    _albumArtworkController.dispose();

    _titleController.dispose();
    _artistController.dispose();
    _trackAlbumController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _trackArtworkController.dispose();

    super.dispose();
  }

  void _refreshSearch() {
    setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
  // ---------------------------------------------------------------------------
  // Genre helpers
  // ---------------------------------------------------------------------------

  List<String> _genresFor(MediaItem song) {
    Object? value = song.genre;

    if (value == null || value.toString().trim().isEmpty) {
      value = song.extras?['genre'];
    }

    if (value is List) {
      return value
          .whereType<String>()
          .expand((String genre) => genre.split(','))
          .map((String genre) => genre.trim())
          .where((String genre) => genre.isNotEmpty)
          .toSet()
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((String genre) => genre.trim())
          .where((String genre) => genre.isNotEmpty)
          .toSet()
          .toList();
    }

    return <String>['Unknown genre'];
  }

  // ---------------------------------------------------------------------------
  // Library grouping
  // ---------------------------------------------------------------------------

  String _groupName(MediaItem song) {
    switch (_category) {
      case LibraryCategory.albums:
        return song.album?.trim().isNotEmpty == true
            ? song.album!.trim()
            : 'Unknown album';

      case LibraryCategory.artists:
        return song.artist?.trim().isNotEmpty == true
            ? song.artist!.trim()
            : 'Unknown artist';

      case LibraryCategory.genres:
        return _genresFor(song).first;

      case LibraryCategory.songs:
        return song.title;
    }
  }

  Map<String, List<MediaItem>> get _groups {
    final Map<String, List<MediaItem>> result = {};

    for (final MediaItem song in widget.songs) {
      if (_category == LibraryCategory.genres) {
        for (final String genre in _genresFor(song)) {
          result.putIfAbsent(genre, () => <MediaItem>[]).add(song);
        }
      } else {
        final String name = _groupName(song);
        result.putIfAbsent(name, () => <MediaItem>[]).add(song);
      }
    }

    return Map<String, List<MediaItem>>.fromEntries(
      result.entries.toList()..sort(
        (
          MapEntry<String, List<MediaItem>> a,
          MapEntry<String, List<MediaItem>> b,
        ) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      ),
    );
  }

  List<MapEntry<String, List<MediaItem>>> get _visibleGroups {
    final String query = _searchController.text.trim().toLowerCase();

    return _groups.entries.where((entry) {
      if (query.isEmpty) return true;

      return entry.key.toLowerCase().contains(query) ||
          entry.value.any((MediaItem song) {
            return song.title.toLowerCase().contains(query) ||
                (song.artist ?? '').toLowerCase().contains(query) ||
                (song.album ?? '').toLowerCase().contains(query);
          });
    }).toList();
  }

  List<MediaItem> get _visibleSongs {
    final String query = _searchController.text.trim().toLowerCase();

    Iterable<MediaItem> result = widget.songs;

    if (_selectedGroup != null) {
      final List<MediaItem> group = _groups[_selectedGroup] ?? <MediaItem>[];

      result = group;
    }

    if (query.isNotEmpty) {
      result = result.where((MediaItem song) {
        return song.title.toLowerCase().contains(query) ||
            (song.artist ?? '').toLowerCase().contains(query) ||
            (song.album ?? '').toLowerCase().contains(query) ||
            _genresFor(
              song,
            ).any((String genre) => genre.toLowerCase().contains(query));
      });
    }

    return result.toList();
  }

  List<MediaItem> get _selectedGroupSongs {
    if (_selectedGroup == null) return <MediaItem>[];

    return _groups[_selectedGroup] ?? <MediaItem>[];
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<bool> _requestFileAccess() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return true;
    }

    status = await Permission.manageExternalStorage.request();

    return status.isGranted;
  }

  // ---------------------------------------------------------------------------
  // Selecting library categories
  // ---------------------------------------------------------------------------

  void _selectCategory(LibraryCategory category) {
    setState(() {
      _category = category;
      _selectedGroup = null;
      _selectedSong = null;
      _searchController.clear();
      _loadError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Selecting groups
  // ---------------------------------------------------------------------------

  Future<void> _selectGroup(String groupName) async {
    final int generation = ++_selectionGeneration;

    setState(() {
      _selectedGroup = groupName;
      _selectedSong = null;
      _loadError = null;
      _isLoading = _category == LibraryCategory.albums;
      _albumChanged = false;
      _trackChanged = false;
    });

    if (_category != LibraryCategory.albums) return;

    // Give Flutter an opportunity to display the loading state.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    if (!mounted || generation != _selectionGeneration) return;

    final List<MediaItem> songs = _selectedGroupSongs;

    String album = groupName;
    String artist = '';
    String year = '';

    final Set<String> genres = <String>{};

    // Read every track in the album so the album editor can collect
    // the metadata from all of its songs.
    for (final MediaItem song in songs) {
      final String? path = _filePath(song);

      if (path == null) continue;

      try {
        final AudioMetadata metadata = readMetadata(
          File(path),
          getImage: false,
        );

        if (artist.isEmpty && metadata.artist?.isNotEmpty == true) {
          artist = metadata.artist!;
        }

        if (album.isEmpty && metadata.album?.isNotEmpty == true) {
          album = metadata.album!;
        }

        if (year.isEmpty && metadata.year != null) {
          year = metadata.year!.year.toString();
        }

        genres.addAll(metadata.genres);
      } catch (error) {
        debugPrint('ALBUM METADATA READ ERROR ($path): $error');

        // Use the information already available in the MediaItem
        // when a file cannot be read.
        genres.addAll(_genresFor(song));
      }
    }

    if (!mounted || generation != _selectionGeneration) return;

    setState(() {
      _albumNameController.text = album;

      _albumArtistController.text = artist.isNotEmpty
          ? artist
          : songs.firstOrNull?.artist ?? '';

      _albumYearController.text = year;

      _albumGenreController.text = genres
          .where((String genre) => genre != 'Unknown genre')
          .join(', ');

      _albumArtworkController.clear();

      _applyArtworkToAll = true;
      _albumChanged = false;
      _isLoading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Selecting individual tracks
  // ---------------------------------------------------------------------------

  String? _filePath(MediaItem song) {
    final Object? path = song.extras?['filePath'];

    if (path is String && path.isNotEmpty) {
      return path;
    }

    return null;
  }

  Future<void> _selectSong(MediaItem song) async {
    if (_isSaving) return;

    final int generation = ++_selectionGeneration;

    final String? path = _filePath(song);

    if (path == null) {
      _showMessage('This song has no file path.');
      return;
    }

    setState(() {
      _selectedSong = song;
      _loadError = null;
      _isLoading = true;
      _trackChanged = false;
    });

    _clearTrackFields();

    await Future<void>.delayed(const Duration(milliseconds: 20));

    if (!mounted || generation != _selectionGeneration) return;

    try {
      final File file = File(path);

      if (!await file.exists()) {
        throw Exception('File does not exist: $path');
      }

      final AudioMetadata metadata = readMetadata(file, getImage: false);

      if (!mounted || generation != _selectionGeneration) return;

      setState(() {
        _titleController.text = metadata.title ?? '';
        _artistController.text = metadata.artist ?? '';
        _trackAlbumController.text = metadata.album ?? '';
        _yearController.text = metadata.year?.year.toString() ?? '';
        _genreController.text = metadata.genres.join(', ');

        _trackArtworkController.clear();

        _isLoading = false;
        _trackChanged = false;
      });
    } catch (error, stackTrace) {
      debugPrint('METADATA READ ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  void _clearTrackFields() {
    _titleController.clear();
    _artistController.clear();
    _trackAlbumController.clear();
    _yearController.clear();
    _genreController.clear();
    _trackArtworkController.clear();
  }

  void _backToGroup() {
    setState(() {
      _selectedSong = null;
      _trackChanged = false;
      _loadError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Artwork download
  // ---------------------------------------------------------------------------

  Future<Picture> _downloadPicture(String imageUrl) async {
    final Uri uri = Uri.parse(imageUrl.trim());

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw Exception('Artwork URL must start with http:// or https://.');
    }

    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Unable to download artwork. HTTP ${response.statusCode}.',
        );
      }

      if (response.contentLength > 15 * 1024 * 1024) {
        throw Exception('Artwork image is larger than 15 MB.');
      }

      final List<int> bytes = await response.fold<List<int>>(<int>[], (
        List<int> result,
        List<int> chunk,
      ) {
        result.addAll(chunk);
        return result;
      });

      if (bytes.isEmpty) {
        throw Exception('The artwork image is empty.');
      }

      final String mimeType =
          response.headers.contentType?.mimeType ??
          _imageMimeFromPath(uri.path);

      if (!mimeType.startsWith('image/')) {
        throw Exception('The URL did not return an image.');
      }

      return Picture(
        Uint8List.fromList(bytes),
        mimeType,
        PictureType.coverFront,
      );
    } finally {
      client.close(force: true);
    }
  }

  String _imageMimeFromPath(String path) {
    final String lower = path.toLowerCase();

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';

    return 'image/jpeg';
  }

  // ---------------------------------------------------------------------------
  // File validation
  // ---------------------------------------------------------------------------

  bool _canWriteFile(String path) {
    const List<String> extensions = <String>[
      '.mp3',
      '.m4a',
      '.mp4',
      '.flac',
      '.wav',
      '.ape',
    ];

    final String lower = path.toLowerCase();

    return extensions.any((String extension) => lower.endsWith(extension));
  }

  int? _parseYear(String text) {
    if (text.trim().isEmpty) return null;

    final int? year = int.tryParse(text.trim());

    if (year == null || year < 1 || year > 9999) {
      throw Exception('Please enter a valid year.');
    }

    return year;
  }

  List<String> _parseGenres(String text) {
    return text
        .split(',')
        .map((String genre) => genre.trim())
        .where((String genre) => genre.isNotEmpty)
        .toSet()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Apply album metadata to every track
  // ---------------------------------------------------------------------------

  Future<void> _saveAlbum() async {
    if (_selectedGroup == null || _isSaving || _isLoading) return;

    setState(() {
      _isSaving = true;
    });

    int saved = 0;
    final List<String> errors = <String>[];

    try {
      final bool permitted = await _requestFileAccess();

      if (!permitted) {
        throw Exception('Storage permission was not granted.');
      }

      final List<MediaItem> songs = _selectedGroupSongs;

      if (songs.isEmpty) {
        throw Exception('This album does not contain any tracks.');
      }

      final String album = _albumNameController.text.trim();
      final String artist = _albumArtistController.text.trim();

      final int? year = _parseYear(_albumYearController.text);

      final List<String> genres = _parseGenres(_albumGenreController.text);

      // Download artwork once, then reuse it for all tracks.
      Picture? picture;

      final String artworkUrl = _albumArtworkController.text.trim();

      if (_applyArtworkToAll && artworkUrl.isNotEmpty) {
        picture = await _downloadPicture(artworkUrl);
      }

      final Set<String> processedPaths = <String>{};

      for (final MediaItem song in songs) {
        final String? path = _filePath(song);

        if (path == null || !processedPaths.add(path)) {
          continue;
        }

        try {
          final File file = File(path);

          if (!await file.exists()) {
            throw Exception('File does not exist.');
          }

          if (!_canWriteFile(path)) {
            throw Exception('Unsupported file format.');
          }

          updateMetadata(file, (metadata) {
            // Preserve each track's title and track number.
            metadata.setAlbum(album);
            metadata.setArtist(artist);
            metadata.setYear(year == null ? null : DateTime(year));
            metadata.setGenres(genres);

            if (picture != null) {
              metadata.setPictures(<Picture>[picture!]);
            }
          });

          saved++;

          if (widget.onSaved != null) {
            await widget.onSaved!(path);
          }
        } catch (error) {
          errors.add('${song.title}: $error');
          debugPrint('ALBUM SAVE ERROR ($path): $error');
        }
      }

      if (!mounted) return;

      setState(() {
        _albumChanged = false;
      });

      if (errors.isEmpty) {
        _showMessage('Updated $saved tracks successfully.');
      } else {
        _showMessage(
          'Updated $saved tracks. ${errors.length} failed. '
          'See debug output for details.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('ALBUM SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('Unable to save album: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Save individual track metadata
  // ---------------------------------------------------------------------------

  Future<void> _saveSong() async {
    final MediaItem? song = _selectedSong;

    if (song == null || _isSaving || _isLoading) return;

    final String? path = _filePath(song);

    if (path == null) {
      _showMessage('This song has no file path.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bool permitted = await _requestFileAccess();

      if (!permitted) {
        throw Exception('Storage permission was not granted.');
      }

      final File file = File(path);

      if (!await file.exists()) {
        throw Exception('File does not exist.');
      }

      if (!_canWriteFile(path)) {
        throw Exception('Unsupported file format.');
      }

      final int? year = _parseYear(_yearController.text);

      final List<String> genres = _parseGenres(_genreController.text);

      Picture? picture;

      final String artworkUrl = _trackArtworkController.text.trim();

      if (artworkUrl.isNotEmpty) {
        picture = await _downloadPicture(artworkUrl);
      }

      updateMetadata(file, (metadata) {
        metadata.setTitle(_titleController.text.trim());
        metadata.setArtist(_artistController.text.trim());
        metadata.setAlbum(_trackAlbumController.text.trim());
        metadata.setYear(year == null ? null : DateTime(year));
        metadata.setGenres(genres);

        if (picture != null) {
          metadata.setPictures(<Picture>[picture!]);
        }
      });

      if (widget.onSaved != null) {
        await widget.onSaved!(path);
      }

      if (!mounted) return;

      setState(() {
        _trackChanged = false;
      });

      _showMessage('Track metadata saved.');
    } catch (error, stackTrace) {
      debugPrint('TRACK SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('Unable to save track: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Artwork display
  // ---------------------------------------------------------------------------

  Widget _buildArtwork(MediaItem song, {String? imageUrl, double size = 100}) {
    final String url = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? Artwork(item: song)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Artwork(item: song);
                    },
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category selector
  // ---------------------------------------------------------------------------

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _categoryChip(LibraryCategory.albums, 'Albums', Icons.album_outlined),
          _categoryChip(
            LibraryCategory.artists,
            'Artists',
            Icons.person_outline,
          ),
          _categoryChip(
            LibraryCategory.genres,
            'Genres',
            Icons.category_outlined,
          ),
          _categoryChip(
            LibraryCategory.songs,
            'Songs',
            Icons.music_note_outlined,
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(LibraryCategory category, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: _category == category,
        onSelected: (bool selected) {
          if (selected) {
            _selectCategory(category);
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Library panel
  // ---------------------------------------------------------------------------

  Widget _buildLibrary() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search music...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        _buildCategorySelector(),

        const Divider(height: 20),

        Expanded(
          child: _category == LibraryCategory.songs
              ? _buildTrackList(_visibleSongs)
              : _buildGroupList(),
        ),
      ],
    );
  }

  Widget _buildGroupList() {
    final List<MapEntry<String, List<MediaItem>>> groups = _visibleGroups;

    if (groups.isEmpty) {
      return _buildEmptyMessage('No groups found.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, List<MediaItem>> group = groups[index];

        final MediaItem representative = group.value.first;

        final bool selected = _selectedGroup == group.key;

        return ListTile(
          selected: selected,
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: _buildArtwork(representative, size: 54),
          title: Text(group.key, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${group.value.length} songs', maxLines: 1),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectGroup(group.key),
        );
      },
    );
  }

  Widget _buildTrackList(List<MediaItem> songs) {
    if (songs.isEmpty) {
      return _buildEmptyMessage('No songs found.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: songs.length,
      itemBuilder: (BuildContext context, int index) {
        final MediaItem song = songs[index];

        return _buildTrackTile(song);
      },
    );
  }

  Widget _buildTrackTile(MediaItem song) {
    final bool selected = _selectedSong?.id == song.id;

    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildArtwork(song, size: 52),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (song.artist?.isNotEmpty == true) song.artist!,
          if (song.album?.isNotEmpty == true) song.album!,
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selected
          ? const Icon(Icons.edit)
          : const Icon(Icons.chevron_right),
      onTap: () => _selectSong(song),
    );
  }

  // ---------------------------------------------------------------------------
  // Album editor
  // ---------------------------------------------------------------------------

  Widget _buildAlbumEditor() {
    final List<MediaItem> songs = _selectedGroupSongs;

    if (songs.isEmpty) {
      return _buildEmptyMessage('This album has no tracks.');
    }

    final MediaItem representative = songs.first;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildArtwork(
                    representative,
                    imageUrl: _albumArtworkController.text,
                    size: 124,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _albumNameController.text.isEmpty
                              ? representative.album ?? 'Unknown album'
                              : _albumNameController.text,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${songs.length} tracks',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Album editor',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Album information',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              _buildField(
                'Album name',
                _albumNameController,
                Icons.album_outlined,
                onChanged: () => _albumChanged = true,
              ),

              const SizedBox(height: 12),

              _buildField(
                'Artist',
                _albumArtistController,
                Icons.person_outline,
                onChanged: () => _albumChanged = true,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      'Year',
                      _albumYearController,
                      Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: () => _albumChanged = true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      'Genre',
                      _albumGenreController,
                      Icons.category_outlined,
                      hint: 'Rock, Metal, Blues',
                      onChanged: () => _albumChanged = true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildField(
                'Artwork image URL',
                _albumArtworkController,
                Icons.image_outlined,
                keyboardType: TextInputType.url,
                hint: 'https://example.com/cover.jpg',
                onChanged: () => setState(() {
                  _albumChanged = true;
                }),
              ),

              const SizedBox(height: 12),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _applyArtworkToAll,
                onChanged: _isSaving
                    ? null
                    : (bool? value) {
                        setState(() {
                          _applyArtworkToAll = value ?? false;
                          _albumChanged = true;
                        });
                      },
                title: const Text('Apply artwork to every track'),
                subtitle: const Text(
                  'When disabled, existing track artwork is preserved.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAlbum,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Updating tracks...'
                        : 'Save to all ${songs.length} tracks',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Tracks in this album',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              Text(
                'Select a track to edit its metadata individually.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 8),

              ...songs.map(_buildTrackTile),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual track editor
  // ---------------------------------------------------------------------------

  Widget _buildTrackEditor() {
    final MediaItem? song = _selectedSong;

    if (song == null) {
      return _buildEmptyMessage('Select an album, artist or genre.');
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _buildError();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _backToGroup,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to collection'),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildArtwork(
                    song,
                    imageUrl: _trackArtworkController.text,
                    size: 112,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(song.artist ?? 'Unknown artist'),
                        const SizedBox(height: 6),
                        Text(
                          'Individual track editor',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Track information',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              _buildField(
                'Title',
                _titleController,
                Icons.music_note_outlined,
                onChanged: () => _trackChanged = true,
              ),

              const SizedBox(height: 12),

              _buildField(
                'Artist',
                _artistController,
                Icons.person_outline,
                onChanged: () => _trackChanged = true,
              ),

              const SizedBox(height: 12),

              _buildField(
                'Album',
                _trackAlbumController,
                Icons.album_outlined,
                onChanged: () => _trackChanged = true,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      'Year',
                      _yearController,
                      Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: () => _trackChanged = true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      'Genre',
                      _genreController,
                      Icons.category_outlined,
                      hint: 'Rock, Metal',
                      onChanged: () => _trackChanged = true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildField(
                'Artwork image URL',
                _trackArtworkController,
                Icons.image_outlined,
                keyboardType: TextInputType.url,
                hint: 'Leave empty to keep current artwork',
                onChanged: () => setState(() {
                  _trackChanged = true;
                }),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveSong,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save track'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Common widgets
  // ---------------------------------------------------------------------------

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      onChanged: (String value) {
        onChanged?.call();
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 58,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Unable to read metadata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_loadError ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectedSong == null
                  ? null
                  : () => _selectSong(_selectedSong!),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Detail panel
  // ---------------------------------------------------------------------------

  Widget _buildDetailPanel() {
    if (_selectedSong != null) {
      return _buildTrackEditor();
    }

    if (_selectedGroup == null) {
      return _buildEmptyMessage(
        'Select an album, artist or genre to get started.',
      );
    }

    if (_category == LibraryCategory.albums) {
      return _buildAlbumEditor();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedGroup!,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text('${_selectedGroupSongs.length} tracks'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildTrackList(_selectedGroupSongs)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Main layout
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metadata editor')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                Expanded(flex: 4, child: _buildLibrary()),
                const Divider(height: 1),
                Expanded(flex: 6, child: _buildDetailPanel()),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 340, child: _buildLibrary()),
              const VerticalDivider(width: 1),
              Expanded(child: _buildDetailPanel()),
            ],
          );
        },
      ),
    );
  }
}

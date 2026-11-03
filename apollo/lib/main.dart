import 'package:auto_music/auto_music.dart';
import 'package:auto_music/player/auto_music_player.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/query/album_query.dart';
import 'package:auto_music/query/song_query.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AutoMusic and its player.
  AutoMusic();

  // Wait until the root MediaList has been initialized.
  await AutoMusicPlayer.ready!;

  final MediaList albums = await MediaList.create(name: 'Albums');
  final MediaList playlists = await MediaList.create(name: 'Playlists');

  final List<MediaList> albumList = await AlbumQuery.FetchAlbumsList();

  for (final MediaList album in albumList) {
    final List<MediaItem> songs = await SongQuery.FetchSongsFromAlbum(album);

    album.addMultiple(songs);
    albums.add(album);
  }

  // Register the library in the media browser.
  AutoMusicPlayer.add(albums);
  AutoMusicPlayer.add(playlists);

  // Initialize audio_service with your custom handler.
  await AutoMusic.init();

  runApp(MyApp(albums: albumList));
}

class MyApp extends StatelessWidget {
  final List<MediaList> albums;

  const MyApp({super.key, required this.albums});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto Music',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: PlayerShell(albums: albums),
    );
  }
}

class PlayerShell extends StatelessWidget {
  final List<MediaList> albums;

  const PlayerShell({super.key, required this.albums});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Music'), centerTitle: true),
      body: PlayerPage(albums: albums),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Player',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}

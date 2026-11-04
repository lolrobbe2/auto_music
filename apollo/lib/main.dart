import 'package:auto_music/auto_music.dart';
import 'package:auto_music/player/auto_music_player.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/query/album_query.dart';
import 'package:auto_music/query/song_query.dart';
import 'package:auto_music/widgets/settings_page.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AutoMusic and its player.
  AutoMusic();

  // Wait for the player and root media list.
  await AutoMusicPlayer.ready!;

  // Create root categories.
  final MediaList albums = MediaList.create(name: 'Albums');

  final MediaList playlists = MediaList.create(name: 'Playlists');

  // Fetch albums and their songs.
  final List<MediaList> albumList = await AlbumQuery.FetchAlbumsList();

  for (final MediaList album in albumList) {
    final List<MediaItem> songs = await SongQuery.FetchSongsFromAlbum(album);

    album.addMultiple(songs);
    albums.add(album);
  }

  // Register categories in the media hierarchy.
  AutoMusicPlayer.add(albums);
  AutoMusicPlayer.add(playlists);

  // Initialize audio_service.
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
      home: MediaNavigation(
        root: AutoMusicPlayer.root!,
        playerPage: PlayerPage(albums: albums),
        equalizerPage: const EqualizerPage(),
        autoEqualizerPage: const AutoEqualizerPage(),
        settingsPage: SettingsPage(
          songs: [
            for (final MediaList album in albums)
              ...album.items.where((item) => item.playable == true),
          ],
        ),
      ),
    );
  }
}

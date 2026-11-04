import 'package:audio_service/audio_service.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/widgets/media_list.dart';
import 'package:flutter/material.dart';

class MediaNavigation extends StatefulWidget {
  final MediaList root;
  final Widget playerPage;
  final Widget equalizerPage;
  final Widget autoEqualizerPage;
  final Widget settingsPage;
  final String title;

  const MediaNavigation({
    super.key,
    required this.root,
    required this.playerPage,
    required this.equalizerPage,
    required this.autoEqualizerPage,
    required this.settingsPage,
    this.title = 'Auto Music',
  });

  @override
  State<MediaNavigation> createState() => _MediaNavigationState();
}

class _MediaNavigationState extends State<MediaNavigation> {
  int _selectedIndex = 0;

  String _getTitle(MediaItem item) {
    if (item.displayTitle?.isNotEmpty == true) {
      return item.displayTitle!;
    }

    return item.title;
  }

  IconData _getIcon(MediaItem item) {
    final String title = item.title.toLowerCase();

    if (title.contains('album')) return Icons.album_outlined;
    if (title.contains('playlist')) return Icons.queue_music_outlined;
    if (title.contains('artist')) return Icons.person_outline;
    if (title.contains('genre')) return Icons.category_outlined;

    return item.playable == true
        ? Icons.music_note_outlined
        : Icons.folder_outlined;
  }

  IconData _getSelectedIcon(MediaItem item) {
    final String title = item.title.toLowerCase();

    if (title.contains('album')) return Icons.album;
    if (title.contains('playlist')) return Icons.queue_music;
    if (title.contains('artist')) return Icons.person;
    if (title.contains('genre')) return Icons.category;

    return item.playable == true ? Icons.music_note : Icons.folder;
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => widget.settingsPage));
  }

  @override
  Widget build(BuildContext context) {
    final List<MediaItem> rootItems = widget.root.items.toList();

    // Fixed destinations followed by dynamic media destinations.
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.music_note_outlined),
        selectedIcon: Icon(Icons.music_note),
        label: 'Player',
      ),
      const NavigationDestination(
        icon: Icon(Icons.equalizer_outlined),
        selectedIcon: Icon(Icons.equalizer),
        label: 'Equalizer',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: 'Auto EQ',
      ),
      ...rootItems.map(
        (MediaItem item) => NavigationDestination(
          icon: Icon(_getIcon(item)),
          selectedIcon: Icon(_getSelectedIcon(item)),
          label: _getTitle(item),
        ),
      ),
    ];

    // Keep exactly the same order as the destinations.
    final List<Widget> pages = [
      widget.playerPage,
      widget.equalizerPage,
      widget.autoEqualizerPage,
      ...rootItems.map(
        (MediaItem item) =>
            MediaListWidget(key: ValueKey(item.id), rootItem: item),
      ),
    ];

    final int selectedIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedIndex == 0 ? widget.title : destinations[selectedIndex].label,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}

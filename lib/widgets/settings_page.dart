import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'metadata_editor_page.dart';

class SettingsPage extends StatelessWidget {
  final List<MediaItem> songs;

  const SettingsPage({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('Edit music metadata'),
            subtitle: const Text('Find online matches and update song tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MetadataEditorPage(songs: songs),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

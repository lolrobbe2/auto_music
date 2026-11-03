import 'package:audio_service/audio_service.dart';
import 'package:auto_music/auto_music.dart';
import 'package:flutter/material.dart';

class AutoEqualizerPage extends StatefulWidget {
  const AutoEqualizerPage({super.key});

  @override
  State<AutoEqualizerPage> createState() => _AutoEqualizerPageState();
}

class _AutoEqualizerPageState extends State<AutoEqualizerPage> {
  bool get _enabled => AutoMusic.player.autoEqualizer.automaticEnabled;

  Future<void> _toggle(bool enabled) async {
    final MediaItem? currentItem = AutoMusic.player.mediaItem.value;

    await AutoMusic.player.autoEqualizer.setAutomaticEnabled(
      enabled,
      currentItem: currentItem,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.auto_awesome,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Automatic Equalizer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Automatically adapts your equalizer settings '
          'to the currently playing music.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        Card(
          child: SwitchListTile(
            title: const Text('Enable Auto EQ'),
            subtitle: const Text('Automatically select equalizer profiles'),
            value: _enabled,
            onChanged: _toggle,
          ),
        ),
        const SizedBox(height: 20),
        StreamBuilder<MediaItem?>(
          stream: AutoMusic.player.mediaItem,
          initialData: AutoMusic.player.mediaItem.value,
          builder: (context, snapshot) {
            final MediaItem? item = snapshot.data;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Current track'),
                subtitle: Text(item?.title ?? 'Nothing playing'),
                trailing: Text(item?.genre ?? 'Unknown genre'),
              ),
            );
          },
        ),
      ],
    );
  }
}

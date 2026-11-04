import 'package:auto_music/auto_music.dart';
import 'package:flutter/material.dart';

class AutoEqualizerPage extends StatefulWidget {
  const AutoEqualizerPage({super.key});

  @override
  State<AutoEqualizerPage> createState() => _AutoEqualizerPageState();
}

class _AutoEqualizerPageState extends State<AutoEqualizerPage> {
  bool get _enabled => AutoMusic.player.autoEqualizer.automaticEnabled;

  String get _selectedProfile => AutoMusic.player.autoEqualizer.selectedProfile;

  List<String> get _profiles =>
      AutoMusic.player.autoEqualizer.availableProfiles;

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

  Future<void> _selectProfile(String? profile) async {
    if (profile == null) return;

    await AutoMusic.player.autoEqualizer.setManualProfile(profile);

    if (mounted) {
      setState(() {});
    }
  }

  String _formatProfileName(String profile) {
    return profile
        .split('-')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),

        Icon(Icons.auto_awesome, size: 64, color: theme.colorScheme.primary),

        const SizedBox(height: 16),

        Text(
          'Equalizer',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),

        const SizedBox(height: 8),

        Text(
          'Automatically adapt your equalizer settings '
          'or manually select your preferred sound profile.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),

        const SizedBox(height: 32),

        Card(
          child: SwitchListTile(
            secondary: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Enable Auto EQ'),
            subtitle: Text(
              _enabled
                  ? 'Automatically select profiles based on genre'
                  : 'Manually select your equalizer profile',
            ),
            value: _enabled,
            onChanged: _toggle,
          ),
        ),

        const SizedBox(height: 20),

        // Manual profile selection.
        if (!_enabled) ...[
          Text('Equalizer Profiles', style: theme.textTheme.titleMedium),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.equalizer),
                      SizedBox(width: 12),
                      Text('Select a profile'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedProfile,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: _profiles.map((String profile) {
                      return DropdownMenuItem<String>(
                        value: profile,
                        child: Text(_formatProfileName(profile)),
                      );
                    }).toList(),
                    onChanged: _selectProfile,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Your selected profile is applied immediately.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],

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

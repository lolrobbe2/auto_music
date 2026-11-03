import 'package:audio_service/audio_service.dart';
import 'package:auto_music/auto_music.dart';
import 'package:auto_music/player/auto_music_player.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/widgets/art_work.dart';
import 'package:auto_music/widgets/media_list.dart';
import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  final List<MediaList> albums;

  const PlayerPage({super.key, required this.albums});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  Future<void> _showMediaBrowser() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: MediaListWidget(rootItem: AutoMusicPlayer.root!),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final player = AutoMusic.player;

    return StreamBuilder<MediaItem?>(
      stream: player.mediaItem,
      initialData: player.mediaItem.value,
      builder: (context, mediaSnapshot) {
        final MediaItem? item = mediaSnapshot.data;

        return StreamBuilder<PlaybackState>(
          stream: player.playbackState,
          initialData: player.playbackState.value,
          builder: (context, playbackSnapshot) {
            final bool isPlaying = playbackSnapshot.data?.playing ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  Artwork(item: item),

                  const SizedBox(height: 32),

                  Text(
                    item?.title ?? 'Nothing playing',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    item?.artist ?? 'Choose a song to start listening',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  if (item?.album != null) ...[
                    const SizedBox(height: 4),
                    Text(item!.album!, textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: 32),

                  _ProgressBar(duration: item?.duration ?? Duration.zero),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        onPressed: item == null
                            ? null
                            : () => player.skipToPrevious(),
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),

                      const SizedBox(width: 24),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        onPressed: item == null
                            ? null
                            : () {
                                if (isPlaying) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              },
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 36,
                        ),
                      ),

                      const SizedBox(width: 24),

                      IconButton(
                        iconSize: 36,
                        onPressed: item == null
                            ? null
                            : () => player.skipToNext(),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  OutlinedButton.icon(
                    onPressed: _showMediaBrowser,
                    icon: const Icon(Icons.library_music),
                    label: const Text('Browse media'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration duration;

  const _ProgressBar({required this.duration});

  @override
  Widget build(BuildContext context) {
    final player = AutoMusic.player;
    final int durationMs = duration.inMilliseconds;

    return StreamBuilder<Duration>(
      stream: player.positionStream,
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final Duration position = snapshot.data ?? Duration.zero;

        final double maxValue = durationMs > 0 ? durationMs.toDouble() : 1.0;

        final double currentValue = durationMs > 0
            ? position.inMilliseconds.clamp(0, durationMs).toDouble()
            : 0.0;

        return Column(
          children: [
            Slider(
              value: currentValue,
              max: maxValue,
              onChanged: durationMs > 0
                  ? (value) {
                      player.seek(Duration(milliseconds: value.round()));
                    }
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(position)),
                  Text(_formatTime(duration)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(Duration duration) {
    final String minutes = duration.inMinutes.toString().padLeft(2, '0');

    final String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }
}

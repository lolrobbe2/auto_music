import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:auto_music/player/auto_equalizer.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/service_log_printer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class AutoMusicPlayer extends BaseAudioHandler with QueueHandler, SeekHandler {
  static const String notificationChannelId =
      'com.example.apollo.channel.audio';
  static const String notificationChannelName = 'Auto Music';
  static final Logger _logger = Logger(
    printer: ServiceLogPrinter('AutoMusicPlayer'),
  );
  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]),
  );
  static bool playing = false;
  final AndroidEqualizer _equalizer = AndroidEqualizer();

  late final AutoEqualizer _autoEqualizer = AutoEqualizer(_equalizer);

  AndroidEqualizer get equalizer => _equalizer;

  AutoEqualizer get autoEqualizer => _autoEqualizer;

  AutoMusicPlayer() {
    ready ??= _initialize();
  }
  Future<void> _initialize() async {
    _player.setVolume(0);
    root = await MediaList.create(name: "root");
    final session = await AudioSession.instance;

    await session.configure(const AudioSessionConfiguration.music());

    await _equalizer.setEnabled(true);
    
    _player.playbackEventStream.listen(_broadcastState);

    // Listen to changes in the sequence
    _player.sequenceStateStream.listen((sequenceState) {
      final items = sequenceState.sequence
          .map(
            (source) => MediaItem(
              id: source.tag.id,
              album: source.tag.album,
              title: source.tag.title,
              artist: source.tag.artist,
              duration: source.tag.duration,
              artUri: source.tag.artUri,
            ),
          )
          .toList();
      queue.add(items);
    });

    Rx.combineLatest2<int?, List<MediaItem>, MediaItem?>(
          _player.currentIndexStream,
          queue,
          (index, items) {
            if (index == null || index < 0 || index >= items.length) {
              return null;
            }

            return items[index];
          },
        )
        .distinct((previous, current) {
          return previous?.id == current?.id;
        })
        .listen((item) {
          mediaItem.add(item);

          if (item != null) {
            unawaited(_autoEqualizer.applyFor(item));
          }
        });
    AudioService.androidForceEnableMediaButtons();
    _player.setVolume(1);
  }

  static MediaList? root;
  static Future<void>? ready;
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final result = await root!.getChildren(parentMediaId, extras);
    if (result.found) {
      return result.children;
    }
    _logger.e('Unable to find children for mediaId: $parentMediaId');
    return [];
  }

  static void add(MediaItem mediaItem) {
    root!.add(mediaItem);
  }

  void _broadcastState(PlaybackEvent event) {
    final bool isPlaying = _player.playing;

    final AudioProcessingState processingState =
        const <ProcessingState, AudioProcessingState>{
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ??
        AudioProcessingState.idle;

    final PlaybackState state = playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1, 3],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekBackward,
        MediaAction.seekForward,
        //MediaAction.playFromSearch,
      },
      processingState: processingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );

    playbackState.add(state);
  }

  @override
  Future<void> play() async {
    playing = true;
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playing = false;
  }

  @override
  Future<void> seek(Duration position, {int? index}) =>
      _player.seek(position, index: index);

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> clearQueue() async {
    await _player.stop(); // Stop any current playback
    final currentQueue = List<MediaItem>.from(queue.value);

    // Remove all items from the queue
    for (int i = currentQueue.length - 1; i >= 0; i--) {
      removeQueueItem(currentQueue[i]);
    }

    mediaItem.add(null); // Clear current media item
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: []),
    ); // Reset audio source
    updateQueue(queue.value);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final newQueue = [...queue.value, mediaItem];
    queue.add(newQueue);
    updateQueue(newQueue);
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final mediaItem = root!.findById(mediaId);
    if (mediaItem != null) {
      await playMediaItem(mediaItem);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await clearQueue();
    final newQueue = [...queue.value, ...mediaItems];
    queue.add(newQueue);

    final newAudioSource = ConcatenatingAudioSource(
      children: newQueue.map((item) {
        final uri = item.extras != null && item.extras!['uri'] != null
            ? Uri.parse(item.extras!['uri'])
            : Uri.parse(item.id);
        return AudioSource.uri(uri, tag: item);
      }).toList(),
    );
    updateQueue(newQueue);

    await _player.setAudioSource(newAudioSource, initialIndex: 0);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    // Check if the media item is already in the queue
    int index = queue.hasValue ? queue.value.indexOf(mediaItem) : -1;
    if (index != -1) {
      await skipToIndex(index);
    } else if (mediaItem is MediaList) {
      await clearQueue();
      await addQueueItems(mediaItem.GetValues());
    } else {
      await addQueueItems(root!.findParent(mediaItem.id)!.GetValues());
    }
    print("Prepared to play new media item: ${mediaItem.title}");
    index = queue.hasValue ? queue.value.indexOf(mediaItem) : -1;
    if (index == -1) {
      return;
    }

    await skipToIndex(index);
  }

  @override
  Future<void> skipToNext() async {
    if (queue.value.isNotEmpty && _player.currentIndex != null) {
      final nextIndex = (_player.currentIndex! + 1) % queue.value.length;
      await _player.seek(Duration.zero, index: nextIndex);
      await play();
    }
  }

  Future<void> skipToIndex(int index) async {
    final int queueLength = queue.value.length;

    if (index < 0 || index >= queueLength) {
      _logger.w('Invalid queue index: $index. Queue length: $queueLength');
      return;
    }

    await _player.seek(Duration.zero, index: index);

    await play();
  }

  @override
  Future<void> skipToPrevious() async {
    if (queue.value.isNotEmpty && _player.currentIndex != null) {
      final previousIndex =
          (_player.currentIndex! - 1 + queue.value.length) % queue.value.length;
      await _player.seek(Duration.zero, index: previousIndex);
      await play();
    }
  }
}

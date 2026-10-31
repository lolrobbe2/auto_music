import 'package:audio_service/audio_service.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/service_log_printer.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class AutoMusicPlayer extends BaseAudioHandler with QueueHandler, SeekHandler {
  static const String notificationChannelId = 'auto_music.audio';
  static const String notificationChannelName = 'Auto Music';
  static final Logger _logger = Logger(
    printer: ServiceLogPrinter('AutoMusicPlayer'),
  );
  AutoMusicPlayer() {
    ready ??= _initialize();
  }
  static Future<void> _initialize() async {
    root = await MediaList.create(name: "root", icon: Icons.home);
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
}

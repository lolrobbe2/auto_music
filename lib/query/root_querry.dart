import 'package:auto_music/service_log_printer.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:logger/logger.dart';

class AudioQueryService {
  static bool _init = false;
  static final Logger _logger = Logger(
    printer: ServiceLogPrinter('AudioQueryService'),
  );
  static final OnAudioQuery audioQuery = OnAudioQuery();
  AudioQueryService() {
    ready = _initialize();
  }
  static Future<void>? ready;
  Future<void> _initialize() async {
    if (_init) {
      _logger.w('Already initialized. Skipping.');
      return;
    }
    _logger.i('Initializing...');

    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      final bool hasPermission = await audioQuery.checkAndRequest();

      if (hasPermission) {
        _init = true;
        _logger.i('Audio permissions granted.');
      } else {
        _logger.w('Audio permissions denied.');
      }
    } catch (error, stackTrace) {
      _logger.e('Initialization failed.', error: error, stackTrace: stackTrace);
    }
  }
}

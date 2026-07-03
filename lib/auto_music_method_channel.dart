import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'auto_music_platform_interface.dart';

/// An implementation of [AutoMusicPlatform] that uses method channels.
class MethodChannelAutoMusic extends AutoMusicPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('auto_music');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}

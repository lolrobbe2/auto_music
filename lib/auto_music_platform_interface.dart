import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'auto_music_method_channel.dart';

abstract class AutoMusicPlatform extends PlatformInterface {
  /// Constructs a AutoMusicPlatform.
  AutoMusicPlatform() : super(token: _token);

  static final Object _token = Object();

  static AutoMusicPlatform _instance = MethodChannelAutoMusic();

  /// The default instance of [AutoMusicPlatform] to use.
  ///
  /// Defaults to [MethodChannelAutoMusic].
  static AutoMusicPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AutoMusicPlatform] when
  /// they register themselves.
  static set instance(AutoMusicPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}


import 'auto_music_platform_interface.dart';

class AutoMusic {
  Future<String?> getPlatformVersion() {
    return AutoMusicPlatform.instance.getPlatformVersion();
  }
}

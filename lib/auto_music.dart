import 'package:audio_service/audio_service.dart';
import 'package:auto_music/player/auto_music_player.dart';
import 'package:auto_music/player/media_constants.dart';
import 'package:auto_music/query/root_querry.dart';

import 'auto_music_platform_interface.dart';

class AutoMusic {
  AutoMusic() {
    query; // Forces initialization
    player;
  }
  Future<String?> getPlatformVersion() {
    return AutoMusicPlatform.instance.getPlatformVersion();
  }

  static Future<void> init() async {
    await AutoMusicPlayer.ready;
    await AudioService.init(
      builder: () => player,
      config: AudioServiceConfig(
        androidNotificationChannelId: AutoMusicPlayer.notificationChannelId,
        androidNotificationChannelName: AutoMusicPlayer.notificationChannelName,
        androidNotificationOngoing: true,
        androidBrowsableRootExtras: {
          AndroidContentStyle.supportedKey: true,
          MediaConstants.EXTRAS_KEY_SEARCH_SUPPORTED: true,
        },
      ),
    );
  }

  static final AudioQueryService query = AudioQueryService();
  static final AutoMusicPlayer player = AutoMusicPlayer();
}

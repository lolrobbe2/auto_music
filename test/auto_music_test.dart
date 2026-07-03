import 'package:flutter_test/flutter_test.dart';
import 'package:auto_music/auto_music.dart';
import 'package:auto_music/auto_music_platform_interface.dart';
import 'package:auto_music/auto_music_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAutoMusicPlatform
    with MockPlatformInterfaceMixin
    implements AutoMusicPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AutoMusicPlatform initialPlatform = AutoMusicPlatform.instance;

  test('$MethodChannelAutoMusic is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAutoMusic>());
  });

  test('getPlatformVersion', () async {
    AutoMusic autoMusicPlugin = AutoMusic();
    MockAutoMusicPlatform fakePlatform = MockAutoMusicPlatform();
    AutoMusicPlatform.instance = fakePlatform;

    expect(await autoMusicPlugin.getPlatformVersion(), '42');
  });
}

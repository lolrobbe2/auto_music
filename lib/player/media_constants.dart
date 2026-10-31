// ignore_for_file: non_constant_identifier_names
import 'dart:ffi';

import 'package:audio_service/audio_service.dart';

class MediaConstants {
  ///Predefined custom action name to ask the connected service to download a specific MediaItem for offline playback.
  static final String CUSTOM_COMMAND_DOWNLOAD =
      "android.support.v4.media.action.DOWNLOAD";

  ///Bundle key used for the error code for expired authentication.
  static final int ERROR_CODE_AUTHENTICATION_EXPIRED_COMPAT = 3;
  static final String
  EXTRAS_KEY_APPLICATION_PREFERENCES_USING_CAR_APP_LIBRARY_INTENT =
      "androidx.media.BrowserRoot.Extras.APPLICATION_PREFERENCES_USING_CAR_APP_LIBRARY_INTENT";
  static final String EXTRAS_KEY_CONTENT_STYLE_SINGLE_ITEM =
      "android.media.browse.CONTENT_STYLE_SINGLE_ITEM_HINT";
  static final String EXTRAS_KEY_CONTENT_STYLE_BROWSABLE =
      "android.media.browse.CONTENT_STYLE_BROWSABLE_HINT";
  static final String EXTRAS_KEY_CONTENT_STYLE_GROUP_TITLE =
      "android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT";
  static final String EXTRAS_KEY_DOWNLOAD_PROGRESS =
      "android.media.browse.extra.DOWNLOAD_PROGRESS";
  static final String EXTRAS_KEY_DOWNLOAD_STATUS =
      "android.media.extra.DOWNLOAD_STATUS";


  static final String EXTRAS_KEY_SEARCH_SUPPORTED = "android.media.browse.SEARCH_SUPPORTED";
}

enum ItemStyle {
  //indicate a preference that certain instances of MediaItem should be presented as list items.
  list(1),
  //indicate a preference that certain instances of MediaItem should be presented as grid items.
  grid(2),
  //indicate a preference that browsable instances of MediaItem should be presented as "category" list items. This means the items provide icons that render well when they do not fill all of the available area.
  categoryList(3),
  //indicate a preference that browsable instances of MediaItem should be presented as "category" grid items. This means the items provide icons that render well when they do not fill all of the available area.
  categoryGrid(4);

  const ItemStyle(this.value);

  final int value;
}

enum DownloadStatus {
  notDownloaded(0),
  downloading(1),
  downloaded(2);

  const DownloadStatus(this.value);

  final int value;
}

extension MediaItemExtensions on MediaItem {
  void setConstantInt(String key, int value) {
    extras![key] = value;
  }

  void setConstantStr(String key, String value) {
    extras![key] = value;
  }

  void setConstantFloat(String key, Float value) {
    extras![key] = value;
  }

  MediaItem SetSingleItemStyle(ItemStyle style) {
    setConstantInt(
      MediaConstants.EXTRAS_KEY_CONTENT_STYLE_SINGLE_ITEM,
      style as int,
    );
    return this;
  }

  MediaItem SetBrowsableStyle(ItemStyle style) {
    setConstantInt(
      MediaConstants.EXTRAS_KEY_CONTENT_STYLE_BROWSABLE,
      style as int,
    );
    return this;
  }

  MediaItem SetGroupTitle(String title) {
    setConstantStr(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_GROUP_TITLE, title);
    return this;
  }

  MediaItem SetDownloadProgress(Float progress) {
    setConstantFloat(MediaConstants.EXTRAS_KEY_DOWNLOAD_PROGRESS, progress);
    return this;
  }

  MediaItem SetDownloadPercentage(int progress) {
    setConstantFloat(
      MediaConstants.EXTRAS_KEY_DOWNLOAD_PROGRESS,
      (progress / 100) as Float,
    );
    return this;
  }

  MediaItem SetDownloadStatus(DownloadStatus status) {
    setConstantInt(MediaConstants.EXTRAS_KEY_DOWNLOAD_STATUS, status as int);
    return this;
  }
}

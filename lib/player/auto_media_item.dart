import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';

class AutoMediaItem extends MediaItem {
  AutoMediaItem({
    required String id,
    required String title,
    String? artist,
    String? album,
    Uri? artUri,
    bool playable = true,
    Map<String, dynamic>? extras,
  }) : super(
          id: id,
          title: title,
          artist: artist,
          album: album,
          artUri: artUri,
          playable: playable,
          extras: extras,
        );

  static Future<AutoMediaItem> create({
    required String id,
    required String title,
    String? artist,
    String? album,
    Uri? artUri,
    IconData? icon,
    bool playable = true,
    Map<String, dynamic>? extras,
  }) async {
    Uri? resolvedArtUri = artUri;

    if (icon != null) {
      final Uint8List bytes = await _iconToBytes(icon);
      resolvedArtUri = _toDataUri(bytes);
    } else if (artUri != null &&
        (artUri.toString().startsWith('assets/') ||
            artUri.scheme == 'asset')) {
      final String assetPath = artUri.scheme == 'asset'
          ? artUri.path.replaceFirst(RegExp(r'^/'), '')
          : artUri.toString();

      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      resolvedArtUri = _toDataUri(bytes);
    }

    return AutoMediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      artUri: resolvedArtUri,
      playable: playable,
      extras: extras,
    );
  }

  static Future<Uint8List> _iconToBytes(IconData icon) async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    painter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 128,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    );

    painter.layout();
    painter.paint(canvas, Offset.zero);

    final ui.Image image = await recorder
        .endRecording()
        .toImage(128, 128);

    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (data == null) {
      throw StateError('Unable to generate icon artwork');
    }

    return data.buffer.asUint8List();
  }

  static Uri _toDataUri(Uint8List bytes) {
    return Uri.parse(
      'data:image/png;base64,${base64Encode(bytes)}',
    );
  }
}
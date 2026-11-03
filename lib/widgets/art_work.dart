import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:auto_music/query/art_query.dart';
import 'package:flutter/material.dart';

class Artwork extends StatefulWidget {
  final MediaItem? item;
  final double? size;
  final double borderRadius;

  const Artwork({required this.item, this.size, this.borderRadius = 24});

  @override
  State<Artwork> createState() => _ArtworkState();
}

class _ArtworkState extends State<Artwork> {
  Future<Uint8List?>? _artworkFuture;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant Artwork oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item?.id != widget.item?.id ||
        oldWidget.item?.artUri != widget.item?.artUri) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    final MediaItem? item = widget.item;

    _artworkFuture = item == null
        ? Future<Uint8List?>.value(null)
        : ArtQuery.FetchArtwork(item);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _artworkFuture,
      builder: (context, snapshot) {
        final Widget image;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          image = Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _placeholder(context);
            },
          );
        } else {
          image = _placeholder(context);
        }

        final Widget artwork = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: image,
        );

        if (widget.size != null) {
          return SizedBox.square(dimension: widget.size, child: artwork);
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AspectRatio(aspectRatio: 1, child: artwork),
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: widget.size == null ? 110 : 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

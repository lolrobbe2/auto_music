import 'package:auto_music/auto_music.dart';
import 'package:auto_music/player/media_list.dart';
import 'package:auto_music/widgets/art_work.dart';
import 'package:flutter/material.dart';


class MediaListWidget extends StatefulWidget {
  /// The starting folder/list.
  ///
  /// Can be a MediaList or any non-playable MediaItem
  /// whose children are available through AudioService.
  final MediaItem rootItem;

  const MediaListWidget({super.key, required this.rootItem});

  @override
  State<MediaListWidget> createState() => _MediaListWidgetState();
}

class _MediaListWidgetState extends State<MediaListWidget> {
  final List<_MediaListLevel> _navigationStack = [];

  bool _isLoading = true;
  String? _loadingItemId;

  _MediaListLevel? get _currentLevel {
    if (_navigationStack.isEmpty) return null;
    return _navigationStack.last;
  }

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  @override
  void didUpdateWidget(covariant MediaListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rootItem.id != widget.rootItem.id) {
      _navigationStack.clear();
      _loadRoot();
    }
  }

  /// Loads the children of a MediaItem.
  ///
  /// MediaList is handled directly. Other non-playable MediaItems
  /// use the registered AudioHandler's browse implementation.
  Future<List<MediaItem>> _getChildren(MediaItem item) async {
    if (item is MediaList) {
      return item.items.toList();
    }

    return AutoMusic.player.getChildren(item.id);
  }

  Future<void> _loadRoot() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<MediaItem> children = await _getChildren(widget.rootItem);

      if (!mounted) return;

      setState(() {
        _navigationStack
          ..clear()
          ..add(_MediaListLevel(parent: widget.rootItem, children: children));

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Unable to load media items.');
    }
  }

  /// Handles opening folders or playing media.
  Future<void> _onItemTap(MediaItem item) async {
    if (_loadingItemId != null) return;

    // Playable item: send it to your existing player.
    if (item.playable == true) {
      try {
        await AutoMusic.player.playMediaItem(item);
      } catch (error) {
        _showError('Unable to play ${item.title}.');
      }

      return;
    }

    // Non-playable item: load its children.
    setState(() {
      _loadingItemId = item.id;
    });

    try {
      final List<MediaItem> children = await _getChildren(item);

      if (!mounted) return;

      if (children.isEmpty) {
        _showError('This folder is empty.');
        return;
      }

      setState(() {
        _navigationStack.add(_MediaListLevel(parent: item, children: children));
      });
    } catch (error) {
      _showError('Unable to open ${item.title}.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingItemId = null;
        });
      }
    }
  }

  void _goBack() {
    if (_navigationStack.length <= 1) return;

    setState(() {
      _navigationStack.removeLast();
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _getTitle(MediaItem item) {
    final String? displayTitle = item.displayTitle;

    if (displayTitle != null && displayTitle.isNotEmpty) {
      return displayTitle;
    }

    return item.title;
  }

  String? _getSubtitle(MediaItem item) {
    return item.displaySubtitle ??
        item.artist ??
        item.album ??
        item.displayDescription;
  }

  @override
  Widget build(BuildContext context) {
    final _MediaListLevel? level = _currentLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header and navigation.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (_navigationStack.length > 1)
                IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level == null
                          ? _getTitle(widget.rootItem)
                          : _getTitle(level.parent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    if (level != null)
                      Text(
                        '${level.children.length} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : level == null || level.children.isEmpty
              ? const Center(child: Text('Nothing here yet'))
              : ListView.separated(
                  itemCount: level.children.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (context, index) {
                    return const Divider(height: 1, indent: 76);
                  },
                  itemBuilder: (context, index) {
                    final MediaItem item = level.children[index];

                    return _MediaListTile(
                      item: item,
                      loading: _loadingItemId == item.id,
                      title: _getTitle(item),
                      subtitle: _getSubtitle(item),
                      onTap: () => _onItemTap(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MediaListTile extends StatelessWidget {
  final MediaItem item;
  final String title;
  final String? subtitle;
  final bool loading;
  final VoidCallback onTap;

  const _MediaListTile({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool playable = item.playable == true;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Artwork(item: item, size: 52, borderRadius: 8),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null
          ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              playable
                  ? Icons.play_circle_outline_rounded
                  : Icons.chevron_right_rounded,
            ),
      onTap: loading ? null : onTap,
    );
  }
}

class _MediaListLevel {
  final MediaItem parent;
  final List<MediaItem> children;

  const _MediaListLevel({required this.parent, required this.children});
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MusicBrainzMatch {
  final String recordingId;
  final String title;
  final String artist;
  final String? album;
  final String? year;
  final String? genre;
  final String? releaseId;
  final int score;
  final int? durationMs;

  const MusicBrainzMatch({
    required this.recordingId,
    required this.title,
    required this.artist,
    required this.score,
    this.album,
    this.year,
    this.genre,
    this.releaseId,
    this.durationMs,
  });

  String? get artworkUrl {
    if (releaseId == null) return null;

    return 'https://coverartarchive.org/release/$releaseId/front-500';
  }

  factory MusicBrainzMatch.fromJson(
    Map<String, dynamic> json, {
    String? preferredAlbum,
  }) {
    final List<dynamic> credits = json['artist-credit'] as List<dynamic>? ?? [];

    final StringBuffer artistBuffer = StringBuffer();

    for (final dynamic credit in credits) {
      if (credit is! Map) continue;

      final dynamic artistData = credit['artist'];

      final String artistName =
          credit['name']?.toString() ??
          (artistData is Map ? artistData['name']?.toString() ?? '' : '');

      artistBuffer.write(artistName);
      artistBuffer.write(credit['joinphrase']?.toString() ?? '');
    }

    final List<Map<String, dynamic>> releases =
        (json['releases'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((release) => Map<String, dynamic>.from(release))
            .toList();

    Map<String, dynamic>? selectedRelease;

    // Prefer the local song's album when a matching release exists.
    if (preferredAlbum != null && preferredAlbum.isNotEmpty) {
      for (final Map<String, dynamic> release in releases) {
        if (release['title']?.toString().toLowerCase() ==
            preferredAlbum.toLowerCase()) {
          selectedRelease = release;
          break;
        }
      }
    }

    // Otherwise prefer an official album release.
    selectedRelease ??= releases.cast<Map<String, dynamic>?>().firstWhere((
      release,
    ) {
      if (release == null) return false;

      final Map<String, dynamic> group = release['release-group'] is Map
          ? Map<String, dynamic>.from(release['release-group'] as Map)
          : <String, dynamic>{};

      return group['primary-type'] == 'Album' &&
          release['status'] == 'Official';
    }, orElse: () => releases.isNotEmpty ? releases.first : null);

    final List<Map<String, dynamic>> tags =
        (json['tags'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((tag) => Map<String, dynamic>.from(tag))
            .toList();

    tags.sort((a, b) {
      final int countA = int.tryParse(a['count']?.toString() ?? '') ?? 0;
      final int countB = int.tryParse(b['count']?.toString() ?? '') ?? 0;

      return countB.compareTo(countA);
    });

    final String? date =
        selectedRelease?['date']?.toString() ??
        json['first-release-date']?.toString();

    return MusicBrainzMatch(
      recordingId: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: artistBuffer.toString().trim(),
      album: selectedRelease?['title']?.toString(),
      year: date != null && date.length >= 4 ? date.substring(0, 4) : null,
      genre: tags.isNotEmpty ? tags.first['name']?.toString() : null,
      releaseId: selectedRelease?['id']?.toString(),
      score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
      durationMs: int.tryParse(json['length']?.toString() ?? ''),
    );
  }
}

class MusicBrainzService {
  static final http.Client _client = http.Client();

  static const String _userAgent =
      'AutoMusic/1.0.0 (https://github.com/lolrobbe2/auto_music)';

  // MusicBrainz allows at most one request per second per application.
  static Future<void> _requestQueue = Future<void>.value();

  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<http.Response> _get(Uri uri) {
    final Completer<http.Response> completer = Completer<http.Response>();

    _requestQueue = _requestQueue.then((_) async {
      final Duration elapsed = DateTime.now().difference(_lastRequest);

      const Duration minimumInterval = Duration(seconds: 1);

      if (elapsed < minimumInterval) {
        await Future.delayed(minimumInterval - elapsed);
      }

      _lastRequest = DateTime.now();

      try {
        final http.Response response = await _client.get(
          uri,
          headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
        );

        completer.complete(response);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  static String _quote(String value) {
    final String escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"');

    return '"$escaped"';
  }

  static Future<List<MusicBrainzMatch>> search({
    required String title,
    String? artist,
    String? preferredAlbum,
  }) async {
    if (title.trim().isEmpty) {
      return [];
    }

    final List<String> terms = ['recording:${_quote(title.trim())}'];

    if (artist != null && artist.trim().isNotEmpty) {
      terms.add('artist:${_quote(artist.trim())}');
    }

    final Uri uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      'query': terms.join(' AND '),
      'fmt': 'json',
      'limit': '15',
    });

    final http.Response response = await _get(uri);

    if (response.statusCode != 200) {
      throw Exception('MusicBrainz returned HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic> recordings = data['recordings'] as List<dynamic>? ?? [];

    final List<MusicBrainzMatch> results = recordings
        .whereType<Map>()
        .map(
          (recording) => MusicBrainzMatch.fromJson(
            Map<String, dynamic>.from(recording),
            preferredAlbum: preferredAlbum,
          ),
        )
        .toList();

    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  static void dispose() {
    _client.close();
  }
}

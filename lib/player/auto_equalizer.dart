import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class _EqPoint {
  final double frequency;
  final double gain;

  const _EqPoint(this.frequency, this.gain);
}

class AutoEqualizer {
  final AndroidEqualizer equalizer;

  AutoEqualizer(this.equalizer);

  bool _automaticEnabled = true;
  int _applyVersion = 0;

  bool get automaticEnabled => _automaticEnabled;

  String _selectedProfile = 'rock';

  String get selectedProfile => _selectedProfile;

  List<String> get availableProfiles => _profiles.keys.toList();

  static const List<_EqPoint> _flat = [_EqPoint(20, 0), _EqPoint(20000, 0)];

  static const Map<String, List<_EqPoint>> _profiles = {
    'rock': [
      _EqPoint(20, 1),
      _EqPoint(60, 2),
      _EqPoint(250, 0.5),
      _EqPoint(1000, -1),
      _EqPoint(4000, 2),
      _EqPoint(10000, 2),
      _EqPoint(20000, 0),
    ],

    'pop': [
      _EqPoint(20, 0),
      _EqPoint(60, 2),
      _EqPoint(250, 1),
      _EqPoint(1000, -0.5),
      _EqPoint(4000, 1),
      _EqPoint(10000, 1.5),
      _EqPoint(20000, 0),
    ],

    'hip-hop': [
      _EqPoint(20, 1),
      _EqPoint(60, 3),
      _EqPoint(250, 1.5),
      _EqPoint(1000, -0.5),
      _EqPoint(4000, 0.5),
      _EqPoint(10000, 1),
      _EqPoint(20000, 0),
    ],

    'classical': [
      _EqPoint(20, 0),
      _EqPoint(60, 0.5),
      _EqPoint(250, 0),
      _EqPoint(1000, 0),
      _EqPoint(4000, 1),
      _EqPoint(10000, 1),
      _EqPoint(20000, 0),
    ],

    'jazz': [
      _EqPoint(20, 0),
      _EqPoint(60, 1),
      _EqPoint(250, 0.5),
      _EqPoint(1000, 1),
      _EqPoint(4000, 1.5),
      _EqPoint(10000, 1),
      _EqPoint(20000, 0),
    ],

    'podcast': [
      _EqPoint(20, -3),
      _EqPoint(60, -2),
      _EqPoint(250, 0),
      _EqPoint(1000, 1),
      _EqPoint(3000, 2),
      _EqPoint(6000, 1),
      _EqPoint(20000, 0),
    ],

    'metal': [
      _EqPoint(20, 1),
      _EqPoint(60, 2),
      _EqPoint(250, 0),
      _EqPoint(1000, -1),
      _EqPoint(4000, 2),
      _EqPoint(10000, 1.5),
      _EqPoint(20000, 0),
    ],
    'emo-pop': [
      _EqPoint(20, 0),
      _EqPoint(60, 1),
      _EqPoint(250, 1),
      _EqPoint(1000, 1.5),
      _EqPoint(4000, 1.5),
      _EqPoint(10000, 1),
      _EqPoint(20000, 0.5),
    ],
    'alternative-r&b': [
      _EqPoint(20, 0),
      _EqPoint(60, 1.5),
      _EqPoint(250, 0.5),
      _EqPoint(1000, 0.5),
      _EqPoint(4000, 1),
      _EqPoint(10000, 1.5),
      _EqPoint(20000, 0.5),
    ],
  };

  /// Enables or disables automatic genre-based EQ.
  Future<void> setAutomaticEnabled(
    bool enabled, {
    MediaItem? currentItem,
  }) async {
    _automaticEnabled = enabled;

    // Cancel any EQ operation currently in progress.
    _applyVersion++;

    if (enabled && currentItem != null) {
      await applyFor(currentItem);
    }
  }

  /// Automatically selects and applies the profile for a MediaItem.
  Future<void> applyFor(MediaItem item) async {
    if (!_automaticEnabled) return;

    final int version = ++_applyVersion;

    final List<_EqPoint> profile = _getProfile(item.genre);
    final AndroidEqualizerParameters parameters = await equalizer.parameters;

    for (final AndroidEqualizerBand band in parameters.bands) {
      if (version != _applyVersion) return;

      final double gain = _interpolate(band.centerFrequency, profile);

      final double clampedGain = gain
          .clamp(parameters.minDecibels, parameters.maxDecibels)
          .toDouble();

      await band.setGain(clampedGain);
    }
  }

  List<_EqPoint> _getProfile(String? genre) {
    if (genre == null || genre.isEmpty) {
      return _flat;
    }

    final String normalized = genre.toLowerCase();

    if (normalized.contains('emo pop') || normalized.contains('emo-pop')) {
      return _profiles['emo-pop']!;
    }

    if (normalized.contains('alternative') ||
        normalized.contains('alternative r&b') ||
        normalized.contains('alt r&b') ||
        normalized.contains('r&b') ||
        normalized.contains('rnb') ||
        normalized.contains('rhythm and blues')) {
      return _profiles['alternative-r&b']!;
    }

    if (normalized.contains('hip hop') ||
        normalized.contains('hip-hop') ||
        normalized.contains('rap')) {
      return _profiles['hip-hop']!;
    }

    if (normalized.contains('metal')) {
      return _profiles['metal']!;
    }

    if (normalized.contains('rock')) {
      return _profiles['rock']!;
    }

    if (normalized.contains('classical')) {
      return _profiles['classical']!;
    }

    if (normalized.contains('jazz')) {
      return _profiles['jazz']!;
    }

    if (normalized.contains('podcast') ||
        normalized.contains('speech') ||
        normalized.contains('spoken word')) {
      return _profiles['podcast']!;
    }

    if (normalized.contains('pop')) {
      return _profiles['pop']!;
    }

    return _flat;
  }

  double _interpolate(double frequency, List<_EqPoint> points) {
    if (frequency <= points.first.frequency) {
      return points.first.gain;
    }

    if (frequency >= points.last.frequency) {
      return points.last.gain;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final _EqPoint lower = points[i];
      final _EqPoint upper = points[i + 1];

      if (frequency >= lower.frequency && frequency <= upper.frequency) {
        final double x = math.log(frequency);
        final double x1 = math.log(lower.frequency);
        final double x2 = math.log(upper.frequency);

        final double t = (x - x1) / (x2 - x1);

        return lower.gain + (upper.gain - lower.gain) * t;
      }
    }

    return 0;
  }

  /// Manually selects and applies an equalizer profile.
  Future<void> setManualProfile(String profileName) async {
    if (_automaticEnabled) return;

    final List<_EqPoint>? profile = _profiles[profileName];

    if (profile == null) return;

    _selectedProfile = profileName;

    // Invalidate any pending automatic EQ operation.
    final int version = ++_applyVersion;

    final AndroidEqualizerParameters parameters = await equalizer.parameters;

    for (final AndroidEqualizerBand band in parameters.bands) {
      if (version != _applyVersion) return;

      final double gain = _interpolate(band.centerFrequency, profile);

      final double clampedGain = gain
          .clamp(parameters.minDecibels, parameters.maxDecibels)
          .toDouble();

      await band.setGain(clampedGain);
    }
  }
}

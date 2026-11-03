import 'package:auto_music/auto_music.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AndroidEqualizer equalizer = AutoMusic.player.equalizer;

    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: FutureBuilder<AndroidEqualizerParameters>(
        future: equalizer.parameters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Unable to load equalizer'));
          }

          final AndroidEqualizerParameters parameters = snapshot.data!;

          return Column(
            children: [
              StreamBuilder<bool>(
                stream: equalizer.enabledStream,
                initialData: equalizer.enabled,
                builder: (context, enabledSnapshot) {
                  return SwitchListTile(
                    title: const Text('Equalizer enabled'),
                    value: enabledSnapshot.data ?? false,
                    onChanged: equalizer.setEnabled,
                  );
                },
              ),

              const Divider(),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: parameters.bands.length,
                  itemBuilder: (context, index) {
                    final AndroidEqualizerBand band = parameters.bands[index];

                    return StreamBuilder<double>(
                      stream: band.gainStream,
                      initialData: band.gain,
                      builder: (context, gainSnapshot) {
                        final double gain = (gainSnapshot.data ?? band.gain)
                            .clamp(
                              parameters.minDecibels,
                              parameters.maxDecibels,
                            )
                            .toDouble();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${band.centerFrequency.round()} Hz',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text('${gain.toStringAsFixed(1)} dB'),
                              ],
                            ),
                            Slider(
                              min: parameters.minDecibels,
                              max: parameters.maxDecibels,
                              value: gain,
                              onChanged: (double value) {
                                band.setGain(value);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

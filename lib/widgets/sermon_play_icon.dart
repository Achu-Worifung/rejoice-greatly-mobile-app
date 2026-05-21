import 'package:flutter/material.dart';

import '../services/church_audio_player.dart';
import '../theme/church_colors.dart';

/// Play / pause / loading indicator for a sermon row; rebuilds on player state changes.
class SermonPlayIcon extends StatelessWidget {
  const SermonPlayIcon({
    super.key,
    required this.sermon,
    this.iconSize = 28,
    this.spinnerSize = 28,
  });

  final Map<String, dynamic> sermon;
  final double iconSize;
  final double spinnerSize;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChurchAudioPlayer.instance,
      builder: (context, _) {
        final audio = ChurchAudioPlayer.instance;
        if (audio.isLoadingFor(sermon)) {
          return SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: Padding(
              padding: EdgeInsets.all(spinnerSize * 0.14),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: ChurchColors.button,
              ),
            ),
          );
        }
        if (audio.isPlayingFor(sermon)) {
          return Icon(
            Icons.pause,
            color: ChurchColors.button,
            size: iconSize,
          );
        }
        return Icon(
          Icons.play_arrow,
          color: ChurchColors.button,
          size: iconSize,
        );
      },
    );
  }
}

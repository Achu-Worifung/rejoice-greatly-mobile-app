import 'package:flutter/material.dart';

import '../services/church_audio_player.dart';
import '../services/sermon_downloads.dart';
import '../services/sermon_progress.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';

/// "1:02:15" or "23:14".
String formatListenTime(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// "1.25×", "2×".
String speedLabel(double speed) =>
    '${speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : speed.toString()}×';

/// The seek bar, skip buttons and speed for the sermon that's playing.
/// Shows nothing while a different sermon (or none) is loaded.
class SermonListenControls extends StatelessWidget {
  const SermonListenControls({super.key, required this.sermonKey});

  final String sermonKey;

  @override
  Widget build(BuildContext context) {
    final player = ChurchAudioPlayer.instance;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        if (player.activeSermon == null ||
            ChurchAudioPlayer.sermonKey(player.activeSermon!) != sermonKey) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, snap) {
            final duration = player.duration ?? Duration.zero;
            final position = snap.data ?? player.position;
            final max = duration.inMilliseconds.toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: ChurchColors.accent,
                    inactiveTrackColor: ChurchColors.divider,
                    thumbColor: ChurchColors.accent,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: max <= 0 ? 0 : position.inMilliseconds.clamp(0, max.toInt()).toDouble(),
                    max: max <= 0 ? 1 : max,
                    onChanged: max <= 0 ? null : (v) => player.seek(Duration(milliseconds: v.round())),
                    semanticFormatterCallback: (v) => formatListenTime(Duration(milliseconds: v.round())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(formatListenTime(position), style: ChurchType.dataSmall),
                      const Spacer(),
                      Text(
                        duration > position ? '−${formatListenTime(duration - position)}' : '',
                        style: ChurchType.dataSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Back 10 seconds',
                      iconSize: 30,
                      color: ChurchColors.accent,
                      onPressed: () => player.skip(const Duration(seconds: -10)),
                      icon: const Icon(Icons.replay_10_rounded),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Forward 30 seconds',
                      iconSize: 30,
                      color: ChurchColors.accent,
                      onPressed: () => player.skip(const Duration(seconds: 30)),
                      icon: const Icon(Icons.forward_30_rounded),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<double>(
                      tooltip: 'Playback speed',
                      initialValue: player.speed,
                      onSelected: player.setSpeed,
                      itemBuilder: (_) => [
                        for (final s in ChurchAudioPlayer.speeds)
                          PopupMenuItem(value: s, child: Text(speedLabel(s))),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: ChurchRadius.mdAll,
                          border: Border.all(color: ChurchColors.divider),
                        ),
                        child: Text(speedLabel(player.speed), style: ChurchType.data),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// "Resume from 23:14 · 18 min left", under the play button, for a sermon
/// they started before and aren't playing now.
class SermonResumeNote extends StatelessWidget {
  const SermonResumeNote({super.key, required this.sermonKey});

  final String sermonKey;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SermonProgress.all, ChurchAudioPlayer.instance]),
      builder: (context, _) {
        final active = ChurchAudioPlayer.instance.activeSermon;
        if (active != null && ChurchAudioPlayer.sermonKey(active) == sermonKey) return const SizedBox.shrink();
        final at = SermonProgress.resumeAt(sermonKey);
        final listen = SermonProgress.all.value[sermonKey];
        if (at == null || listen == null) return const SizedBox.shrink();
        final left = listen.remaining.inMinutes;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Picks up at ${formatListenTime(at)}${left > 0 ? ' · $left min left' : ''}',
            style: ChurchType.label,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// Download for listening offline, how it's going, or remove it again.
class SermonDownloadButton extends StatelessWidget {
  const SermonDownloadButton({super.key, required this.sermonKey, required this.sermon});

  final String sermonKey;
  final Map<String, dynamic> sermon;

  Future<void> _download(BuildContext context) async {
    final url = (sermon['audioUrl'] as String?)?.trim();
    if (url == null || url.isEmpty) return;
    try {
      await SermonDownloads.download(sermonKey, sermon, url);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Downloaded. You can listen without a connection.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SermonDownloads.all, SermonDownloads.inFlight]),
      builder: (context, _) {
        final done = SermonDownloads.all.value[sermonKey];
        final progress = SermonDownloads.inFlight.value[sermonKey];
        if (progress != null) {
          return Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress > 0 ? progress : null,
                  color: ChurchColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                progress > 0 ? 'Downloading ${(progress * 100).round()}%' : 'Downloading…',
                style: ChurchType.label,
              ),
            ],
          );
        }
        if (done != null) {
          return Row(
            children: [
              Icon(Icons.download_done_rounded, color: ChurchColors.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Downloaded · ${SermonDownloads.sizeLabel(done.bytes)}', style: ChurchType.label),
              ),
              TextButton(
                onPressed: () => SermonDownloads.remove(sermonKey),
                child: const Text('Remove'),
              ),
            ],
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download for offline'),
          ),
        );
      },
    );
  }
}

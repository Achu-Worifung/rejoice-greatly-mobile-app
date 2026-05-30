import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/church_api.dart';
import '../services/church_audio_player.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/sermon_playing_waveform.dart';

/// Full-screen sermon (no bottom nav shell); opened via [Navigator.push].
class SermonDetailPage extends StatefulWidget {
  const SermonDetailPage({super.key, required this.initial});

  final Map<String, dynamic> initial;

  @override
  State<SermonDetailPage> createState() => _SermonDetailPageState();
}

class _SermonDetailPageState extends State<SermonDetailPage> {
  Map<String, dynamic>? _fetched;
  late bool _loading = widget.initial['id'] != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.initial['id'];
    if (id == null) {
      return;
    }
    try {
      final m = await ChurchApi.getSermonById(id);
      if (mounted) {
        setState(() {
          _fetched = m;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> get _merged {
    if (_fetched == null) return Map<String, dynamic>.from(widget.initial);
    return {...widget.initial, ..._fetched!};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: ChurchColors.background,
        appBar: ChurchAppBar.pageTitle(
          'Sermon',
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ChurchColors.button),
        ),
      );
    }
    final m = _merged;
    final imageUrl = m['imageUrl'] as String?;
    final audio = m['audioUrl'] as String?;
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle(
        'Sermon',
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: ChurchColors.card,
                  child: const Center(
                    child: Icon(Icons.mic, size: 64, color: ChurchColors.muted),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              color: ChurchColors.card,
              child: const Center(
                child: Icon(Icons.mic, size: 64, color: ChurchColors.muted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['title'] as String? ?? 'Sermon',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.bodyText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _metaLine(m),
                  style: const TextStyle(
                    color: ChurchColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if ((m['category'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ChurchColors.button.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (m['category'] as String).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ChurchColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                if (audio != null && audio.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: ChurchAudioPlayer.instance,
                    builder: (context, _) {
                      final player = ChurchAudioPlayer.instance;
                      final loading = player.isLoadingFor(m);
                      final playing = player.isPlayingFor(m);
                      final paused = player.isPausedFor(m);

                      Widget leadingIcon() {
                        if (loading) {
                          return const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ChurchColors.buttonText,
                            ),
                          );
                        }
                        if (playing) {
                          return const SizedBox(
                            width: 40,
                            height: 28,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SermonPlayingWaveform(
                                size: 22,
                                barCount: 3,
                                isPlaying: true,
                                foregroundColor: ChurchColors.buttonText,
                              ),
                            ),
                          );
                        }
                        if (paused) {
                          return const Icon(
                            Icons.pause_rounded,
                            size: 28,
                            color: ChurchColors.buttonText,
                          );
                        }
                        return const Icon(
                          Icons.play_arrow_rounded,
                          size: 28,
                          color: ChurchColors.buttonText,
                        );
                      }

                      final label = loading
                          ? 'Loading audio…'
                          : playing
                              ? 'Pause'
                              : paused
                                  ? 'Resume'
                                  : 'Listen to sermon';

                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loading
                              ? null
                              : () async {
                                  final ok = await player.toggle(m);
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not play this sermon audio.'),
                                      ),
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: ChurchColors.button,
                            foregroundColor: ChurchColors.buttonText,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: leadingIcon(),
                          label: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if ((m['description'] as String?)?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m['description'] as String,
                    style: const TextStyle(
                      color: ChurchColors.bodyText,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                ],
                if (m['duration'] != null && '${m['duration']}'.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.timelapse, size: 18, color: ChurchColors.muted),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ${m['duration']}',
                        style: const TextStyle(color: ChurchColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _metaLine(Map<String, dynamic> m) {
    final parts = <String>[
      if ((m['speaker'] as String?)?.isNotEmpty == true) m['speaker'] as String,
      if (m['datePreached'] != null) _dateStr(m['datePreached'] as String?),
    ];
    return parts.where((e) => e.isNotEmpty).join(' · ');
  }

  String _dateStr(String? s) {
    if (s == null || s.isEmpty) return '';
    if (s.length < 10) return s;
    try {
      return DateFormat.yMMMEd().format(DateTime.parse(s.substring(0, 10)));
    } catch (_) {
      return s;
    }
  }

}

/// Opens [SermonDetailPage] on the root stack (covers bottom nav on phone).
void openSermonDetailPage(BuildContext context, Map<String, dynamic> initial) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => SermonDetailPage(initial: Map<String, dynamic>.from(initial)),
    ),
  );
}

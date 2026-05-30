import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/church_api.dart';
import '../services/church_audio_player.dart';
import '../theme/church_colors.dart';
import '../widgets/detail_page_hero.dart';
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
    final m = _merged;
    final imageUrl = m['imageUrl'] as String?;
    final title = m['title'] as String? ?? 'Sermon';
    final category = (m['category'] as String?)?.trim();
    final speaker = (m['speaker'] as String?)?.trim() ?? '';
    final description = (m['description'] as String?)?.trim() ?? '';
    final audio = m['audioUrl'] as String?;
    final dateLine = _dateStr(m['datePreached'] as String?);
    final duration = m['duration'] != null ? '${m['duration']}'.trim() : '';

    return Scaffold(
      backgroundColor: ChurchColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DetailPageHeroHeader(
              imageUrl: imageUrl,
              placeholderIcon: Icons.mic,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.bodyText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                DetailCategoryChip(
                  label: category?.isNotEmpty == true ? category! : 'Sermon',
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: ChurchColors.button),
                    ),
                  )
                else ...[
                  if (speaker.isNotEmpty)
                    DetailInfoRow(icon: Icons.person_outline, text: speaker),
                  if (dateLine.isNotEmpty)
                    DetailInfoRow(icon: Icons.event_rounded, text: dateLine),
                  if (audio != null && audio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _AudioPlayButton(sermon: m),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: ChurchColors.accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: ChurchColors.bodyText,
                      ),
                    ),
                  ],
                  if (duration.isNotEmpty)
                    DetailInfoRow(icon: Icons.timelapse, text: 'Duration: $duration'),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _dateStr(String? s) {
    if (s == null || s.isEmpty) return '';
    if (s.length < 10) return s;
    try {
      return DateFormat.yMMMMEEEEd().format(DateTime.parse(s.substring(0, 10)));
    } catch (_) {
      return s;
    }
  }
}

class _AudioPlayButton extends StatelessWidget {
  const _AudioPlayButton({required this.sermon});

  final Map<String, dynamic> sermon;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChurchAudioPlayer.instance,
      builder: (context, _) {
        final player = ChurchAudioPlayer.instance;
        final loading = player.isLoadingFor(sermon);
        final playing = player.isPlayingFor(sermon);
        final paused = player.isPausedFor(sermon);

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
                    final ok = await player.toggle(sermon);
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
    );
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

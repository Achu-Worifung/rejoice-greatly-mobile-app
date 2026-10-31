import 'package:flutter/material.dart';

import '../pages/leader_bacenta_page.dart';
import '../services/leader_api.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'dashboard_label_title.dart';

/// On Home, for leaders only: the bacenta they lead, and what needs them —
/// tonight's attendance, or people to check in with. Shows nothing to everyone else.
class LeaderCard extends StatefulWidget {
  const LeaderCard({super.key});

  @override
  State<LeaderCard> createState() => _LeaderCardState();
}

class _LeaderCardState extends State<LeaderCard> {
  List<LedBacenta> _led = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final led = await LeaderApi.led();
      if (mounted) setState(() => _led = led);
    } catch (_) {
      // Not being able to load it shouldn't get in the way of Home.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_led.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardLabelText(label: 'You lead'),
          for (final b in _led)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: ChurchColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: ChurchRadius.lgAll,
                  side: BorderSide(color: ChurchColors.divider),
                ),
                child: InkWell(
                  borderRadius: ChurchRadius.lgAll,
                  onTap: () async {
                    await openLeaderBacenta(context, b);
                    _load();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.groups_2_outlined, color: ChurchColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: ChurchType.title),
                              Text(
                                [
                                  if (b.meetsToday) 'Meeting tonight · take attendance'
                                  else if (b.meetingDay != null) '${b.meetingDay}s${b.meetingTime != null ? ' · ${b.meetingTime}' : ''}',
                                  if (b.toFollowUp > 0) '${b.toFollowUp} to check in with',
                                ].join(' · '),
                                style: ChurchType.label,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: ChurchColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

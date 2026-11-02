import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/checkin_location.dart';
import '../services/rides_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_buttons.dart';
import '../widgets/event_actions.dart';

/// "Rides to church": ask for a ride on a coming Sunday, see who's picking
/// you up, and — for drivers the transport team approved — who you're
/// picking up.
class RidesPage extends StatefulWidget {
  const RidesPage({super.key, this.load, this.loadDriving, this.cancel});

  /// Stand-ins for the API, for tests.
  final Future<RidesOverview> Function()? load;
  final Future<Driving> Function()? loadDriving;
  final Future<void> Function(String id)? cancel;

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  RidesOverview? _rides;
  Driving _driving = Driving.none;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rides = await (widget.load ?? RidesApi.mine)();
      if (mounted) setState(() => _rides = rides);
    } catch (e) {
      debugPrint('RidesPage: $e');
      if (mounted) setState(() => _error = userFacingError(e));
    }
    try {
      final driving = await (widget.loadDriving ?? RidesApi.driving)();
      if (mounted) setState(() => _driving = driving);
    } catch (e) {
      // Not knowing whether they drive only hides that section.
      debugPrint('RidesPage driving: $e');
    }
  }

  Future<void> _ask() async {
    final rides = _rides;
    if (rides == null) return;
    final asked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RideRequestPage(sundays: rides.openSundays)),
    );
    if (asked == true) _load();
  }

  Future<void> _cancel(MyRide ride) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: Text(ride.arranged
            ? 'We’ll let ${ride.driver!.name.split(' ').first} know they don’t need to come.'
            : 'The transport team will stop looking for a driver.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel ride')),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await (widget.cancel ?? RidesApi.cancel)(ride.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride cancelled.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn’t cancel that. ${userFacingError(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rides = _rides;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text('Rides to church', style: ChurchType.headline)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            Text(
              'Need a ride on Sunday? Ask here and the transport team will find someone from church who lives near you.',
              style: ChurchType.body,
            ),
            const SizedBox(height: 24),
            if (rides == null && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rides == null)
              Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center, style: ChurchType.body),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ],
              )
            else ...[
              for (final ride in rides.rides) ...[
                _RideCard(ride: ride, now: now, onCancel: () => _cancel(ride)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              ChurchPrimaryButton(
                label: rides.rides.isEmpty ? 'Ask for a ride' : 'Ask for another Sunday',
                icon: Icons.directions_car_outlined,
                onPressed: rides.openSundays.isEmpty ? null : _ask,
              ),
              const SizedBox(height: 10),
              Text(
                'Only the transport coordinator and your driver see your address, and it’s deleted the day after.',
                style: ChurchType.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (_driving.approved) ...[
              const SizedBox(height: 32),
              ChurchEyebrow('Driving'),
              const SizedBox(height: 8),
              _DrivingTeaser(
                driving: _driving,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const DrivingPage()),
                  );
                  _load();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, required this.now, required this.onCancel});

  final MyRide ride;
  final DateTime now;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChurchEyebrow(rideDayLabel(ride.date, now), color: ChurchColors.accent),
          const SizedBox(height: 4),
          Text(
            '${ride.label} · ${ride.seats} ${ride.seats == 1 ? 'seat' : 'seats'}',
            style: ChurchType.label,
          ),
          const SizedBox(height: 12),
          if (ride.arranged) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: ChurchColors.successInk, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${driver!.name} is picking you up', style: ChurchType.bodyStrong),
                      if ((driver.car ?? '').isNotEmpty) Text(driver.car!, style: ChurchType.label),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, color: ChurchColors.muted, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finding you a driver', style: ChurchType.bodyStrong),
                      Text('We’ll let you know as soon as someone’s arranged.', style: ChurchType.label),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              if (ride.arranged && (driver!.phone ?? '').isNotEmpty)
                TextButton.icon(
                  onPressed: () => openExternal(context, Uri(scheme: 'tel', path: driver.phone)),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text('Call ${driver.name.split(' ').first}'),
                ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: ChurchColors.muted),
                child: const Text('I don’t need it anymore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrivingTeaser extends StatelessWidget {
  const _DrivingTeaser({required this.driving, required this.onTap});

  final Driving driving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = driving.riders.length;
    final subtitle = !driving.ready
        ? 'Add where you start from and your phone, so the team can match you.'
        : n == 0
            ? 'No one to pick up yet. Choose the Sundays you can drive.'
            : 'You’re picking up $n ${n == 1 ? 'person' : 'people'}.';
    return Material(
      color: ChurchColors.card,
      shape: RoundedRectangleBorder(borderRadius: ChurchRadius.lgAll, side: BorderSide(color: ChurchColors.divider)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(Icons.volunteer_activism_outlined, color: ChurchColors.accent),
        title: Text('You’re on the driving team', style: ChurchType.title.copyWith(fontSize: 16)),
        subtitle: Text(subtitle, style: ChurchType.label),
        trailing: Icon(Icons.chevron_right_rounded, color: ChurchColors.muted),
      ),
    );
  }
}

/// Where to pick someone up: an address the driver reads, a phone they can
/// call, and optionally the exact spot from the phone's location. The last
/// address and phone are remembered on this phone only.
class _PlaceFields extends StatefulWidget {
  const _PlaceFields({
    required this.address,
    required this.phone,
    required this.pinned,
    required this.onPinned,
    required this.addressLabel,
    required this.addressHelp,
    required this.phoneHelp,
  });

  final TextEditingController address;
  final TextEditingController phone;
  final ({double lat, double lng})? pinned;
  final ValueChanged<({double lat, double lng})?> onPinned;
  final String addressLabel;
  final String addressHelp;
  final String phoneHelp;

  @override
  State<_PlaceFields> createState() => _PlaceFieldsState();
}

class _PlaceFieldsState extends State<_PlaceFields> {
  bool _locating = false;

  Future<void> _pin() async {
    const location = CheckinLocation();
    setState(() => _locating = true);
    var access = await location.access();
    if (access == LocationAccess.canAsk) access = await location.request();
    final here = access == LocationAccess.granted ? await location.current() : null;
    if (!mounted) return;
    setState(() => _locating = false);
    if (here == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(access == LocationAccess.granted
            ? 'Couldn’t find where you are. The address is enough.'
            : 'Location is off for this app. The address is enough.'),
      ));
      return;
    }
    widget.onPinned((lat: here.latitude, lng: here.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.address,
          textCapitalization: TextCapitalization.words,
          maxLength: 300,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: widget.addressLabel,
            helperText: widget.addressHelp,
            helperMaxLines: 2,
            counterText: '',
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: widget.pinned != null
              ? TextButton.icon(
                  onPressed: () => widget.onPinned(null),
                  icon: Icon(Icons.where_to_vote_outlined, size: 18, color: ChurchColors.successInk),
                  label: const Text('Pinned to where you are now · Undo'),
                )
              : TextButton.icon(
                  onPressed: _locating ? null : _pin,
                  icon: _locating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('I’m here now: pin this spot'),
                ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.phone,
          keyboardType: TextInputType.phone,
          maxLength: 40,
          decoration: InputDecoration(labelText: 'Phone', helperText: widget.phoneHelp, counterText: ''),
        ),
      ],
    );
  }
}

class _SeatStepper extends StatelessWidget {
  const _SeatStepper({required this.value, required this.onChanged, required this.label, required this.help});

  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final String help;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ChurchType.bodyStrong),
              Text(help, style: ChurchType.label),
            ],
          ),
        ),
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          tooltip: 'Fewer',
        ),
        SizedBox(
          width: 28,
          child: Text('$value', textAlign: TextAlign.center, style: ChurchType.data, semanticsLabel: '$value seats'),
        ),
        IconButton(
          onPressed: value < 8 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'More',
        ),
      ],
    );
  }
}

/// "This Sunday", "Tomorrow", else "Nov 8".
String _chipLabel(DateTime day, DateTime now) {
  final label = rideDayLabel(day, now);
  return label.contains(',') ? DateFormat('MMM d').format(day) : label;
}

const _lastAddressKey = 'rides.lastAddress';
const _lastPhoneKey = 'rides.lastPhone';

/// Asking for a ride: which Sunday, how many, and where from.
class RideRequestPage extends StatefulWidget {
  const RideRequestPage({super.key, required this.sundays, this.submit});

  final List<DateTime> sundays;

  /// Stand-in for the API, for tests.
  final Future<void> Function(DateTime date, int seats, RidePlace pickup, String? note)? submit;

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> {
  late DateTime? _date = widget.sundays.isEmpty ? null : widget.sundays.first;
  int _seats = 1;
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  ({double lat, double lng})? _pinned;
  bool _sending = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _remembered();
  }

  Future<void> _remembered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (_address.text.isEmpty) _address.text = prefs.getString(_lastAddressKey) ?? '';
      if (_phone.text.isEmpty) _phone.text = prefs.getString(_lastPhoneKey) ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final date = _date;
    final problem = date == null
        ? 'Choose a Sunday.'
        : _address.text.trim().isEmpty
            ? 'Add the address to pick you up from.'
            : _phone.text.trim().length < 7
                ? 'Add a phone number your driver can call.'
                : null;
    setState(() => _problem = problem);
    if (problem != null) return;
    setState(() => _sending = true);
    final pickup = RidePlace(address: _address.text, phone: _phone.text, lat: _pinned?.lat, lng: _pinned?.lng);
    try {
      await (widget.submit ??
          (d, s, p, n) => RidesApi.request(date: d, seats: s, pickup: p, note: n))(date!, _seats, pickup, _note.text);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastAddressKey, pickup.address.trim());
        await prefs.setString(_lastPhoneKey, pickup.phone.trim());
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! We’ll let you know once a driver is arranged.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _problem = userFacingError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text('Ask for a ride', style: ChurchType.headline)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          ChurchEyebrow('Which Sunday'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in widget.sundays)
                ChoiceChip(
                  label: Text(_chipLabel(d, now)),
                  selected: _date != null && DateUtils.isSameDay(_date, d),
                  onSelected: (_) => setState(() => _date = d),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SeatStepper(
            value: _seats,
            onChanged: (v) => setState(() => _seats = v),
            label: 'Seats',
            help: 'Including you.',
          ),
          const SizedBox(height: 20),
          _PlaceFields(
            address: _address,
            phone: _phone,
            pinned: _pinned,
            onPinned: (p) => setState(() => _pinned = p),
            addressLabel: 'Pickup address',
            addressHelp: 'Street and number, so your driver can find you.',
            phoneHelp: 'So your driver can call when they’re close.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Anything your driver should know? (optional)',
              hintText: 'A walker, a car seat, which door…',
              alignLabelWithHint: true,
            ),
          ),
          if (_problem != null) ...[
            const SizedBox(height: 8),
            Text(_problem!, style: ChurchType.label.copyWith(color: ChurchColors.errorInk)),
          ],
          const SizedBox(height: 16),
          ChurchPrimaryButton(label: 'Ask for a ride', loading: _sending, onPressed: _send),
          const SizedBox(height: 10),
          Text(
            'Only the transport coordinator and your driver see your address and phone. They’re deleted the day after the ride.',
            style: ChurchType.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A driver's page: who they're picking up, the Sundays they can drive, and
/// their car and start point.
class DrivingPage extends StatefulWidget {
  const DrivingPage({super.key, this.load, this.setAvailable, this.save});

  /// Stand-ins for the API, for tests.
  final Future<Driving> Function()? load;
  final Future<Driving> Function(DateTime date, bool available)? setAvailable;
  final Future<Driving> Function(int seats, String? car, RidePlace start)? save;

  @override
  State<DrivingPage> createState() => _DrivingPageState();
}

class _DrivingPageState extends State<DrivingPage> {
  Driving? _driving;
  String? _error;
  int _seats = 3;
  final _car = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  ({double lat, double lng})? _pinned;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _car.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _show(Driving d, {bool fields = false}) {
    setState(() => _driving = d);
    if (!fields) return;
    _seats = d.seats;
    _car.text = d.car ?? '';
    _address.text = d.address ?? '';
    _phone.text = d.phone ?? '';
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await (widget.load ?? RidesApi.driving)();
      if (mounted) _show(d, fields: true);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  Future<void> _toggle(DateTime day, bool available) async {
    try {
      final d = await (widget.setAvailable ?? RidesApi.setAvailable)(day, available);
      if (mounted) _show(d);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn’t save that. ${userFacingError(e)}')));
    }
  }

  Future<void> _save() async {
    if (_address.text.trim().isEmpty || _phone.text.trim().length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add where you start from and a phone number.')),
      );
      return;
    }
    setState(() => _saving = true);
    final start = RidePlace(address: _address.text, phone: _phone.text, lat: _pinned?.lat, lng: _pinned?.lng);
    try {
      final d = await (widget.save ??
          (s, c, p) => RidesApi.updateDriving(seats: s, car: c, start: p))(_seats, _car.text, start);
      if (!mounted) return;
      _show(d);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(d.located
            ? 'Saved. Thank you!'
            : 'Saved, but we couldn’t find that address on the map. Try adding the city, or pin your spot.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn’t save. ${userFacingError(e)}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _driving;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text('Driving', style: ChurchType.headline)),
      body: d == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: ChurchType.body, textAlign: TextAlign.center),
                        TextButton(onPressed: _load, child: const Text('Try again')),
                      ],
                    ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  Text(
                    'Thank you for driving. The transport coordinator matches you with people near your way to church.',
                    style: ChurchType.body,
                  ),
                  const SizedBox(height: 24),
                  ChurchEyebrow('Picking up'),
                  const SizedBox(height: 8),
                  if (d.riders.isEmpty)
                    Text('No one yet. You’ll get a notification when someone is matched with you.', style: ChurchType.label)
                  else
                    for (final r in d.riders) ...[
                      _RiderCard(rider: r, now: now),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 24),
                  ChurchEyebrow('Sundays I can drive'),
                  const SizedBox(height: 8),
                  Material(
                    color: ChurchColors.card,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: ChurchRadius.lgAll,
                      side: BorderSide(color: ChurchColors.divider),
                    ),
                    child: Column(
                      children: [
                        for (final (i, day) in d.sundays.indexed) ...[
                          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: ChurchColors.divider),
                          SwitchListTile(
                            value: d.canDriveOn(day),
                            onChanged: (v) => _toggle(day, v),
                            activeThumbColor: ChurchColors.buttonText,
                            activeTrackColor: ChurchColors.button,
                            inactiveThumbColor: ChurchColors.muted,
                            inactiveTrackColor: ChurchColors.background,
                            trackOutlineColor: WidgetStatePropertyAll(ChurchColors.muted.withValues(alpha: 0.6)),
                            title: Text(rideDayLabel(day, now), style: ChurchType.body),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ChurchEyebrow('Your car'),
                  const SizedBox(height: 12),
                  _PlaceFields(
                    address: _address,
                    phone: _phone,
                    pinned: _pinned,
                    onPinned: (p) => setState(() => _pinned = p),
                    addressLabel: 'Where you usually start from',
                    addressHelp: d.located || _address.text.isEmpty
                        ? 'Your street is enough. Only the coordinator sees it, to match you with people on your way.'
                        : 'We couldn’t find this on the map. Try adding the city, or pin your spot.',
                    phoneHelp: 'Given to the people you pick up.',
                  ),
                  const SizedBox(height: 16),
                  _SeatStepper(
                    value: _seats,
                    onChanged: (v) => setState(() => _seats = v),
                    label: 'Seats free',
                    help: 'Not counting you.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _car,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your car (optional)',
                      hintText: 'e.g. Silver Honda Odyssey',
                      helperText: 'So riders know which car to look for.',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ChurchPrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.rider, required this.now});

  final RideRider rider;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final directions = rider.directions;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChurchEyebrow(rideDayLabel(rider.date, now), color: ChurchColors.accent),
          const SizedBox(height: 4),
          Text(
            '${rider.name} · ${rider.seats} ${rider.seats == 1 ? 'seat' : 'seats'}',
            style: ChurchType.bodyStrong,
          ),
          if ((rider.address ?? '').isNotEmpty) Text(rider.address!, style: ChurchType.label),
          if ((rider.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('“${rider.note}”', style: ChurchType.body),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              if (directions != null)
                TextButton.icon(
                  onPressed: () => openExternal(context, directions),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Directions'),
                ),
              if ((rider.phone ?? '').isNotEmpty)
                TextButton.icon(
                  onPressed: () => openExternal(context, Uri(scheme: 'tel', path: rider.phone)),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text('Call ${rider.name.split(' ').first}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

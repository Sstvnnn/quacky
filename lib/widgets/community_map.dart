import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../screens/sar/emergency_call_screen.dart';
import '../state/incident_controller.dart';

typedef _Neighbor = Quaker;

class CommunityMap extends StatefulWidget {
  final bool sosMode;
  final bool sarMode;
  const CommunityMap({
    super.key,
    this.sosMode = false,
    this.sarMode = false,
  });

  @override
  State<CommunityMap> createState() => _CommunityMapState();
}

class _CommunityMapState extends State<CommunityMap> {
  static const _center = LatLng(-6.2146, 106.8451);

  late final List<_Neighbor> _neighbors;
  final List<Timer> _timers = [];
  _Neighbor? _alertFor;
  _Neighbor? _responder;
  _Neighbor? _helpTarget;

  static const _dangerFrames = [
    'assets/images/Danger_Pic1.jpg',
    'assets/images/Danger_Pic2.jpg',
    'assets/images/Danger_Pic3.jpg',
    'assets/images/Danger_Pic4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.sarMode) {
      _neighbors = context.read<IncidentController>().people;
      return;
    }

    _neighbors = buildRoster();

    if (widget.sosMode) {
      for (final (i, n) in _neighbors.indexed) {
        _timers.add(Timer(Duration(milliseconds: 1200 + i * 700), () {
          if (mounted) setState(() => n.notified = true);
        }));
      }
      _timers.add(Timer(const Duration(seconds: 6), () {
        if (!mounted) return;
        setState(() {
          _neighbors[0].status = NeighborStatus.responding;
          _responder = _neighbors[0];
        });
      }));
    } else {
      _timers.add(Timer(const Duration(seconds: 6), () {
        if (!mounted) return;
        setState(() {
          _neighbors[3].status = NeighborStatus.sos;
          _alertFor = _neighbors[3];
        });
      }));
      _timers.add(Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        setState(() {
          _neighbors[4].status = NeighborStatus.sos;
          _alertFor ??= _neighbors[4];
        });
      }));
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  LatLng get _origin => widget.sarMode ? sarBasePoint : _center;

  String _distanceTo(LatLng p) {
    final m = const Distance()(_origin, p);
    return m < 950 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  _Neighbor? get _nearestSos {
    _Neighbor? best;
    double bestD = double.infinity;
    const dist = Distance();
    for (final n in _neighbors) {
      if (n.status != NeighborStatus.sos) continue;
      final d = dist(_origin, n.point);
      if (d < bestD) {
        bestD = d;
        best = n;
      }
    }
    return best;
  }

  void _openRescueSheet(_Neighbor n) {
    setState(() => _alertFor = null);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RescueSheet(
        neighbor: n,
        frames: _dangerFrames,
        sarMode: widget.sarMode,
        distanceLabel: _distanceTo(n.point),
        alreadyHelping: _helpTarget == n,
        onCall: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EmergencyCallScreen(
              name: n.name,
              avatarAsset: n.avatarAsset,
            ),
          ));
        },
        onComingToHelp: () {
          Navigator.of(sheetContext).pop();
          setState(() => _helpTarget = n);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: QColors.orange,
              content: Text(
                  '🧡 Heading to ${n.name} — other Quakers can see you are on the way'),
            ),
          );
        },
        onMarkSaved: () {
          Navigator.of(sheetContext).pop();
          if (widget.sarMode) {
            context.read<IncidentController>().markSaved(n);
          } else {
            setState(() {
              n.status = NeighborStatus.saved;
              if (_helpTarget == n) _helpTarget = null;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: QColors.green,
              content: Text('✓ ${n.name} marked as saved'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sarMode) {
      context.watch<IncidentController>();
    }
    LatLng? routeFrom;
    LatLng? routeTo;
    if (widget.sarMode) {
      final nearest = _nearestSos;
      if (nearest != null) {
        routeFrom = _origin;
        routeTo = nearest.point;
      }
    } else if (widget.sosMode && _responder != null) {
      routeFrom = _responder!.point;
      routeTo = _center;
    } else if (_helpTarget != null) {
      routeFrom = _center;
      routeTo = _helpTarget!.point;
    }

    final nearest = _nearestSos;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: widget.sarMode
                ? const LatLng(-6.2155, 106.8452)
                : _center,
            initialZoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.quacky',
            ),
            if (routeFrom != null && routeTo != null)
              _RoutePolyline(
                key: ValueKey('$routeFrom-$routeTo'),
                from: routeFrom,
                to: routeTo,
              ),
            MarkerLayer(
              markers: [
                for (final n in _neighbors)
                  Marker(
                    point: n.point,
                    width: 96,
                    height: 112,
                    child: GestureDetector(
                      onTap: (!widget.sosMode &&
                              n.status == NeighborStatus.sos)
                          ? () => _openRescueSheet(n)
                          : null,
                      child: _PersonPin(
                        neighbor: n,
                        isNearestTarget: n == nearest,
                        showNotified: widget.sosMode,
                        distanceLabel: _distanceTo(n.point),
                      ),
                    ),
                  ),
                Marker(
                  point: _origin,
                  width: 96,
                  height: 104,
                  child: widget.sarMode
                      ? const _RescuerPin()
                      : _SelfPin(sos: widget.sosMode),
                ),
              ],
            ),
          ],
        ),

        if (_alertFor != null && !widget.sosMode)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _openRescueSheet(_alertFor!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QColors.red,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(_alertFor!.avatarAsset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🆘 ${_alertFor!.name} needs help',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${_distanceTo(_alertFor!.point)} away — you are the nearest safe Quaker',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            )
                .animate()
                .slideY(begin: -1.5, curve: Curves.easeOut, duration: 400.ms)
                .then()
                .shake(hz: 3, rotation: 0.005, duration: 400.ms),
          ),

        if (widget.sosMode)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _responder == null
                    ? QColors.brown
                    : QColors.orange,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  if (_responder == null) ...[
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Calling nearby Quakers…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ] else ...[
                    CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          AssetImage(_responder!.avatarAsset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🧡 ${_responder!.name} is coming to help',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${_distanceTo(_responder!.point)} away — hold on',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().slideY(
                begin: -1.5, curve: Curves.easeOut, duration: 400.ms),
          ),
      ],
    );
  }
}


class _RoutePolyline extends StatefulWidget {
  final LatLng from;
  final LatLng to;
  const _RoutePolyline({super.key, required this.from, required this.to});

  @override
  State<_RoutePolyline> createState() => _RoutePolylineState();
}

class _RoutePolylineState extends State<_RoutePolyline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  List<LatLng> get _full {
    final mid = LatLng(
      widget.from.latitude + (widget.to.latitude - widget.from.latitude) * 0.5,
      widget.to.longitude,
    );
    return [widget.from, mid, widget.to];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pts = _interpolate(_full, _c.value);
        return PolylineLayer(
          polylines: [
            Polyline(
              points: pts,
              strokeWidth: 5,
              color: QColors.orange,
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  List<LatLng> _interpolate(List<LatLng> path, double t) {
    if (t >= 1) return path;
    final totalSegs = path.length - 1;
    final scaled = t * totalSegs;
    final seg = scaled.floor();
    final frac = scaled - seg;
    final out = <LatLng>[];
    for (int i = 0; i <= seg; i++) {
      out.add(path[i]);
    }
    if (seg < totalSegs) {
      final a = path[seg];
      final b = path[seg + 1];
      out.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * frac,
        a.longitude + (b.longitude - a.longitude) * frac,
      ));
    }
    return out;
  }
}

class _PersonPin extends StatelessWidget {
  final _Neighbor neighbor;
  final bool isNearestTarget;
  final bool showNotified;
  final String distanceLabel;
  const _PersonPin({
    required this.neighbor,
    required this.distanceLabel,
    this.isNearestTarget = false,
    this.showNotified = false,
  });

  Color get _color => switch (neighbor.status) {
        NeighborStatus.safe => QColors.green,
        NeighborStatus.sos => QColors.red,
        NeighborStatus.saved => Colors.blueGrey,
        NeighborStatus.responding => QColors.orange,
      };

  String get _label => switch (neighbor.status) {
        NeighborStatus.responding => 'On the way',
        _ => neighbor.name,
      };

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _color, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
        image: DecorationImage(
          image: AssetImage(neighbor.avatarAsset),
          fit: BoxFit.cover,
        ),
      ),
      child: neighbor.status == NeighborStatus.saved
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 26),
            )
          : null,
    );

    if (neighbor.status == NeighborStatus.sos ||
        neighbor.status == NeighborStatus.responding) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNearestTarget ? QColors.orange : _color,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                begin: 1,
                end: isNearestTarget ? 2.6 : 2,
                duration: isNearestTarget ? 1000.ms : 1200.ms,
              )
              .fadeOut(duration: isNearestTarget ? 1000.ms : 1200.ms),
          avatar,
        ],
      );
    }

    if (showNotified &&
        neighbor.notified &&
        neighbor.status == NeighborStatus.safe) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: QColors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.notifications_active,
                  size: 12, color: Colors.white),
            ).animate().scale(
                  begin: const Offset(0, 0),
                  curve: Curves.elasticOut,
                  duration: 500.ms,
                ),
          ),
        ],
      );
    }

    final isSos = neighbor.status == NeighborStatus.sos;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isNearestTarget && isSos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: QColors.orange,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Text(
              'NEAREST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.1, duration: 700.ms),
        avatar,
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (isSos)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: QColors.red, width: 1.5),
            ),
            child: Text(
              distanceLabel,
              style: const TextStyle(
                color: QColors.red,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _RescuerPin extends StatelessWidget {
  const _RescuerPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: QColors.nightIndigo,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 6),
            ],
          ),
          child: const Icon(Icons.shield, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: QColors.nightIndigo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'SAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelfPin extends StatelessWidget {
  final bool sos;
  const _SelfPin({required this.sos});

  @override
  Widget build(BuildContext context) {
    final color = sos ? QColors.red : QColors.green;
    Widget avatar = Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Image.asset(
        sos
            ? 'assets/images/Quaky_Danger.png'
            : 'assets/images/Quaky_Safe.png',
        fit: BoxFit.contain,
      ),
    );

    if (sos) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QColors.red,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1, end: 2.1, duration: 1400.ms)
              .fadeOut(duration: 1400.ms),
          avatar,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'You',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RescueSheet extends StatelessWidget {
  final _Neighbor neighbor;
  final List<String> frames;
  final bool sarMode;
  final String distanceLabel;
  final bool alreadyHelping;
  final VoidCallback onMarkSaved;
  final VoidCallback onComingToHelp;
  final VoidCallback onCall;
  const _RescueSheet({
    required this.neighbor,
    required this.frames,
    required this.sarMode,
    required this.distanceLabel,
    required this.alreadyHelping,
    required this.onMarkSaved,
    required this.onComingToHelp,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final userConfirmed = neighbor.locSource == LocSource.user;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: QColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: QColors.creamDeep,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: QColors.red, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundImage: AssetImage(neighbor.avatarAsset),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        neighbor.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${neighbor.age} yrs · ${neighbor.gender} · $distanceLabel away',
                        style: const TextStyle(
                            fontSize: 14, color: QColors.brownSoft),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: QColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 1, end: 0.5, duration: 600.ms),
              ],
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (userConfirmed ? QColors.green : QColors.orange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: userConfirmed ? QColors.green : QColors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    userConfirmed ? Icons.verified : Icons.auto_awesome,
                    color: userConfirmed ? QColors.green : QColors.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userConfirmed
                              ? 'LOCATION · USER CONFIRMED'
                              : 'LOCATION · AI SUGGESTION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color:
                                userConfirmed ? QColors.green : QColors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userConfirmed
                              ? '“${neighbor.locNote}”'
                              : neighbor.aiSummary,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: QColors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 20),

            const Text(
              'LAST FRAMES FROM CAMERA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: QColors.brownSoft,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: frames.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    frames[i],
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                )
                    .animate()
                    .fadeIn(delay: (120 * i).ms)
                    .slideX(begin: 0.3, curve: Curves.easeOut),
              ),
            ),
            const SizedBox(height: 24),

            if (sarMode) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QColors.red,
                  minimumSize: const Size.fromHeight(64),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 26),
                label: const Text('EMERGENCY CALL'),
                onPressed: onCall,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.02, duration: 600.ms),
              const SizedBox(height: 10),
            ],

            if (!sarMode && !alreadyHelping)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QColors.orange,
                  minimumSize: const Size.fromHeight(64),
                ),
                icon: const Icon(Icons.directions_run, size: 26),
                label: const Text("I'M COMING TO HELP"),
                onPressed: onComingToHelp,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.02, duration: 600.ms)
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QColors.green,
                  minimumSize: const Size.fromHeight(64),
                ),
                icon: const Icon(Icons.volunteer_activism, size: 26),
                label: const Text('MARK AS SAVED'),
                onPressed: onMarkSaved,
              ).animate().fadeIn().slideY(begin: 0.3),
            const SizedBox(height: 8),
            Text(
              (!sarMode && !alreadyHelping)
                  ? 'Let ${neighbor.name} know you are on the way.\nOther Quakers will see this node is covered.'
                  : 'Mark as saved once you have reached and secured this Quaker.\nSAR teams will see this node as cleared.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: QColors.brownSoft),
            ),
          ],
        ),
      ),
    );
  }
}

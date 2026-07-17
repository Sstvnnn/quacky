import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_theme.dart';
import '../core/mock_config.dart';

enum NeighborStatus { safe, sos, saved }

class _Neighbor {
  final String name;
  final int age;
  final String gender;
  final String avatarAsset;
  final LatLng point;
  final String distance;
  NeighborStatus status = NeighborStatus.safe;

  _Neighbor({
    required this.name,
    required this.age,
    required this.gender,
    required this.avatarAsset,
    required this.point,
    required this.distance,
  });
}

class CommunityMap extends StatefulWidget {
  final bool sosMode;
  const CommunityMap({super.key, this.sosMode = false});

  @override
  State<CommunityMap> createState() => _CommunityMapState();
}

class _CommunityMapState extends State<CommunityMap> {
  // Jakarta Convention Center area — change to your demo city if you like.
  static const _center = LatLng(-6.2146, 106.8451);

  late final List<_Neighbor> _neighbors;
  Timer? _incomingSos;
  _Neighbor? _alertFor;

  static const _dangerFrames = [
    'assets/images/Danger_Pic1.jpg',
    'assets/images/Danger_Pic2.jpg',
    'assets/images/Danger_Pic3.jpg',
    'assets/images/Danger_Pic4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _neighbors = [
      _Neighbor(
        name: 'Sari',
        age: 24,
        gender: 'Female',
        avatarAsset: 'assets/images/young-female.jpg',
        point: const LatLng(-6.2135, 106.8437),
        distance: '90 m',
      ),
      _Neighbor(
        name: 'Budi',
        age: 43,
        gender: 'Male',
        avatarAsset: 'assets/images/man.jpg',
        point: const LatLng(-6.2159, 106.8468),
        distance: '210 m',
      ),
      _Neighbor(
        name: 'Pak Joko',
        age: 68,
        gender: 'Male',
        avatarAsset: 'assets/images/elder.jpg',
        point: const LatLng(-6.2128, 106.8462),
        distance: '260 m',
      ),
      _Neighbor(
        name: 'Dimas',
        age: 26,
        gender: 'Male',
        avatarAsset: 'assets/images/young-male.jpg',
        point: const LatLng(-6.2161, 106.8433),
        distance: '140 m',
      ),
      _Neighbor(
        name: 'Bima',
        age: 7,
        gender: 'Male',
        avatarAsset: 'assets/images/boy.jpg',
        point: const LatLng(-6.2140, 106.8480),
        distance: '320 m',
      ),
    ];

    _incomingSos = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() {
        _neighbors[3].status = NeighborStatus.sos;
        _alertFor = _neighbors[3];
      });
    });
  }

  @override
  void dispose() {
    _incomingSos?.cancel();
    super.dispose();
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
        onMarkSaved: () {
          Navigator.of(sheetContext).pop();
          setState(() => n.status = NeighborStatus.saved);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: QColors.green,
              content: Text(
                  '✓ ${n.name} marked as saved — SAR teams notified'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(initialCenter: _center, initialZoom: 16.2),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.quacky',
            ),
            MarkerLayer(
              markers: [
                for (final n in _neighbors)
                  Marker(
                    point: n.point,
                    width: 74,
                    height: 84,
                    child: GestureDetector(
                      onTap: n.status == NeighborStatus.sos
                          ? () => _openRescueSheet(n)
                          : null,
                      child: _PersonPin(neighbor: n),
                    ),
                  ),
                Marker(
                  point: _center,
                  width: 96,
                  height: 104,
                  child: _SelfPin(sos: widget.sosMode),
                ),
              ],
            ),
          ],
        ),

        if (_alertFor != null)
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
                            '${_alertFor!.distance} away — you are the nearest safe user',
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
      ],
    );
  }
}

class _PersonPin extends StatelessWidget {
  final _Neighbor neighbor;
  const _PersonPin({required this.neighbor});

  Color get _color => switch (neighbor.status) {
        NeighborStatus.safe => QColors.green,
        NeighborStatus.sos => QColors.red,
        NeighborStatus.saved => Colors.blueGrey,
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
              child:
                  const Icon(Icons.check, color: Colors.white, size: 26),
            )
          : null,
    );

    if (neighbor.status == NeighborStatus.sos) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QColors.red,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1, end: 2, duration: 1200.ms)
              .fadeOut(duration: 1200.ms),
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
            color: _color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            neighbor.name,
            style: const TextStyle(
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
  final VoidCallback onMarkSaved;
  const _RescueSheet({
    required this.neighbor,
    required this.frames,
    required this.onMarkSaved,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
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

            // Victim header.
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
                        '${neighbor.age} yrs · ${neighbor.gender} · ${neighbor.distance} away',
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
            const SizedBox(height: 20),

            const Text(
              'SITUATION SUMMARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: QColors.brownSoft,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: QColors.creamDeep, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: QColors.orange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      MockConfig.geminiContextSummary,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: QColors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: QColors.green,
                minimumSize: const Size.fromHeight(64),
              ),
              icon: const Icon(Icons.volunteer_activism, size: 26),
              label: const Text('MARK AS SAVED'),
              onPressed: onMarkSaved,
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3),
            const SizedBox(height: 8),
            const Text(
              'Press once you have reached and secured this person.\nSAR teams will see this node as cleared.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: QColors.brownSoft),
            ),
          ],
        ),
      ),
    );
  }
}

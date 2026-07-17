import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../state/incident_controller.dart';
import 'emergency_call_screen.dart';
import 'sar_dashboard_screen.dart';

class SarIncidentsScreen extends StatelessWidget {
  const SarIncidentsScreen({super.key});

  static const _frames = [
    'assets/images/Danger_Pic1.jpg',
    'assets/images/Danger_Pic2.jpg',
    'assets/images/Danger_Pic3.jpg',
    'assets/images/Danger_Pic4.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentController>();
    final records = inc.incidents;
    return Scaffold(
      backgroundColor: QColors.nightIndigo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'INCIDENT DATA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: inc.allClear ? QColors.green : QColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      inc.allClear
                          ? 'ALL CLEAR'
                          : '${inc.activeSos} ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _IncidentCard(
                  quaker: records[i],
                  frames: _frames,
                )
                    .animate()
                    .fadeIn(delay: (110 * i).ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Quaker quaker;
  final List<String> frames;
  const _IncidentCard({required this.quaker, required this.frames});

  @override
  Widget build(BuildContext context) {
    final sos = quaker.status == NeighborStatus.sos;
    final userConfirmed = quaker.locSource == LocSource.user;
    final accent = sos ? QColors.red : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage(quaker.avatarAsset),
                  child: !sos
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 22),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quaker.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${quaker.age} yrs · ${quaker.gender} · ${distanceLabelFrom(sarBasePoint, quaker.point)} from base',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  sos ? 'SOS' : 'CLEARED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ).animate(
                onPlay: (c) {
                  if (sos) c.repeat(reverse: true);
                },
              ).fade(begin: 1, end: sos ? 0.55 : 1, duration: 600.ms),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      userConfirmed ? Icons.verified : Icons.auto_awesome,
                      size: 14,
                      color:
                          userConfirmed ? QColors.green : QColors.yellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      userConfirmed
                          ? 'USER CONFIRMED LOCATION'
                          : 'AI SUGGESTED LOCATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color:
                            userConfirmed ? QColors.green : QColors.yellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  userConfirmed ? '“${quaker.locNote}”' : quaker.aiSummary,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: frames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  frames[i],
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (sos) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QColors.red,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 19),
                    label: const Text('CALL',
                        style: TextStyle(fontSize: 14)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EmergencyCallScreen(
                          name: quaker.name,
                          avatarAsset: quaker.avatarAsset,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 19),
                    label: const Text('VIEW MAP',
                        style: TextStyle(fontSize: 14)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SarDashboardScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

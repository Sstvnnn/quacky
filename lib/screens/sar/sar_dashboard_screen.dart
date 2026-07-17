import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../state/incident_controller.dart';
import '../../widgets/community_map.dart';

class SarDashboardScreen extends StatelessWidget {
  const SarDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentController>();
    final clear = inc.allClear;
    final accent = clear ? QColors.green : QColors.red;
    return Scaffold(
      backgroundColor: QColors.nightIndigo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE OPERATIONS MAP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          clear
                              ? 'Jakarta sector 4 · sector clear'
                              : 'Jakarta sector 4 · live incident',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      clear ? 'ALL CLEAR' : '${inc.activeSos} ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _Stat(
                    label: 'ACTIVE SOS',
                    value: inc.activeSos,
                    color: QColors.red,
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    label: 'SAFE',
                    value: inc.safeCount,
                    color: QColors.green,
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    label: 'CLEARED',
                    value: inc.clearedCount,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: accent, width: 3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      const CommunityMap(sarMode: true),
                      if (clear)
                        Positioned(
                          top: 14,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: QColors.green,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38, blurRadius: 10),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'ALL NODES CLEARED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .slideY(
                                begin: -1.5,
                                curve: Curves.easeOut,
                                duration: 400.ms,
                              )
                              .then()
                              .shake(hz: 2, rotation: 0.004, duration: 300.ms),
                        )
                      else
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tap a red node to open rescue details',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12.5),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

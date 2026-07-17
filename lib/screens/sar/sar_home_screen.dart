import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../core/mock_config.dart';
import '../../state/incident_controller.dart';
import '../auth/login_screen.dart';
import 'sar_dashboard_screen.dart';
// import 'sar_incidents_screen.dart';

class SarHomeScreen extends StatelessWidget {
  const SarHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentController>();
    final active = !inc.allClear;
    return Scaffold(
      backgroundColor: QColors.nightIndigo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                child: Row(
                  children: [
                    const Icon(Icons.shield_moon,
                        color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SAR OPERATIONS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Team Alpha · Jakarta sector 4',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout, color: Colors.white54),
                      onPressed: () => _logout(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 8),

              // Incident status hero — red while nodes are down, green when
              // the sector is fully cleared.
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: active ? QColors.red : QColors.green,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (active ? QColors.red : QColors.green)
                          .withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Icon(
                        active ? Icons.crisis_alert : Icons.verified,
                        key: ValueKey(active),
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active ? 'ACTIVE EMERGENCY' : 'ALL CLEAR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            active
                                ? 'M ${MockConfig.magnitude} earthquake · ${inc.activeSos} Quaker${inc.activeSos == 1 ? '' : 's'} awaiting rescue'
                                : 'Every SOS node in this sector has been rescued',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate(
                    key: ValueKey('hero-$active'),
                    onPlay: (c) {
                      if (active) c.repeat(reverse: true);
                    },
                  )
                  .scaleXY(
                    end: active ? 1.015 : 1.0,
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 14),

              Row(
                children: [
                  _LiveStat(
                    label: 'ACTIVE SOS',
                    value: inc.activeSos,
                    color: QColors.red,
                  ),
                  const SizedBox(width: 10),
                  _LiveStat(
                    label: 'SAFE',
                    value: inc.safeCount,
                    color: QColors.green,
                  ),
                  const SizedBox(width: 10),
                  _LiveStat(
                    label: 'CLEARED',
                    value: inc.clearedCount,
                    color: Colors.blueGrey,
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
              const SizedBox(height: 18),

              _NavCard(
                icon: Icons.map_outlined,
                title: 'Live operations map',
                subtitle: active
                    ? 'Routes, nearest node and rescue actions'
                    : 'Sector overview — all nodes green',
                accent: active ? QColors.red : QColors.green,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SarDashboardScreen()),
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.25),
              const SizedBox(height: 12),
              _NavCard(
                icon: Icons.assignment_outlined,
                title: 'Incident data',
                subtitle:
                    '${inc.incidents.length} record${inc.incidents.length == 1 ? '' : 's'} · profiles, frames & AI context',
                accent: QColors.orange,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SarIncidentsScreen()),
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.25),
              const Spacer(),

              Center(
                child: Text(
                  'Quaky Rescue Network',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _LiveStat({
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

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../widgets/seismic_wave.dart';
import 'auth/login_screen.dart';
import 'emergency_flow_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _displayName {
    final user = Supabase.instance.client.auth.currentUser;
    return (user?.userMetadata?['display_name'] as String?) ?? 'Friend';
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _startFlow(BuildContext context, {required bool drill}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmergencyFlowScreen(drill: drill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset('assets/images/Quaky_Logo.png', height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $_displayName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'You’re protected',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: QColors.brownSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout, color: QColors.brownSoft),
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: QColors.creamDeep, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: QColors.green,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(end: 1.5, duration: 800.ms)
                        .fade(end: 0.5),
                    const SizedBox(width: 9),
                    const Text(
                      'Monitoring motion sensors',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: QColors.brown,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: () => _startFlow(context, drill: false),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 210,
                          height: 210,
                          decoration: const BoxDecoration(
                            color: QColors.sleepBlue,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(
                              begin: 0.85,
                              end: 1.05,
                              duration: 2600.ms,
                              curve: Curves.easeInOut,
                            )
                            .fade(begin: 0.35, end: 0.6),
                        Image.asset('assets/images/Idle.png', width: 200)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(
                              begin: 0,
                              end: -14,
                              duration: 2600.ms,
                              curve: Curves.easeInOut,
                            ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quaky is resting',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 20),

              const SeismicWave(
                active: false,
                color: QColors.creamDeep,
                height: 70,
              ),
              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Drill'),
                      onPressed: () => _startFlow(context, drill: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Map'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

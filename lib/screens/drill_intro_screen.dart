import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import 'emergency_flow_screen.dart';

class DrillIntroScreen extends StatelessWidget {
  const DrillIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/images/Quaky_Logo.png', width: 190)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(end: -10, duration: 1200.ms, curve: Curves.easeInOut),
              const SizedBox(height: 28),
              const Text(
                'One drill before\nQuacky protects you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
              const SizedBox(height: 14),
              const Text(
                'You will hear the real alarm, talk to Quacky, and practice '
                'the safety check. In a real earthquake your hands will '
                'already know what to do.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: QColors.brownSoft),
              ).animate().fadeIn(delay: 500.ms),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QColors.creamDeep,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.volume_up, color: QColors.brown),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Turn your volume up — the drill alarm is loud on purpose.',
                        style: TextStyle(fontSize: 13, color: QColors.brown),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Start the drill'),
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const EmergencyFlowScreen(drill: true),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.4),
            ],
          ),
        ),
      ),
    );
  }
}

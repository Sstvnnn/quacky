import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../state/quake_controller.dart';
import '../widgets/state_hud.dart';
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
    final phase = context.watch<QuakeController>().phase;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/Quaky_Logo.png', height: 44),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            StateHud(phase: phase),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Hi, $_displayName!',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 4),
                    const Text(
                      'Quacky is watching over you.',
                      style:
                          TextStyle(fontSize: 15, color: QColors.brownSoft),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: QColors.creamDeep, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: QColors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(end: 1.5, duration: 800.ms)
                              .fade(end: 0.5),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sensors active',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mic + accelerometer monitoring',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: QColors.brownSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),

                    // The demo trigger.
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QColors.red,
                        minimumSize: const Size.fromHeight(72),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded, size: 30),
                      label: const Text('SIMULATE EARTHQUAKE'),
                      onPressed: () => _startFlow(context, drill: false),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(end: 1.02, duration: 900.ms)
                        .animate() 
                        .fadeIn(delay: 350.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Practice drill'),
                      onPressed: () => _startFlow(context, drill: true),
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Community map'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      ),
                    ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

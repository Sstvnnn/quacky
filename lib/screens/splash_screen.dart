import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../state/profile_service.dart';
import 'drill_intro_screen.dart';
import 'home_screen.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2000), _route);
  }

  Future<void> _route() async {
    final session = Supabase.instance.client.auth.currentSession;
    Widget next;
    if (session == null) {
      next = const LandingScreen();
    } else {
      bool done = false;
      try {
        done = (await ProfileService.fetchProfile())
                ?.hasCompletedSimulation ??
            false;
      } catch (_) {}
      next = done ? const HomeScreen() : const DrillIntroScreen();
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Quaky_Logo.png', width: 220)
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Your earthquake buddy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: QColors.brownSoft,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 600.ms).slideY(
                  begin: 0.4,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class _Slide {
  final String image;
  final String title;
  final String body;
  const _Slide(this.image, this.title, this.body);
}


class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      'assets/images/Idle.png',
      'Always on watch',
      'Whenever your phone is idle, Quacky quietly feels for the ground shaking. Just a vigilant little duck keeping watch day and night.',
    ),
    _Slide(
      'assets/images/Quaky_Danger.png',
      'Wake up instantly',
      'If nearby phones agree the ground is moving, Quacky sounds a loud alarm that won’t stop until you are awake and ready to act.',
    ),
    _Slide(
      'assets/images/Quaky_Speech.png',
      'Your smart guide',
      'Point your camera around the room. Quacky will look around and tell you exactly where to duck and cover in seconds.',
    ),
    _Slide(
      'assets/images/Quaky_Safe.png',
      'Nobody left behind',
      'Mark yourself safe or send an SOS. Your neighbors and rescue teams will instantly see who needs help and exactly where to go.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _go(const RegisterScreen());
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _go(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(s.image, height: 220)
                            .animate(key: ValueKey('img$i'))
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(),
                        const SizedBox(height: 40),
                        Text(
                              s.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                            .animate(key: ValueKey('t$i'))
                            .fadeIn(delay: 120.ms)
                            .slideY(begin: 0.3),
                        const SizedBox(height: 16),
                        Text(
                              s.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.5,
                                height: 1.5,
                                color: QColors.brownSoft,
                              ),
                            )
                            .animate(key: ValueKey('b$i'))
                            .fadeIn(delay: 240.ms)
                            .slideY(begin: 0.3),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? QColors.orange : QColors.creamDeep,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_isLast ? 'Get started' : 'Next'),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                foregroundColor: QColors.orange,
              ),
              onPressed: () => _go(const LoginScreen()),
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Already have an account?   '),
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(
                        color: QColors.orange,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                        decorationColor: QColors.orange,
                        decorationThickness: 2,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: QColors.brownSoft,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_theme.dart';

class EmergencyCallScreen extends StatefulWidget {
  final String name;
  final String avatarAsset;
  const EmergencyCallScreen({
    super.key,
    required this.name,
    required this.avatarAsset,
  });

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  bool _connected = false;
  int _seconds = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _connected = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _time {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.nightIndigo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (!_connected)
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: QColors.red,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(begin: 1, end: 1.5, duration: 1200.ms)
                        .fadeOut(duration: 1200.ms),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 72,
                      backgroundImage: AssetImage(widget.avatarAsset),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _connected ? 'Connected · $_time' : 'Connecting…',
                style: TextStyle(
                  color: _connected ? QColors.green : Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 40),
              if (_connected)
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(28, (i) {
                      return Container(
                        width: 4,
                        height: 8.0 + (i % 5) * 10,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                            delay: (i * 60).ms,
                          )
                          .scaleY(
                            begin: 0.3,
                            end: 1.6,
                            duration: 400.ms,
                            curve: Curves.easeInOut,
                          );
                    }),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: QColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end,
                      color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'End call',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

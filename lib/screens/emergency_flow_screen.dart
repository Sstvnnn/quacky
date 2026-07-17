import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/app_theme.dart';
import '../core/mock_config.dart';
import '../state/profile_service.dart';
import '../state/quake_controller.dart';
import '../widgets/community_map.dart';
import '../widgets/state_hud.dart';
import '../widgets/typing_text.dart';
import 'home_screen.dart';

class EmergencyFlowScreen extends StatefulWidget {
  final bool drill;
  const EmergencyFlowScreen({super.key, required this.drill});

  @override
  State<EmergencyFlowScreen> createState() => _EmergencyFlowScreenState();
}

class _EmergencyFlowScreenState extends State<EmergencyFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuakeController>().startEmergency(drill: widget.drill);
    });
  }

  @override
  Widget build(BuildContext context) {
    final qc = context.watch<QuakeController>();
    final resolved =
        qc.phase == QuakePhase.safe || qc.phase == QuakePhase.sos;

    final Widget view = switch (qc.phase) {
      QuakePhase.idle => const SizedBox.shrink(),
      QuakePhase.detecting => const _DetectingView(),
      QuakePhase.consensus => _ConsensusView(votes: qc.consensusVotes),
      QuakePhase.alarm => _AlarmView(onAck: qc.acknowledgeAlarm),
      QuakePhase.geminiLive => _GeminiLiveView(
          countdown: qc.countdown,
          captions: qc.captions,
          onSafe: qc.markSafe,
          onSos: qc.triggerSos,
        ),
      QuakePhase.safe || QuakePhase.sos =>
        _ResultView(sos: qc.phase == QuakePhase.sos, drill: qc.isDrill),
    };

    final dark =
        qc.phase == QuakePhase.alarm || qc.phase == QuakePhase.geminiLive;

    return PopScope(
      // No backing out mid-emergency; the flow must resolve.
      canPop: resolved || qc.phase == QuakePhase.idle,
      child: Scaffold(
        backgroundColor: qc.phase == QuakePhase.alarm
            ? QColors.redDark
            : qc.phase == QuakePhase.geminiLive
                ? Colors.black
                : QColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              if (qc.isDrill) const _DrillBanner(),
              if (!dark) StateHud(phase: qc.phase),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: KeyedSubtree(
                    key: ValueKey(qc.phase),
                    child: view,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrillBanner extends StatelessWidget {
  const _DrillBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: QColors.yellow,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        '🎓 DRILL — not a real earthquake',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: QColors.brown,
        ),
      ),
    );
  }
}

class _DetectingView extends StatefulWidget {
  const _DetectingView();

  @override
  State<_DetectingView> createState() => _DetectingViewState();
}

class _DetectingViewState extends State<_DetectingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();
  final _rng = Random();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(24, (i) {
                final h = 8.0 + _rng.nextDouble() * 72;
                return Container(
                  width: 6,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: h > 56 ? QColors.red : QColors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'Anomaly detected',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          const Text(
            'Low-frequency rumble on microphone · accelerometer spike',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: QColors.brownSoft),
          ),
        ],
      ),
    );
  }
}


class _ConsensusView extends StatelessWidget {
  final int votes;
  const _ConsensusView({required this.votes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: QColors.yellow,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 1, end: 2.3, duration: 1300.ms)
                    .fadeOut(duration: 1300.ms),
                const Icon(Icons.wifi_tethering,
                    size: 56, color: QColors.brown),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$votes of ${MockConfig.consensusPool} nearby devices confirmed',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifying with the crowd before sounding the alarm',
            style: TextStyle(fontSize: 14, color: QColors.brownSoft),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(MockConfig.consensusPool, (i) {
              final confirmed = i < votes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.phone_android,
                  size: 34,
                  color: confirmed ? QColors.green : QColors.creamDeep,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AlarmView extends StatelessWidget {
  final VoidCallback onAck;
  const _AlarmView({required this.onAck});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAck,
      child: Container(
        width: double.infinity,
        color: QColors.red,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Quaky_Danger.png', width: 200)
                .animate(onPlay: (c) => c.repeat())
                .shake(hz: 5, rotation: 0.06, duration: 800.ms),
            const SizedBox(height: 24),
            const Text(
              'EARTHQUAKE!',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 1, end: 0.35, duration: 400.ms),
            const SizedBox(height: 10),
            Text(
              'Confirmed by ${MockConfig.consensusNeeded} nearby devices',
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'TAP ANYWHERE TO ANSWER QUACKY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: QColors.red,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.08, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _GeminiLiveView extends StatefulWidget {
  final int countdown;
  final List<String> captions;
  final VoidCallback onSafe;
  final VoidCallback onSos;
  const _GeminiLiveView({
    required this.countdown,
    required this.captions,
    required this.onSafe,
    required this.onSos,
  });

  @override
  State<_GeminiLiveView> createState() => _GeminiLiveViewState();
}

class _GeminiLiveViewState extends State<_GeminiLiveView> {
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.asset(MockConfig.geminiFeedAsset);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _video = c;
        _videoReady = true;
      });
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = widget.countdown <= 10;
    final caption = widget.captions.isEmpty ? null : widget.captions.last;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera feed.
        if (_videoReady && _video != null)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _video!.value.size.width,
              height: _video!.value.size.height,
              child: VideoPlayer(_video!),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF101418), Color(0xFF1C232B)],
              ),
            ),
            child: Center(
              child: const Icon(Icons.videocam,
                      size: 72, color: Colors.white24)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.4, end: 1, duration: 900.ms),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black87,
                Colors.transparent,
                Colors.transparent,
                Colors.black87,
              ],
              stops: [0, 0.25, 0.6, 1],
            ),
          ),
        ),

        Column(
          children: [
            const SizedBox(height: 10),
            // Top bar: live badge + countdown.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: QColors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 1, end: 0.2, duration: 600.ms),
                        const SizedBox(width: 7),
                        const Text(
                          'GEMINI LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Countdown ring.
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: widget.countdown /
                              MockConfig.geminiWindowSeconds,
                          strokeWidth: 5,
                          color: urgent ? QColors.red : QColors.yellow,
                          backgroundColor: Colors.white24,
                        ),
                        Text(
                          '${widget.countdown}',
                          style: TextStyle(
                            color: urgent ? QColors.red : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            if (caption != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset('assets/images/Quaky_Speech.png', width: 54)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(end: 1.08, duration: 700.ms),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TypingText(
                          caption,
                          key: ValueKey(caption),
                          textAlign: TextAlign.left,
                          charDelay: const Duration(milliseconds: 28),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 84,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QColors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: widget.onSafe,
                        child: const Text(
                          "I'M SAFE",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 84,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: widget.onSos,
                        child: const Text(
                          'SOS',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                        end: 1.03,
                        duration: 600.ms,
                      ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final bool sos;
  final bool drill;
  const _ResultView({required this.sos, required this.drill});

  Future<void> _finish(BuildContext context) async {
    final qc = context.read<QuakeController>();
    if (drill) {
      try {
        await ProfileService.markSimulationComplete();
      } catch (_) {}
    }
    qc.reset();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = sos ? QColors.red : QColors.green;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: color,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Column(
            children: [
              Text(
                sos ? '🆘 SOS — RESCUE ALERT ACTIVE' : '✓ YOU ARE MARKED SAFE',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sos
                    ? 'Your GPS, camera frames and situation summary are being shared with nearby users and Search & Rescue'
                    : 'Nearby users can see you are okay',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ).animate().slideY(begin: -1, curve: Curves.easeOut),
        Expanded(child: CommunityMap(sosMode: sos)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (sos) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QColors.green,
                    minimumSize: const Size.fromHeight(64),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 26),
                  label: const Text("I'M SAFE NOW"),
                  onPressed: () =>
                      context.read<QuakeController>().markSafe(),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.03, duration: 600.ms),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                icon: const Icon(Icons.home),
                label: Text(drill ? 'Finish drill' : 'Back to home'),
                onPressed: () => _finish(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

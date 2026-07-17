import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/app_theme.dart';
import '../core/mock_config.dart';
import '../state/profile_service.dart';
import '../state/quake_controller.dart';
import '../widgets/community_map.dart';
import '../widgets/seismic_wave.dart';
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
          onSafe: qc.markSafe,
          onSos: qc.triggerSos,
        ),
      QuakePhase.safe || QuakePhase.sos =>
        _ResultView(sos: qc.phase == QuakePhase.sos, drill: qc.isDrill),
    };

    return PopScope(
      canPop: resolved || qc.phase == QuakePhase.idle,
      child: Scaffold(
        backgroundColor:
            qc.phase == QuakePhase.alarm ? QColors.red : QColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              if (qc.isDrill) const _DrillBanner(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: KeyedSubtree(key: ValueKey(qc.phase), child: view),
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

class _DetectingView extends StatelessWidget {
  const _DetectingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SeismicWave(
            active: true,
            color: QColors.orange,
            height: 150,
          ),
          const SizedBox(height: 40),
          const Text(
            'Seismic activity detected',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          const Text(
            'Unusual ground motion on this device',
            style: TextStyle(fontSize: 14.5, color: QColors.brownSoft),
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
    final reached = votes >= MockConfig.consensusNeeded;
    final lit =
        ((votes / MockConfig.consensusReached) * 5).clamp(0, 5).floor();
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
                  decoration: BoxDecoration(
                    color: reached ? QColors.green : QColors.yellow,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 1, end: 2.3, duration: 1300.ms)
                    .fadeOut(duration: 1300.ms),
                Icon(
                  reached ? Icons.verified : Icons.wifi_tethering,
                  size: 56,
                  color: reached ? QColors.green : QColors.brown,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  '$votes',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: reached ? QColors.green : QColors.brown,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'devices\nconfirmed',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: QColors.brownSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.phone_android,
                  size: 34,
                  color: i < lit ? QColors.green : QColors.creamDeep,
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          AnimatedOpacity(
            opacity: reached ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: QColors.orange, width: 2),
              ),
              child: Text(
                'Estimated magnitude  M ${MockConfig.magnitude}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: QColors.brown,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Within ${MockConfig.consensusRadiusKm.toStringAsFixed(0)} km · ${MockConfig.consensusWindowSeconds}s window',
            style: const TextStyle(fontSize: 13, color: QColors.brownSoft),
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
            Image.asset('assets/images/Quaky_Danger.png', width: 190)
                .animate(onPlay: (c) => c.repeat())
                .shake(hz: 5, rotation: 0.06, duration: 800.ms),
            const SizedBox(height: 22),
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
            const SizedBox(height: 12),
            Text(
              'M ${MockConfig.magnitude} · confirmed by ${MockConfig.consensusReached} devices',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 46),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'TAP ANYWHERE TO CONTINUE',
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
  final VoidCallback onSafe;
  final VoidCallback onSos;
  const _GeminiLiveView({
    required this.countdown,
    required this.onSafe,
    required this.onSos,
  });

  @override
  State<_GeminiLiveView> createState() => _GeminiLiveViewState();
}

class _GeminiLiveViewState extends State<_GeminiLiveView> {
  VideoPlayerController? _video;
  bool _ready = false;
  String? _analysis;
  final List<Timer> _scriptTimers = [];

  @override
  void initState() {
    super.initState();
    _initVideo();
    for (final (sec, line) in MockConfig.geminiAnalysis) {
      _scriptTimers.add(Timer(Duration(seconds: sec), () {
        if (mounted) setState(() => _analysis = line);
      }));
    }
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.asset(MockConfig.geminiFeedAsset);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(1);
      await c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _video = c;
        _ready = true;
      });
    } catch (_) {
    }
  }

  @override
  void dispose() {
    for (final t in _scriptTimers) {
      t.cancel();
    }
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = widget.countdown <= 10;
    final ringColor = urgent ? QColors.red : QColors.orange;
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: (widget.countdown + 1) /
                        MockConfig.geminiWindowSeconds,
                    end: widget.countdown / MockConfig.geminiWindowSeconds,
                  ),
                  duration: const Duration(seconds: 1),
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: ringColor,
                    backgroundColor: QColors.creamDeep,
                  ),
                ),
              ),
              Text(
                '${widget.countdown}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: urgent ? QColors.red : QColors.brown,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: (_ready && _video != null)
                          ? FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: _video!.value.size.width,
                                height: _video!.value.size.height,
                                child: VideoPlayer(_video!),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF12181F),
                              child: Center(
                                child: const Icon(Icons.videocam,
                                        size: 64, color: Colors.white24)
                                    .animate(
                                        onPlay: (c) =>
                                            c.repeat(reverse: true))
                                    .fade(
                                        begin: 0.4,
                                        end: 1,
                                        duration: 900.ms),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_analysis != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: QColors.creamDeep, width: 2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome,
                                  color: QColors.orange, size: 20)
                              .animate(
                                  onPlay: (c) => c.repeat(reverse: true))
                              .fade(begin: 0.5, end: 1, duration: 700.ms),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TypingText(
                              _analysis!,
                              key: ValueKey(_analysis),
                              textAlign: TextAlign.left,
                              charDelay: const Duration(milliseconds: 24),
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: QColors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 88,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: widget.onSafe,
                    child: const Text("I'M SAFE",
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 88,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QColors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: widget.onSos,
                    child: const Text('SOS',
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.w900)),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                    end: 1.03, duration: 600.ms),
              ),
            ],
          ),
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
    final qc = context.watch<QuakeController>();
    final color = sos ? QColors.red : QColors.green;
    return Container(
      color: QColors.cream,
      child: Column(
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
                      ? 'Alerting nearby Quakers and Search & Rescue with your location and camera context'
                      : 'Nearby Quakers can see you are okay',
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
                  if (qc.locationSource == LocationSource.userConfirmed)
                    _ConfirmedLocationCard(note: qc.locationNote)
                  else
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(color: QColors.orange, width: 2),
                      ),
                      icon: const Icon(Icons.mic, color: QColors.orange),
                      label: const Text('Tell rescuers exactly where you are'),
                      onPressed: () => _openVoiceOverride(context),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QColors.green,
                      minimumSize: const Size.fromHeight(60),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: const Text("I'M SAFE NOW"),
                    onPressed: () => context.read<QuakeController>().markSafe(),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(end: 1.02, duration: 600.ms),
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
      ),
    );
  }

  void _openVoiceOverride(BuildContext context) {
    final qc = context.read<QuakeController>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceOverrideSheet(
        onConfirmed: (text) => qc.confirmLocationByVoice(text),
      ),
    );
  }
}

class _ConfirmedLocationCard extends StatelessWidget {
  final String note;
  const _ConfirmedLocationCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QColors.green, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: QColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOCATION CONFIRMED BY VOICE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: QColors.green,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '“$note”',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: QColors.brown,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _VoiceOverrideSheet extends StatefulWidget {
  final ValueChanged<String> onConfirmed;
  const _VoiceOverrideSheet({required this.onConfirmed});

  @override
  State<_VoiceOverrideSheet> createState() => _VoiceOverrideSheetState();
}

class _VoiceOverrideSheetState extends State<_VoiceOverrideSheet> {
  bool _listening = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _listening = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: QColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/Quaky_Speech_To_Text.png', width: 96),
          const SizedBox(height: 12),
          if (_listening) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: QColors.orange,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 1, end: 1.9, duration: 1100.ms)
                    .fadeOut(duration: 1100.ms),
                const CircleAvatar(
                  radius: 33,
                  backgroundColor: QColors.orange,
                  child: Icon(Icons.mic, color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Listening… say exactly where you are',
              style: TextStyle(fontSize: 15, color: QColors.brownSoft),
            ),
          ] else ...[
            const Text(
              'HEARD YOU SAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: QColors.brownSoft,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: QColors.orange, width: 2),
              ),
              child: TypingText(
                MockConfig.voiceOverrideTranscript,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: QColors.green,
                minimumSize: const Size.fromHeight(58),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Confirm this location'),
              onPressed: () {
                widget.onConfirmed(MockConfig.voiceOverrideTranscript);
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

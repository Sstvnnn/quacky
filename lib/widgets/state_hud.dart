import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../state/quake_controller.dart';

class _HudEntry {
  final String label;
  final Set<QuakePhase> phases;
  const _HudEntry(this.label, this.phases);
}

class StateHud extends StatefulWidget {
  final QuakePhase phase;
  const StateHud({super.key, required this.phase});

  @override
  State<StateHud> createState() => _StateHudState();
}

class _StateHudState extends State<StateHud> {
  final _scroll = ScrollController();

  static const List<_HudEntry> _entries = [
    _HudEntry('IDLE', {QuakePhase.idle}),
    _HudEntry('DETECT', {QuakePhase.detecting}),
    _HudEntry('CONSENSUS', {QuakePhase.consensus}),
    _HudEntry('ALARM', {QuakePhase.alarm}),
    _HudEntry('GEMINI LIVE', {QuakePhase.geminiLive}),
    _HudEntry('RESULT', {QuakePhase.safe, QuakePhase.sos}),
  ];

  int get _activeIndex =>
      _entries.indexWhere((e) => e.phases.contains(widget.phase));

  @override
  void didUpdateWidget(covariant StateHud old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase && _scroll.hasClients) {
      final target = (_activeIndex * 96.0 - 90)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final e = _entries[i];
          final isActive = i == active;
          final isPast = i < active;
          final chip = AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? QColors.orange
                  : isPast
                      ? QColors.creamDeep
                      : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? QColors.brown : QColors.creamDeep,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                e.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : QColors.brownSoft,
                ),
              ),
            ),
          );
          if (!isActive) return chip;
          return chip
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.06, duration: 500.ms, curve: Curves.easeInOut);
        },
      ),
    );
  }
}

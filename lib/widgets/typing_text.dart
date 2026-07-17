import 'package:flutter/material.dart';

class TypingText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final TextAlign textAlign;

  const TypingText(
    this.text, {
    super.key,
    this.style,
    this.charDelay = const Duration(milliseconds: 40),
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      key: ValueKey(text),
      tween: IntTween(begin: 0, end: text.length),
      duration: charDelay * text.length,
      builder: (context, count, _) => Text(
        text.substring(0, count),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

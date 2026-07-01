import 'dart:async';
import 'package:flutter/material.dart';

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double slideOffset;
  final Duration delay;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.slideOffset = 30.0,
    this.delay = Duration.zero,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> {
  bool _animate = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _animate = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          setState(() {
            _animate = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _animate ? 1.0 : 0.0),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, widget.slideOffset * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

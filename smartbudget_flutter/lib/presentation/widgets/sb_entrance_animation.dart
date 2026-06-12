import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable wrapper widget that applies a premium fade-in and slide-up transition.
class SBEntranceAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset;

  const SBEntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    // Reduced motion: contenido visible de inmediato, sin fade/slide
    // ni staggers (requisito de accesibilidad del flujo).
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    return child
        .animate()
        .fade(delay: delay, duration: duration)
        .slideY(
          begin: slideOffset,
          end: 0.0,
          curve: Curves.easeOutQuad,
        );
  }
}

/// Helper extension on [Widget] to apply the entrance animation cleanly inline.
extension SBEntranceAnimationExtension on Widget {
  Widget animateEntrance({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
    double slideOffset = 0.08,
  }) {
    return SBEntranceAnimation(
      delay: delay,
      duration: duration,
      slideOffset: slideOffset,
      child: this,
    );
  }
}

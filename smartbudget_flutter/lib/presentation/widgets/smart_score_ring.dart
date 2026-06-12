import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SmartScoreRing extends StatefulWidget {
  final int score;
  final double size;

  const SmartScoreRing({
    super.key,
    required this.score,
    this.size = 120.0,
  });

  @override
  State<SmartScoreRing> createState() => _SmartScoreRingState();
}

class _SmartScoreRingState extends State<SmartScoreRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SmartScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double score) {
    if (score >= 71) {
      return AppColors.primaryGreen;
    } else if (score >= 41) {
      return AppColors.warningAmber;
    } else {
      return AppColors.expenseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final strokeColor = _getColor(currentScore);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  score: currentScore,
                  color: strokeColor,
                  backgroundColor: AppColors.dividerGray.withValues(alpha: 0.5),
                  strokeWidth: widget.size * 0.08,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentScore.round()}',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: strokeColor,
                    ),
                  ),
                  Text(
                    '/100',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: widget.size * 0.12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * pi;
    // Start from top (-pi / 2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
    this.shape = BoxShape.rectangle,
  });

  const LoadingShimmer.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  const LoadingShimmer.rect({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
  }) : shape = BoxShape.rectangle;

  factory LoadingShimmer.card({
    Key? key,
    double height = 150.0,
  }) {
    return LoadingShimmer(
      key: key,
      width: double.infinity,
      height: height,
      borderRadius: AppSpacing.radiusLg,
    );
  }

  static Widget listTile({Key? key}) {
    return _ShimmerListTile(key: key);
  }

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.dividerGray,
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.rectangle
                  ? BorderRadius.circular(widget.borderRadius)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerListTile extends StatelessWidget {
  const _ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      child: Row(
        children: [
          const LoadingShimmer.circle(size: 40.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer.rect(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: 14.0,
                ),
                const SizedBox(height: 6.0),
                LoadingShimmer.rect(
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: 10.0,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const LoadingShimmer.rect(width: 70.0, height: 14.0),
        ],
      ),
    );
  }
}

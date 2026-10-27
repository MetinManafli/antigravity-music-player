import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double maxHeight;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 4,
    this.maxHeight = 18,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _randomSeeds = [];

  @override
  void initState() {
    super.initState();
    final random = Random();
    for (int i = 0; i < widget.barCount; i++) {
      _randomSeeds.add(random.nextDouble());
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ?? AppTheme.primaryLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            double value = 0.2;
            if (widget.isPlaying) {
              final phase = (_controller.value + _randomSeeds[index]) % 1.0;
              value = (sin(phase * 2 * pi) + 1) / 2;
              value = value.clamp(0.2, 1.0);
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: widget.maxHeight * value,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

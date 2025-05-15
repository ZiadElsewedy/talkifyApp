import 'package:flutter/material.dart';

/// A modern circular progress indicator that shows loading progress with percentage
class WhiteCircleIndicator extends StatefulWidget {
  /// The size of the circle indicator
  final double size;

  /// The color of the progress indicator
  final Color color;

  /// The background color of the circle
  final Color backgroundColor;

  /// The stroke width of the progress indicator
  final double strokeWidth;

  /// The loading progress (0.0 to 1.0)
  final double? progress;

  const WhiteCircleIndicator({
    Key? key,
    this.size = 45.0,
    this.color = Colors.black,
    this.backgroundColor = Colors.black12,
    this.strokeWidth = 3.0,
    this.progress,
  }) : super(key: key);

  @override
  State<WhiteCircleIndicator> createState() => _WhiteCircleIndicatorState();
}

class _WhiteCircleIndicatorState extends State<WhiteCircleIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.progress == null) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: widget.progress,
            strokeWidth: widget.strokeWidth,
            backgroundColor: widget.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          ),
          // Percentage text
          if (widget.progress != null)
            Text(
              '${(widget.progress! * 100).toInt()}%',
              style: TextStyle(
                color: widget.color,
                fontSize: widget.size * 0.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          // Rotating indicator when no progress
          if (widget.progress == null)
            RotationTransition(
              turns: _animation,
              child: CircularProgressIndicator(
                strokeWidth: widget.strokeWidth,
                backgroundColor: widget.backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
        ],
      ),
    );
  }
}

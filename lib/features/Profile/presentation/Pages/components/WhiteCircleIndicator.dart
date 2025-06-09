import 'package:flutter/material.dart';

/// A modern circular progress indicator that shows loading progress with percentage
class PercentCircleIndicator extends StatefulWidget {
  /// The size of the circle indicator
  final double size;

  /// The color of the progress indicator
  final Color? color;

  /// The background color of the circle
  final Color? backgroundColor;

  /// The stroke width of the progress indicator
  final double strokeWidth;

  /// The loading progress (0.0 to 1.0)
  final double? progress;

  const PercentCircleIndicator({
    Key? key,
    this.size = 45.0,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 3.0,
    this.progress,
  }) : super(key: key);

  @override
  State<PercentCircleIndicator> createState() => _PercentCircleIndicatorState();
}

class _PercentCircleIndicatorState extends State<PercentCircleIndicator>
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color progressColor = widget.color ?? (isDarkMode ? Colors.white : Colors.black);
    final Color bgColor = widget.backgroundColor ?? (isDarkMode ? Colors.white24 : Colors.black12);
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.15),
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
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          // Percentage text
          if (widget.progress != null)
            Text(
              '${(widget.progress! * 100).toInt()}%',
              style: TextStyle(
                color: progressColor,
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
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
        ],
      ),
    );
  }
}

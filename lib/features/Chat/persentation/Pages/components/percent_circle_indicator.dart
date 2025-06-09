import 'package:flutter/material.dart';

/// A circular progress indicator with optional percentage display
class PercentCircleIndicator extends StatelessWidget {
  final double progress;
  final bool showPercentage;
  final double size;
  final Color? color;
  
  const PercentCircleIndicator({
    Key? key,
    this.progress = 0.0,
    this.showPercentage = false,
    this.size = 40.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle or indeterminate progress
          progress > 0 && showPercentage
              ? CircularProgressIndicator(
                  value: progress,
                  color: progressColor,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                )
              : CircularProgressIndicator(
                  color: progressColor,
                ),
          
          // Percentage text
          if (progress > 0 && showPercentage)
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
} 
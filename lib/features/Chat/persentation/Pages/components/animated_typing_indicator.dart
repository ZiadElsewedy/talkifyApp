import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';

class AnimatedTypingIndicator extends StatefulWidget {
  final List<String> typingUserNames;

  const AnimatedTypingIndicator({
    super.key,
    required this.typingUserNames,
  });

  @override
  State<AnimatedTypingIndicator> createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Create staggered animations for the dots
    _dotAnimations = List.generate(
      3,
      (index) => Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUserNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTypingDots(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTypingText(),
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              transform: Matrix4.translationValues(0, -_dotAnimations[index].value, 0),
            ),
          ),
        );
      },
    );
  }

  String _getTypingText() {
    if (widget.typingUserNames.length == 1) {
      return '${widget.typingUserNames[0]} is typing...';
    } else if (widget.typingUserNames.length == 2) {
      return '${widget.typingUserNames[0]} and ${widget.typingUserNames[1]} are typing...';
    } else {
      return '${widget.typingUserNames.length} people are typing...';
    }
  }
} 
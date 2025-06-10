// this is a button that allows the user to follow or unfollow another user
import 'package:flutter/material.dart';

class FollowButton extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final bool isFollowing;
  final Future<void> Function(bool) onFollow;
  final bool isCompact;

  const FollowButton({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.isFollowing,
    required this.onFollow,
    this.isCompact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isLoading = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      setState(() {
        _isFollowing = widget.isFollowing;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onFollow(!_isFollowing);
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final followBg = _isFollowing ? (isDarkMode ? Colors.grey[900]! : Colors.white) : (isDarkMode ? Colors.blue[900]! : Colors.black);
    final followFg = _isFollowing ? (isDarkMode ? Colors.white : Colors.black) : Colors.white;
    final followBorder = _isFollowing ? (isDarkMode ? Colors.grey[700]! : Colors.grey.shade300) : Colors.transparent;
    
    // Adjust size and padding based on compact mode
    final double horizontalPadding = widget.isCompact ? 12 : 20;
    final double verticalPadding = widget.isCompact ? 8 : 12;
    final Size minimumSize = widget.isCompact ? const Size(80, 32) : const Size(120, 40);
    final double iconSize = widget.isCompact ? 14 : 16;
    final double fontSize = widget.isCompact ? 12 : 14;
    final double spacerWidth = widget.isCompact ? 4 : 8;
    
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleFollowToggle,
      style: ElevatedButton.styleFrom(
        backgroundColor: followBg,
        foregroundColor: followFg,
        elevation: widget.isCompact ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
          side: BorderSide(
            color: followBorder,
            width: 1,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        minimumSize: minimumSize,
      ),
      child: _isLoading
          ? SizedBox(
              width: widget.isCompact ? 16 : 20,
              height: widget.isCompact ? 16 : 20,
              child: CircularProgressIndicator(
                strokeWidth: widget.isCompact ? 1.5 : 2,
                valueColor: AlwaysStoppedAnimation<Color>(followFg),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isFollowing ? Icons.check : Icons.add,
                  size: iconSize,
                  color: followFg,
                ),
                SizedBox(width: spacerWidth),
                Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    color: followFg,
                  ),
                ),
              ],
            ),
    );
  }
}

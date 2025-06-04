import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/Utils/audio_handler.dart';
import 'dart:math' as math;

// Custom painter for audio wave pattern
class AudioWavePainter extends CustomPainter {
  final Color color;
  
  AudioWavePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final height = size.height;
    final width = size.width;
    final centerY = height / 2;
    
    // Number of waves to draw
    const int waveCount = 30;
    final double segmentWidth = width / waveCount;
    
    // Start at the left of the canvas
    path.moveTo(0, centerY);
    
    // Create a random but consistent wave pattern
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < waveCount; i++) {
      // Calculate x position for this segment
      final x = i * segmentWidth;
      
      // Calculate a random height for this wave bar
      // Higher probability in the middle for aesthetic appeal
      final double amplitude = (i > waveCount / 3 && i < 2 * waveCount / 3)
          ? random.nextDouble() * height * 0.8
          : random.nextDouble() * height * 0.5;
      
      // Draw bar up from center
      final double topY = math.max(0, centerY - amplitude / 2);
      final double bottomY = math.min(height, centerY + amplitude / 2);
      
      // Draw the vertical bar
      canvas.drawRect(
        Rect.fromLTRB(
          x, 
          topY, 
          x + segmentWidth * 0.7, // Bar width (70% of segment)
          bottomY
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(AudioWavePainter oldDelegate) => color != oldDelegate.color;
}

class AudioMessagePlayer extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  
  const AudioMessagePlayer({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  late AudioPlayer _audioPlayer;
  final _audioHandler = AudioHandler();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    // Get player from global handler using message ID as unique identifier
    _audioPlayer = _audioHandler.getPlayer(widget.message.id);
    _initAudioPlayer();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    // Store a local reference to avoid context access during disposal
    final String messageId = widget.message.id;
    
    // Use Future.microtask to ensure disposal happens after the current frame
    Future.microtask(() {
      // Only dispose if we have a valid ID
      if (messageId.isNotEmpty) {
        _audioHandler.disposePlayer(messageId);
      }
    });
    
    super.dispose();
  }
  
  // Safe setState that checks if the widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }
  
  Future<void> _initAudioPlayer() async {
    if (widget.message.fileUrl == null || widget.message.fileUrl!.isEmpty) {
      return;
    }
    
    try {
      _safeSetState(() {
        _isLoading = true;
      });
      
      // Set the audio source if not already set
      if (_audioPlayer.duration == null) {
        if (!mounted || _isDisposed) return;
        await _audioPlayer.setUrl(widget.message.fileUrl!);
        // Ensure we don't loop audio
        await _audioPlayer.setLoopMode(LoopMode.off);
      }
      
      // Get the duration
      if (!mounted || _isDisposed) return;
      _duration = _audioPlayer.duration ?? Duration.zero;
      
      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        _safeSetState(() {
          _position = position;
        });
      });
      
      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        _safeSetState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _position = Duration.zero;
            // Don't automatically restart playback - just reset position
            if (!_isDisposed) {
              _audioPlayer.pause();
              _audioPlayer.seek(Duration.zero);
            }
          }
        });
      });
      
      _safeSetState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing audio player: $e');
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _playPause() async {
    if (_isDisposed) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Pause all other players before playing this one
      await _audioHandler.pauseAllExcept(widget.message.id);
      await _audioPlayer.play();
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Update colors for dark mode
    Color primaryColor;
    Color bubbleColor;
    Color textColor;
    
    if (isDarkMode) {
      // Dark mode colors
      primaryColor = widget.isCurrentUser ? Colors.white : Colors.grey[300]!;
      bubbleColor = widget.isCurrentUser ? Colors.blue.shade800 : Colors.grey[800]!;
      textColor = Colors.white;
    } else {
      // Light mode colors
      primaryColor = widget.isCurrentUser ? Colors.white : Colors.black;
      bubbleColor = widget.isCurrentUser ? Colors.black : Colors.white;
      textColor = widget.isCurrentUser ? Colors.white : Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio player
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/pause button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying
                      ? primaryColor.withOpacity(0.2)
                      : primaryColor.withOpacity(0.1),
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: primaryColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading ? null : _playPause,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Waveform and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      // Custom audio waveform with slider
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 8,
                          ),
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: widget.isCurrentUser 
                              ? Colors.white24 
                              : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _position.inMilliseconds.toDouble(),
                          min: 0.0,
                          max: _duration.inMilliseconds.toDouble() > 0 
                              ? _duration.inMilliseconds.toDouble() 
                              : 1.0,
                          onChanged: (value) {
                            if (!_isLoading && !_isDisposed) {
                              _audioPlayer.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            }
                          },
                        ),
                      ),
                    
                    // Duration display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/Utils/audio_handler.dart';

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
            if (!_isDisposed) {
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
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isCurrentUser ? Colors.black : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.music_note,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Voice Note',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isCurrentUser ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLoading
                      ? Icons.hourglass_empty
                      : _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                  color: widget.isCurrentUser ? Colors.white : Colors.black,
                  size: 32,
                ),
                onPressed: _isLoading ? null : _playPause,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        activeTrackColor: widget.isCurrentUser 
                            ? Colors.white 
                            : Colors.black,
                        inactiveTrackColor: widget.isCurrentUser 
                            ? Colors.white30 
                            : Colors.grey[300],
                        thumbColor: widget.isCurrentUser 
                            ? Colors.white 
                            : Colors.black,
                        overlayColor: Colors.black12,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isCurrentUser 
                                ? Colors.white70 
                                : Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isCurrentUser 
                                ? Colors.white70 
                                : Colors.grey[600],
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
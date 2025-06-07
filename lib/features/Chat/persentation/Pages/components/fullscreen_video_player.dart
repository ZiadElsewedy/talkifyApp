import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  
  const FullscreenVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.title,
  }) : super(key: key);

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = false;
  bool _isDownloading = false;
  bool _isLandscape = false;
  bool _isBuffering = false;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _isFullscreen = true;
  
  // Available playback speeds
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
    
    // Keep portrait orientation but allow user to rotate if they want
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    
    // Reset to portrait orientation when exiting
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
    super.dispose();
  }

  Future<void> _initializeVideoController() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    
    // Listen for buffering state
    _controller.addListener(() {
      final isBuffering = _controller.value.isBuffering;
      if (isBuffering != _isBuffering && mounted) {
        setState(() {
          _isBuffering = isBuffering;
        });
      }
    });
    
    try {
      await _controller.initialize();
      await _controller.play(); // Auto-play when entering fullscreen
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showControls = true; // Show controls initially
        });
        _startHideControlsTimer();
      }
    } catch (e) {
      print('Error initializing fullscreen video: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
        _startHideControlsTimer();
      }
      _showControls = true;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _controller.setPlaybackSpeed(speed);
    });
    _startHideControlsTimer();
  }

  void _exitFullscreen() {
    Navigator.of(context).pop();
  }

  void _rewind() {
    final newPosition = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPosition);
    _showControls = true;
    _startHideControlsTimer();
    setState(() {});
  }

  void _fastForward() {
    final newPosition = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(newPosition);
    _showControls = true;
    _startHideControlsTimer();
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player positioned in the center
          Center(
            child: _isInitialized
                ? Container(
                    constraints: BoxConstraints(
                      maxWidth: isPortrait ? screenSize.width : double.infinity,
                      maxHeight: isPortrait ? screenSize.height * 0.4 : double.infinity,
                    ),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          
          // Buffering indicator
          if (_isBuffering && _isInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Gesture detector for controls
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Video controls overlay
          if (_showControls)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top bar with title and close button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: _exitFullscreen,
                          ),
                          if (widget.title != null)
                            Expanded(
                              child: Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          IconButton(
                            icon: _isDownloading 
                                ? const SizedBox(
                                    width: 24, 
                                    height: 24, 
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.share, color: Colors.white),
                            onPressed: _isDownloading ? null : () async {
                              try {
                                setState(() {
                                  _isDownloading = true;
                                });
                                
                                // Use Share.share with the URL directly
                                await Share.share(
                                  'Check out this video from Talkify: ${widget.videoUrl}',
                                  subject: 'Video from Talkify',
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Video link shared')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to download: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isDownloading = false;
                                  });
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isLandscape 
                                  ? Icons.stay_current_portrait 
                                  : Icons.stay_current_landscape,
                              color: Colors.white
                            ),
                            tooltip: _isLandscape 
                                ? 'Switch to portrait mode' 
                                : 'Switch to landscape mode',
                            onPressed: () {
                              setState(() {
                                _isLandscape = !_isLandscape;
                                if (_isLandscape) {
                                  SystemChrome.setPreferredOrientations([
                                    DeviceOrientation.landscapeLeft,
                                    DeviceOrientation.landscapeRight,
                                  ]);
                                } else {
                                  SystemChrome.setPreferredOrientations([
                                    DeviceOrientation.portraitUp,
                                    DeviceOrientation.portraitDown,
                                  ]);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              // Show playback speed options
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.black.withOpacity(0.9),
                                builder: (context) => _buildPlaybackSpeedSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacer to push controls to bottom
                    const Spacer(),
                    
                    // Video control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                          onPressed: _rewind,
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 56,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                          onPressed: _fastForward,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Progress bar
                    if (_isInitialized)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Expanded(
                              child: Slider(
                                value: _controller.value.position.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: _controller.value.duration.inMilliseconds.toDouble(),
                                onChanged: (value) {
                                  _controller.seekTo(Duration(milliseconds: value.toInt()));
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.white38,
                                thumbColor: Colors.white,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    
                    // Bottom padding
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybackSpeedSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Playback speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.2)),
          ..._availableSpeeds.map((speed) {
            return ListTile(
              title: Text(
                '${speed}x',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: _playbackSpeed == speed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: _playbackSpeed == speed
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _setPlaybackSpeed(speed);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
} 
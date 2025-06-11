import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class CommunityVoiceNoteRecorder extends StatefulWidget {
  final String chatRoomId;
  final VoidCallback onCancelRecording;
  
  const CommunityVoiceNoteRecorder({
    Key? key,
    required this.chatRoomId,
    required this.onCancelRecording,
  }) : super(key: key);

  @override
  State<CommunityVoiceNoteRecorder> createState() => _CommunityVoiceNoteRecorderState();
}

class _CommunityVoiceNoteRecorderState extends State<CommunityVoiceNoteRecorder> with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSending = false;
  double _uploadProgress = 0.0;
  String _recordingPath = '';
  int _recordDuration = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_animationController);
    _checkPermissionAndStartRecording();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermissionAndStartRecording() async {
    try {
      // Check if microphone permission is granted
      if (await _audioRecorder.hasPermission()) {
        _startRecording();
      } else {
        // Request microphone permission
        final status = await Permission.microphone.request();
        if (status.isGranted) {
          _startRecording();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice notes'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onCancelRecording();
        }
      }
    } catch (e) {
      print('Error checking permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
      widget.onCancelRecording();
    }
  }
  
  Future<void> _startRecording() async {
    try {
      // Get temporary directory for storing the recording
      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = '${tempDir.path}/$fileName';
      
      // Configure audio recorder
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath,
      );
      
      // Start timer to track recording duration
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });
      });
      
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Failed to start recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
      widget.onCancelRecording();
    }
  }
  
  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isSending = true;
      });
      
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording failed or was too short'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onCancelRecording();
        return;
      }
      
      final user = context.read<AuthCubit>().GetCurrentUser();
      if (user != null) {
        final File audioFile = File(path);
        
        if (!audioFile.existsSync() || audioFile.lengthSync() <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording too short or failed'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onCancelRecording();
          return;
        }
        
        // Start upload progress simulation
        _startUploadProgressSimulation();
        
        // Send the audio file
        context.read<ChatCubit>().sendMediaMessage(
          chatRoomId: widget.chatRoomId,
          senderId: user.id,
          senderName: user.name,
          senderAvatar: user.profilePictureUrl,
          filePath: path,
          fileName: 'Voice Note (${_formatDuration(_recordDuration)})',
          type: MessageType.audio,
          metadata: {
            'duration': _recordDuration,
          },
        );
      }
    } catch (e) {
      print('Failed to stop recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send voice note: $e'),
          backgroundColor: Colors.red,
        ),
      );
      widget.onCancelRecording();
    }
  }
  
  void _startUploadProgressSimulation() {
    const totalDuration = Duration(seconds: 3);
    const updateInterval = Duration(milliseconds: 100);
    int steps = totalDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    double progressIncrement = 1.0 / steps;
    
    Timer.periodic(updateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _uploadProgress += progressIncrement;
        if (_uploadProgress >= 1.0) {
          _uploadProgress = 1.0;
          timer.cancel();
          
          // Add a slight delay before dismissing to show 100% completion
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              widget.onCancelRecording();
            }
          });
        }
      });
    });
  }
  
  void _cancelRecording() async {
    _timer?.cancel();
    if (_isRecording) {
      await _audioRecorder.stop();
    }
    widget.onCancelRecording();
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSending) ...[
            const SizedBox(height: 8),
            Text(
              'Sending voice note...',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Recording time
                Text(
                  _formatDuration(_recordDuration),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Cancel button
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: _cancelRecording,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Recording indicator and send button
                GestureDetector(
                  onTap: _stopRecording,
                  child: ScaleTransition(
                    scale: _animation,
                    child: CircularPercentIndicator(
                      radius: 32.0,
                      lineWidth: 4.0,
                      percent: 1.0,
                      center: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: primaryColor,
                        size: 32,
                      ),
                      progressColor: primaryColor,
                      backgroundColor: backgroundColor ?? Colors.grey.shade200,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                      animateFromLastPercent: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to stop recording',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 
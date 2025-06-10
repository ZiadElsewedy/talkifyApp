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
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class VoiceNoteRecorder extends StatefulWidget {
  final String chatRoomId;
  final VoidCallback onCancelRecording;
  
  const VoiceNoteRecorder({
    Key? key,
    required this.chatRoomId,
    required this.onCancelRecording,
  }) : super(key: key);

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> with SingleTickerProviderStateMixin {
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
        
        // Create a simulation of upload progress
        // We'll use this alongside the real upload
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
    // This timer simulates progress updates for a smoother UX
    // The actual upload may finish faster or slower, but this gives visual feedback
    const totalDuration = Duration(seconds: 3); // Adjust based on typical upload time
    const updateInterval = Duration(milliseconds: 100);
    final steps = totalDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    
    double progress = 0.0;
    Timer.periodic(updateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      progress += 1 / steps;
      if (progress >= 1.0) {
        progress = 1.0;
        timer.cancel();
      }
      
      setState(() {
        _uploadProgress = progress;
      });
    });
  }
  
  void _cancelRecording() async {
    _timer?.cancel();
    _timer = null;
    
    try {
      await _audioRecorder.cancel();
    } catch (e) {
      print('Error canceling recording: $e');
    }
    
    widget.onCancelRecording();
  }
  
  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is MessageSent) {
          // Message sent successfully, close the recorder
          widget.onCancelRecording();
        } else if (state is MediaUploadError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send voice note: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onCancelRecording();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isSending 
            ? _buildSendingUI(isDarkMode, colorScheme) 
            : _buildRecordingUI(isDarkMode, colorScheme),
      ),
    );
  }
  
  Widget _buildRecordingUI(bool isDarkMode, ColorScheme colorScheme) {
    return Row(
      children: [
        ScaleTransition(
          scale: _animation,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Recording... ${_formatDuration(_recordDuration)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? colorScheme.onSurface : Colors.black,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.send, 
            color: isDarkMode ? colorScheme.primary : Colors.black,
          ),
          onPressed: _stopRecording,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: _cancelRecording,
        ),
      ],
    );
  }
  
  Widget _buildSendingUI(bool isDarkMode, ColorScheme colorScheme) {
    final progressColor = isDarkMode ? colorScheme.primary : Colors.black;
    final backgroundColor = isDarkMode 
        ? colorScheme.surfaceVariant 
        : Colors.grey.shade300;
    final textColor = isDarkMode ? colorScheme.onSurface : Colors.black;
    
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 20.0,
          lineWidth: 4.0,
          percent: _uploadProgress,
          center: Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          progressColor: progressColor,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Sending voice note...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
} 
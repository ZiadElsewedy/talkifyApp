import 'package:just_audio/just_audio.dart';

/// Global audio handler to manage audio players across the app
class AudioHandler {
  static final AudioHandler _instance = AudioHandler._internal();
  
  factory AudioHandler() => _instance;
  
  AudioHandler._internal();
  
  final Map<String, AudioPlayer> _players = {};
  
  /// Get an existing player or create a new one
  AudioPlayer getPlayer(String id) {
    if (!_players.containsKey(id)) {
      _players[id] = AudioPlayer();
    }
    return _players[id]!;
  }
  
  /// Dispose a specific player
  void disposePlayer(String id) {
    if (_players.containsKey(id)) {
      _players[id]!.dispose();
      _players.remove(id);
    }
  }
  
  /// Dispose all players (called when app is closed or when needed)
  void disposeAllPlayers() {
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
  
  /// Called when a voice note is deleted to ensure its player is disposed
  void handleVoiceNoteDeleted(String messageId) {
    // Dispose the player if it exists
    disposePlayer(messageId);
    
    // Log the cleanup for debugging
    print('AudioHandler: Cleaned up player for deleted voice note ID: $messageId');
  }
} 
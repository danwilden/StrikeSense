import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../models/timer_event.dart';
import 'event_bus.dart';

/// Audio cue types for different timer events
enum AudioCueType {
  roundStart,
  roundEnd,
  warning,
  countdown,
  workStart,
  restStart,
  timerComplete,
  timerPause,
  timerResume,
}

/// Audio service that handles timer audio cues
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<AudioCueType, String> _audioFiles = {
    AudioCueType.roundStart: 'audio/round_start.wav',
    AudioCueType.roundEnd: 'audio/round_end.wav',
    AudioCueType.warning: 'audio/warning.wav',
    AudioCueType.countdown: 'audio/countdown.wav',
    AudioCueType.workStart: 'audio/work_start.wav',
    AudioCueType.restStart: 'audio/rest_start.wav',
    AudioCueType.timerComplete: 'audio/timer_complete.wav',
    AudioCueType.timerPause: 'audio/pause.wav',
    AudioCueType.timerResume: 'audio/resume.wav',
  };

  bool _isInitialized = false;
  bool _isMuted = false;
  double _volume = 0.8;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio player
      await _audioPlayer.setVolume(_volume);

      _isInitialized = true;
      print('AudioService initialized successfully');
    } catch (e) {
      print('Failed to initialize AudioService: $e');
      throw Exception('Failed to initialize AudioService: $e');
    }
  }

  /// Start listening to timer events
  void startListening() {
    if (!_isInitialized) {
      print('AudioService not initialized');
      return;
    }

    // Subscribe to timer events
    EventBus().subscribe(_handleTimerEvent);
    print('AudioService started listening to timer events');
  }

  /// Stop listening to timer events
  void stopListening() {
    EventBus().unsubscribe(_handleTimerEvent);
    print('AudioService stopped listening to timer events');
  }

  /// Handle timer events and play appropriate audio cues
  void _handleTimerEvent(TimerEvent event) {
    if (_isMuted) return;

    switch (event.runtimeType) {
      case TimerStarted:
        _playCue(AudioCueType.roundStart);
        break;
      case TimerPaused:
        _playCue(AudioCueType.timerPause);
        break;
      case TimerResumed:
        _playCue(AudioCueType.timerResume);
        break;
      case TimerStopped:
        _playCue(AudioCueType.timerPause); // Use pause sound for stop
        break;
      case TimerCompleted:
        _playCue(AudioCueType.timerComplete);
        break;
      case RoundStarted:
        final roundStarted = event as RoundStarted;
        if (roundStarted.isWorkPeriod) {
          _playCue(AudioCueType.workStart);
        } else {
          _playCue(AudioCueType.restStart);
        }
        break;
      case RoundEnded:
        _playCue(AudioCueType.roundEnd);
        break;
      case WarningReached:
        _playCue(AudioCueType.warning);
        break;
      case CountdownStarted:
        _playCue(AudioCueType.countdown);
        break;
      case TimerTick:
        // No audio cue for tick events - too frequent
        break;
    }
  }

  /// Play an audio cue
  Future<void> _playCue(AudioCueType cueType) async {
    if (!_isInitialized || _isMuted) return;

    final audioFile = _audioFiles[cueType];
    if (audioFile == null) {
      print('Audio file not found for cue type: $cueType');
      return;
    }

    try {
      // Stop any current playback
      await _audioPlayer.stop();

      // Play the audio cue
      await _audioPlayer.play(AssetSource(audioFile));
      print('Playing audio cue: $cueType');
    } catch (e) {
      print('Failed to play audio cue $cueType: $e');
    }
  }

  /// Set master volume
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_volume);
  }

  /// Mute/unmute audio
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// Check if audio is muted
  bool get isMuted => _isMuted;

  /// Get current volume
  double get volume => _volume;

  /// Play a specific audio cue manually
  Future<void> playCue(AudioCueType cueType) async {
    await _playCue(cueType);
  }

  /// Stop all audio playback
  Future<void> stopAllAudio() async {
    await _audioPlayer.stop();
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopListening();
    await _audioPlayer.dispose();
    _isInitialized = false;
  }
}

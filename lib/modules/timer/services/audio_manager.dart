import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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

/// Audio cue configuration
class AudioCueConfig {
  final String assetPath;
  final double volume;
  final bool enabled;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  const AudioCueConfig({
    required this.assetPath,
    this.volume = 1.0,
    this.enabled = true,
    this.fadeInDuration = Duration.zero,
    this.fadeOutDuration = Duration.zero,
  });
}

/// Audio session configuration for background operation
class AudioSessionConfig {
  final bool allowBackgroundPlayback;
  final bool allowMusicMixing;
  final bool enableAudioDucking;
  final AVAudioSessionCategory category;

  const AudioSessionConfig({
    this.allowBackgroundPlayback = true,
    this.allowMusicMixing = true,
    this.enableAudioDucking = true,
    this.category = AVAudioSessionCategory.playback,
  });
}

/// Manages all audio cues and sound effects for the timer
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<AudioCueType, AudioCueConfig> _cueConfigs = {};
  final Map<AudioCueType, AudioPlayer> _preloadedPlayers = {};

  bool _isInitialized = false;
  bool _isMuted = false;
  double _masterVolume = 1.0;

  /// Initialize the audio manager with default configurations
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio session for background playback
      await _configureAudioSession();

      // Set up default audio cue configurations
      _setupDefaultCueConfigs();

      // Preload audio files
      await _preloadAudioFiles();

      _isInitialized = true;
      debugPrint('AudioManager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AudioManager: $e');
      rethrow;
    }
  }

  /// Configure audio session for background operation
  Future<void> _configureAudioSession() async {
    if (Platform.isIOS) {
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } else if (Platform.isAndroid) {
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    }
  }

  /// Set up default audio cue configurations
  void _setupDefaultCueConfigs() {
    _cueConfigs[AudioCueType.roundStart] = const AudioCueConfig(
      assetPath: 'audio/round_start.wav',
      volume: 0.8,
    );

    _cueConfigs[AudioCueType.roundEnd] = const AudioCueConfig(
      assetPath: 'audio/round_end.wav',
      volume: 0.8,
    );

    _cueConfigs[AudioCueType.warning] = const AudioCueConfig(
      assetPath: 'audio/warning.wav',
      volume: 0.7,
    );

    _cueConfigs[AudioCueType.countdown] = const AudioCueConfig(
      assetPath: 'audio/countdown.wav',
      volume: 0.6,
    );

    _cueConfigs[AudioCueType.workStart] = const AudioCueConfig(
      assetPath: 'audio/work_start.wav',
      volume: 0.8,
    );

    _cueConfigs[AudioCueType.restStart] = const AudioCueConfig(
      assetPath: 'audio/rest_start.wav',
      volume: 0.8,
    );

    _cueConfigs[AudioCueType.timerComplete] = const AudioCueConfig(
      assetPath: 'audio/timer_complete.wav',
      volume: 0.9,
    );

    _cueConfigs[AudioCueType.timerPause] = const AudioCueConfig(
      assetPath: 'audio/pause.wav',
      volume: 0.5,
    );

    _cueConfigs[AudioCueType.timerResume] = const AudioCueConfig(
      assetPath: 'audio/resume.wav',
      volume: 0.5,
    );
  }

  /// Preload audio files for minimal latency
  Future<void> _preloadAudioFiles() async {
    for (final entry in _cueConfigs.entries) {
      final cueType = entry.key;
      final config = entry.value;

      try {
        final player = AudioPlayer();
        await player.setSource(AssetSource(config.assetPath));

        // Add completion handler to prevent hanging
        player.onPlayerComplete.listen((event) {
          debugPrint('Audio cue completed: $cueType');
        });

        _preloadedPlayers[cueType] = player;
        debugPrint('Preloaded audio: ${config.assetPath}');
      } catch (e) {
        debugPrint('Failed to preload audio ${config.assetPath}: $e');
        // Continue with other files even if one fails
      }
    }
  }

  /// Play an audio cue
  Future<void> playCue(AudioCueType cueType) async {
    if (!_isInitialized) {
      debugPrint('AudioManager not initialized');
      return;
    }

    if (_isMuted) return;

    final config = _cueConfigs[cueType];
    if (config == null || !config.enabled) return;

    final player = _preloadedPlayers[cueType];
    if (player == null) {
      debugPrint('Audio player not found for cue type: $cueType');
      return;
    }

    try {
      final volume = _masterVolume * config.volume;
      await player.setVolume(volume);
      await player.stop(); // Stop any current playback

      // Play with timeout to prevent hanging
      await player
          .play(AssetSource(config.assetPath))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Audio playback timeout for cue: $cueType');
            },
          );
      debugPrint('Playing audio cue: $cueType');
    } catch (e) {
      debugPrint('Failed to play audio cue $cueType: $e');
    }
  }

  /// Stop all audio playback
  Future<void> stopAllAudio() async {
    for (final player in _preloadedPlayers.values) {
      try {
        await player.stop();
      } catch (e) {
        debugPrint('Error stopping audio player: $e');
      }
    }
  }

  /// Set master volume (0.0 to 1.0)
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  /// Get current master volume
  double get masterVolume => _masterVolume;

  /// Mute/unmute all audio
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// Check if audio is muted
  bool get isMuted => _isMuted;

  /// Update audio cue configuration
  void updateCueConfig(AudioCueType cueType, AudioCueConfig config) {
    _cueConfigs[cueType] = config;
  }

  /// Get audio cue configuration
  AudioCueConfig? getCueConfig(AudioCueType cueType) {
    return _cueConfigs[cueType];
  }

  /// Update audio session configuration
  Future<void> updateSessionConfig(AudioSessionConfig config) async {
    await _configureAudioSession();
  }

  /// Handle audio session interruption (e.g., phone calls)
  Future<void> handleInterruption() async {
    await stopAllAudio();
    // Reconfigure session after interruption
    await _configureAudioSession();
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopAllAudio();
      for (final player in _preloadedPlayers.values) {
        try {
          await player.dispose();
        } catch (e) {
          debugPrint('Error disposing audio player: $e');
        }
      }
      _preloadedPlayers.clear();
      await _audioPlayer.dispose();
      _isInitialized = false;
      debugPrint('AudioManager disposed successfully');
    } catch (e) {
      debugPrint('Error disposing AudioManager: $e');
    }
  }
}

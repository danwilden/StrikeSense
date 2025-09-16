import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'audio_manager.dart';

/// Audio session interruption types
enum AudioInterruptionType { began, ended, endedWithOptions }

/// Audio session interruption options
class AudioInterruptionOptions {
  final bool shouldResume;
  final bool shouldStop;

  const AudioInterruptionOptions({
    this.shouldResume = false,
    this.shouldStop = false,
  });
}

/// Audio session interruption event
class AudioInterruptionEvent {
  final AudioInterruptionType type;
  final AudioInterruptionOptions? options;

  const AudioInterruptionEvent({required this.type, this.options});
}

/// Manages audio session configuration and interruptions for background operation
class AudioSessionManager {
  static final AudioSessionManager _instance = AudioSessionManager._internal();
  factory AudioSessionManager() => _instance;
  AudioSessionManager._internal();

  final StreamController<AudioInterruptionEvent> _interruptionController =
      StreamController<AudioInterruptionEvent>.broadcast();

  bool _isInitialized = false;
  bool _isInterrupted = false;

  /// Stream of audio interruption events
  Stream<AudioInterruptionEvent> get interruptionEvents =>
      _interruptionController.stream;

  /// Check if audio session is currently interrupted
  bool get isInterrupted => _isInterrupted;

  /// Initialize audio session manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _setupAudioSession();
      await _setupInterruptionHandling();
      _isInitialized = true;
      debugPrint('AudioSessionManager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AudioSessionManager: $e');
      rethrow;
    }
  }

  /// Configure audio session for background operation
  Future<void> _setupAudioSession() async {
    if (Platform.isIOS) {
      await _configureIOSAudioSession();
    } else if (Platform.isAndroid) {
      await _configureAndroidAudioSession();
    }
  }

  /// Configure iOS audio session
  Future<void> _configureIOSAudioSession() async {
    try {
      // Configure audio session for background playback
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
      debugPrint('iOS audio session configured for background playback');
    } catch (e) {
      debugPrint('Failed to configure iOS audio session: $e');
      rethrow;
    }
  }

  /// Configure Android audio session
  Future<void> _configureAndroidAudioSession() async {
    try {
      // Configure audio session for background playback
      await AudioPlayer.global.setAudioContext(
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
      debugPrint('Android audio session configured for background playback');
    } catch (e) {
      debugPrint('Failed to configure Android audio session: $e');
      rethrow;
    }
  }

  /// Set up interruption handling
  Future<void> _setupInterruptionHandling() async {
    if (Platform.isIOS) {
      await _setupIOSInterruptionHandling();
    } else if (Platform.isAndroid) {
      await _setupAndroidInterruptionHandling();
    }
  }

  /// Set up iOS interruption handling
  Future<void> _setupIOSInterruptionHandling() async {
    try {
      // Set up method channel for iOS audio session interruptions
      const MethodChannel channel = MethodChannel(
        'audio_session_interruptions',
      );

      channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'audioInterruptionBegan':
            _handleInterruptionBegan();
            break;
          case 'audioInterruptionEnded':
            final shouldResume =
                call.arguments['shouldResume'] as bool? ?? false;
            _handleInterruptionEnded(shouldResume);
            break;
        }
      });
    } catch (e) {
      debugPrint('Failed to setup iOS interruption handling: $e');
    }
  }

  /// Set up Android interruption handling
  Future<void> _setupAndroidInterruptionHandling() async {
    try {
      // Set up method channel for Android audio focus changes
      const MethodChannel channel = MethodChannel('audio_focus_changes');

      channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'audioFocusLost':
            _handleInterruptionBegan();
            break;
          case 'audioFocusGained':
            _handleInterruptionEnded(true);
            break;
        }
      });
    } catch (e) {
      debugPrint('Failed to setup Android interruption handling: $e');
    }
  }

  /// Handle interruption began
  void _handleInterruptionBegan() {
    _isInterrupted = true;
    _interruptionController.add(
      const AudioInterruptionEvent(type: AudioInterruptionType.began),
    );
    debugPrint('Audio session interrupted');
  }

  /// Handle interruption ended
  void _handleInterruptionEnded(bool shouldResume) {
    _isInterrupted = false;
    _interruptionController.add(
      AudioInterruptionEvent(
        type: AudioInterruptionType.ended,
        options: AudioInterruptionOptions(
          shouldResume: shouldResume,
          shouldStop: !shouldResume,
        ),
      ),
    );
    debugPrint('Audio session interruption ended, shouldResume: $shouldResume');
  }

  /// Update audio session configuration
  Future<void> updateConfiguration(AudioSessionConfig config) async {
    if (Platform.isIOS) {
      await _updateIOSConfiguration(config);
    } else if (Platform.isAndroid) {
      await _updateAndroidConfiguration(config);
    }
  }

  /// Update iOS audio session configuration
  Future<void> _updateIOSConfiguration(AudioSessionConfig config) async {
    try {
      final options = <AVAudioSessionOptions>[];

      if (config.allowMusicMixing) {
        options.add(AVAudioSessionOptions.mixWithOthers);
      }

      if (config.enableAudioDucking) {
        options.add(AVAudioSessionOptions.duckOthers);
      }

      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: config.category,
            options: options.toSet(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to update iOS audio session configuration: $e');
    }
  }

  /// Update Android audio session configuration
  Future<void> _updateAndroidConfiguration(AudioSessionConfig config) async {
    try {
      AndroidAudioFocus audioFocus = AndroidAudioFocus.gain;

      if (config.enableAudioDucking) {
        audioFocus = AndroidAudioFocus.gainTransientMayDuck;
      }

      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: config.allowBackgroundPlayback,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: audioFocus,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to update Android audio session configuration: $e');
    }
  }

  /// Request audio focus (Android)
  Future<bool> requestAudioFocus() async {
    if (Platform.isAndroid) {
      try {
        const MethodChannel channel = MethodChannel('audio_focus');
        final result = await channel.invokeMethod('requestAudioFocus');
        return result as bool? ?? false;
      } catch (e) {
        debugPrint('Failed to request audio focus: $e');
        return false;
      }
    }
    return true; // iOS doesn't need explicit focus request
  }

  /// Abandon audio focus (Android)
  Future<void> abandonAudioFocus() async {
    if (Platform.isAndroid) {
      try {
        const MethodChannel channel = MethodChannel('audio_focus');
        await channel.invokeMethod('abandonAudioFocus');
      } catch (e) {
        debugPrint('Failed to abandon audio focus: $e');
      }
    }
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isInterrupted) {
          _handleInterruptionEnded(true);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Audio session should continue in background
        break;
      case AppLifecycleState.detached:
        await abandonAudioFocus();
        break;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _interruptionController.close();
    await abandonAudioFocus();
    _isInitialized = false;
  }
}

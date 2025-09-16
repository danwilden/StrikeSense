# Audio Cues Implementation

This document describes the audio cues system implemented for the Training Timer module, fulfilling the requirements from Task 2.3.

## Overview

The audio cues system provides audio feedback for timer events including round start/end, warnings, countdown beeps, and other timer state changes. The system is designed to work in both foreground and background modes with proper audio session management.

## Architecture

### Core Components

1. **AudioManager** - Central audio management system
2. **AudioCueService** - Integrates audio cues with timer events
3. **AudioSessionManager** - Handles audio session configuration and interruptions
4. **AudioPreferences** - Manages user audio preferences and settings

### Audio Cue Types

The system supports the following audio cue types:

- `roundStart` - Played when a round starts
- `roundEnd` - Played when a round ends
- `warning` - Played for warnings (e.g., 10 seconds remaining)
- `countdown` - Played for countdown beeps (3, 2, 1 seconds)
- `workStart` - Played when work period starts
- `restStart` - Played when rest period starts
- `timerComplete` - Played when timer completes
- `timerPause` - Played when timer is paused
- `timerResume` - Played when timer is resumed

## Usage

### Basic Integration

```dart
import 'package:strikesense/modules/timer/services/service_locator.dart';
import 'package:strikesense/modules/timer/services/audio_cue_service.dart';

// Initialize services
TimerServiceLocator.initialize();

// Get audio cue service
final audioCueService = TimerServiceLocator.audioCueService;

// Initialize and start listening to timer events
await audioCueService.initialize();
audioCueService.startListening(timerEngine);
```

### Audio Preferences

```dart
import 'package:strikesense/modules/timer/services/audio_preferences.dart';

// Get preferences service
final prefsService = TimerServiceLocator.audioPreferencesService;

// Initialize preferences
await prefsService.initialize();

// Update settings
await prefsService.setMasterVolume(0.8);
await prefsService.setMuted(false);
await prefsService.setCueEnabled(AudioCueType.warning, true);
```

### Manual Audio Cue Playback

```dart
// Play a specific audio cue
audioCueService.playCue(AudioCueType.roundStart);

// Stop all audio
await audioCueService.stopAllAudio();
```

## Audio Assets

### Required Audio Files

Place the following audio files in `assets/audio/`:

- `round_start.wav` - Round start sound
- `round_end.wav` - Round end sound
- `warning.wav` - Warning sound
- `countdown.wav` - Countdown beep
- `work_start.wav` - Work period start
- `rest_start.wav` - Rest period start
- `timer_complete.wav` - Timer completion
- `pause.wav` - Pause sound
- `resume.wav` - Resume sound

### Audio File Specifications

- **Format**: WAV (uncompressed for minimal latency)
- **Sample Rate**: 44.1 kHz
- **Bit Depth**: 16-bit
- **Channels**: Mono or Stereo
- **Duration**: 0.5-2 seconds for quick feedback

## Background Operation

The system is configured for background operation with:

- **iOS**: AVAudioSession with background audio mode
- **Android**: Foreground Service with notification
- **Audio Session Management**: Proper handling of interruptions and focus changes
- **Music Integration**: Audio ducking to work alongside music apps

## Configuration

### Audio Session Configuration

```dart
import 'package:strikesense/modules/timer/services/audio_manager.dart';

final audioManager = TimerServiceLocator.audioManager;

// Configure audio session
await audioManager.updateSessionConfig(AudioSessionConfig(
  allowBackgroundPlayback: true,
  allowMusicMixing: true,
  enableAudioDucking: true,
  category: AVAudioSessionCategory.playback,
));
```

### Audio Cue Configuration

```dart
// Update individual cue settings
audioManager.updateCueConfig(
  AudioCueType.warning,
  AudioCueConfig(
    assetPath: 'audio/custom_warning.wav',
    volume: 0.7,
    enabled: true,
  ),
);
```

## Testing

### Unit Tests

Run the audio cue service tests:

```bash
flutter test test/modules/timer/services/audio_cue_service_test.dart
```

### Integration Testing

Use the provided example to test audio cues:

```dart
import 'package:strikesense/modules/timer/examples/audio_cues_integration_example.dart';

// Navigate to the example screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AudioCuesIntegrationExample(),
  ),
);
```

### Manual Testing Scenarios

1. **Foreground Operation**: Test audio cues while app is in foreground
2. **Background Operation**: Test audio cues while app is in background
3. **Music Integration**: Test with music apps running (Spotify, Apple Music)
4. **Interruption Handling**: Test during phone calls and other audio interruptions
5. **Volume Control**: Test master volume and individual cue volume settings
6. **Mute Functionality**: Test mute/unmute behavior

## Troubleshooting

### Common Issues

1. **Audio files not found**: Ensure audio files are in `assets/audio/` and `pubspec.yaml` includes the assets
2. **Background audio not working**: Check iOS Info.plist for background audio capability
3. **Audio interruptions**: Verify audio session configuration and interruption handling
4. **Volume issues**: Check device volume and app audio settings

### Debug Information

Enable debug logging to troubleshoot audio issues:

```dart
// AudioManager logs initialization and playback events
// AudioSessionManager logs session configuration and interruptions
// AudioCueService logs event handling and cue playback
```

## Future Enhancements

Potential improvements for the audio cues system:

1. **Custom Audio Cues**: Allow users to upload custom audio files
2. **Voice Announcements**: Add text-to-speech for timer announcements
3. **Audio Presets**: Predefined audio configurations for different workout types
4. **Advanced Audio Processing**: Audio effects, equalization, and spatial audio
5. **Accessibility**: Enhanced support for users with hearing impairments

## Dependencies

The audio cues system uses the following packages:

- `audioplayers: ^6.0.0` - Audio playback
- `shared_preferences: ^2.3.2` - Preferences storage
- `get_it: ^7.7.0` - Dependency injection
- `flutter_bloc: ^8.1.6` - State management (for timer events)

## Performance Considerations

- Audio files are preloaded at initialization for minimal latency
- Efficient audio session management prevents battery drain
- Proper resource cleanup prevents memory leaks
- Background operation is optimized for minimal CPU usage

# Audio Cue Specifications

This document describes the audio files generated for the StrikeSense timer audio cues system.

## Generated Audio Files

All audio files are generated as 16-bit mono WAV files at 44.1 kHz sample rate using text-to-speech (TTS).

### File Details

| File                 | Text             | Duration | Purpose        | Description                               |
| -------------------- | ---------------- | -------- | -------------- | ----------------------------------------- |
| `round_start.wav`    | "Round start"    | 0.6s     | Round Start    | Clear spoken announcement for round start |
| `round_end.wav`      | "Round end"      | 0.5s     | Round End      | Clear spoken announcement for round end   |
| `warning.wav`        | "Warning"        | 0.4s     | Warning        | Spoken warning for time alerts            |
| `countdown.wav`      | "Countdown"      | 0.5s     | Countdown      | Spoken countdown announcement             |
| `work_start.wav`     | "Work period"    | 0.6s     | Work Start     | Clear spoken announcement for work period |
| `rest_start.wav`     | "Rest period"    | 0.6s     | Rest Start     | Clear spoken announcement for rest period |
| `timer_complete.wav` | "Timer complete" | 0.8s     | Timer Complete | Spoken completion announcement            |
| `pause.wav`          | "Timer paused"   | 0.7s     | Pause          | Spoken pause notification                 |
| `resume.wav`         | "Timer resumed"  | 0.7s     | Resume         | Spoken resume notification                |

## Audio Design Rationale

### Text-to-Speech Selection

- **Clear, professional voice**: Uses macOS Samantha voice for clarity and consistency
- **Appropriate speech rate**: 200 words per minute for natural, understandable speech
- **Consistent pronunciation**: TTS ensures uniform delivery across all audio cues

### Duration Selection

- **Short (0.4-0.5s)**: Quick announcements for frequent events (warning, countdown)
- **Medium (0.6-0.7s)**: Standard duration for most timer events (round start/end, work/rest, pause/resume)
- **Long (0.8s)**: Extended duration for important events (completion)

### Audio Processing

- **Normalized levels**: All audio files are normalized for consistent playback volume
- **Mono output**: Single channel for compatibility and smaller file sizes
- **Fade effects**: Subtle fade-in/fade-out for smoother audio transitions

## Technical Specifications

- **Format**: WAV (uncompressed)
- **Sample Rate**: 44.1 kHz
- **Bit Depth**: 16-bit
- **Channels**: Mono
- **Encoding**: PCM
- **File Size**: 33-66 KB per file
- **TTS Engine**: macOS `say` command with Samantha voice
- **Speech Rate**: 200 words per minute

## Usage in App

These audio files are automatically loaded by the AudioManager and played by the AudioCueService when corresponding timer events occur:

```dart
// Audio cues are triggered automatically by timer events
timerEngine.start(); // Plays round_start.wav
timerEngine.pause(); // Plays pause.wav
// etc.
```

## Customization

To replace these TTS-generated audio files with custom audio:

1. Create new WAV files with the same names
2. Ensure they meet the technical specifications above
3. Replace the files in the `assets/audio/` directory
4. Run `flutter clean && flutter pub get` to refresh assets

### Regenerating TTS Audio

To regenerate the TTS audio files with different settings:

```bash
# Use default settings (Samantha voice, 200 WPM)
python3 scripts/generate_tts_audio_simple.py

# Use different voice and rate
python3 scripts/generate_tts_audio_simple.py --voice "Alex" --rate 180

# Use different output directory
python3 scripts/generate_tts_audio_simple.py --output-dir custom_audio
```

## Testing

Test the audio cues using the integration example:

```dart
import 'package:strikesense/modules/timer/examples/audio_cues_integration_example.dart';

// Navigate to the example screen to test all audio cues
```

## Future Enhancements

Consider these improvements for production:

1. **Professional Audio Design**: Replace generated tones with professionally designed sounds
2. **Multiple Variations**: Add variations for each cue type to prevent monotony
3. **User Customization**: Allow users to upload their own audio files
4. **Accessibility**: Add visual alternatives for users with hearing impairments
5. **Localization**: Consider cultural preferences for audio cues

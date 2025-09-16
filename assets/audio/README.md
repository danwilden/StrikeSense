# Audio Assets

This directory contains audio files for timer cues and notifications.

## Required Audio Files

The following audio files are required for the timer module:

- `round_start.wav` - Sound played when a round starts
- `round_end.wav` - Sound played when a round ends
- `warning.wav` - Sound played for warnings (e.g., 10 seconds remaining)
- `countdown.wav` - Sound played for countdown beeps (3, 2, 1 seconds)
- `work_start.wav` - Sound played when work period starts
- `rest_start.wav` - Sound played when rest period starts
- `timer_complete.wav` - Sound played when timer completes
- `pause.wav` - Sound played when timer is paused
- `resume.wav` - Sound played when timer is resumed

## Audio File Specifications

- **Format**: WAV (uncompressed for minimal latency)
- **Sample Rate**: 44.1 kHz
- **Bit Depth**: 16-bit
- **Channels**: Mono or Stereo
- **Duration**: Keep files short (0.5-2 seconds) for quick feedback
- **Volume**: Normalize audio levels for consistent playback

## Audio Design Guidelines

1. **Round Start/End**: Clear, distinct sounds that indicate period transitions
2. **Warning**: Attention-grabbing but not jarring sound for time warnings
3. **Countdown**: Short, rhythmic beeps that build anticipation
4. **Work/Rest**: Different tones to clearly distinguish between work and rest periods
5. **Completion**: Celebratory sound that indicates successful completion
6. **Pause/Resume**: Subtle sounds that don't interrupt the workout flow

## Accessibility Considerations

- Ensure audio cues are distinct and easily recognizable
- Consider providing visual alternatives for users with hearing impairments
- Test audio cues with background music to ensure they remain audible
- Provide volume controls and mute options

## Testing

Test audio cues in various scenarios:

- With background music playing
- In silent mode
- With different device volume levels
- In background/foreground app states
- With headphones and speakers

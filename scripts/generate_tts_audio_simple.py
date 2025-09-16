#!/usr/bin/env python3
"""
Simple Text-to-Speech Audio Generator for StrikeSense Timer

This script generates audio files using macOS 'say' command for the StrikeSense timer app.
It's a simpler alternative to the pyttsx3 approach.

Usage:
python3 generate_tts_audio_simple.py
"""

import os
import subprocess
import tempfile
from pathlib import Path
from pydub import AudioSegment
from pydub.effects import normalize
import argparse

class SimpleTTSAudioGenerator:
    def __init__(self, output_dir="assets/audio", voice="Samantha", rate=200):
        """
        Initialize the simple TTS audio generator.
        
        Args:
            output_dir: Directory to save generated audio files
            voice: macOS voice to use (e.g., 'Samantha', 'Alex', 'Victoria')
            rate: Speech rate (words per minute)
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.voice = voice
        self.rate = rate
        
        print(f"Using voice: {voice}")
        print(f"Speech rate: {rate} WPM")
    
    def generate_audio_file(self, text, filename, duration_limit=None):
        """
        Generate an audio file from text using macOS 'say' command.
        
        Args:
            text: Text to convert to speech
            filename: Output filename (without extension)
            duration_limit: Maximum duration in seconds (optional)
        """
        print(f"Generating: {filename}.wav - '{text}'")
        
        # Create temporary file for TTS output
        with tempfile.NamedTemporaryFile(suffix='.aiff', delete=False) as temp_file:
            temp_path = temp_file.name
        
        try:
            # Use macOS 'say' command to generate audio
            cmd = [
                'say',
                '-v', self.voice,
                '-r', str(self.rate),
                '-o', temp_path,
                text
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"  Error: say command failed: {result.stderr}")
                return
            
            # Check if file was created and has content
            if not os.path.exists(temp_path) or os.path.getsize(temp_path) == 0:
                print(f"  Error: TTS failed to generate audio for '{text}'")
                return
            
            # Load and process the audio
            try:
                audio = AudioSegment.from_file(temp_path)
            except Exception as e:
                print(f"  Error loading audio: {e}")
                return
            
            # Normalize audio levels
            audio = normalize(audio)
            
            # Apply duration limit if specified
            if duration_limit and len(audio) > duration_limit * 1000:
                audio = audio[:duration_limit * 1000]
                print(f"  Truncated to {duration_limit}s")
            
            # Convert to mono and set sample rate
            audio = audio.set_channels(1)  # Mono
            audio = audio.set_frame_rate(44100)  # 44.1 kHz
            
            # Apply fade in/out for smoother playback
            if len(audio) > 200:  # Only if long enough
                audio = audio.fade_in(50).fade_out(50)
            
            # Save final audio file
            output_path = self.output_dir / f"{filename}.wav"
            audio.export(output_path, format="wav")
            
            print(f"  Saved: {output_path} ({len(audio)/1000:.1f}s)")
            
        except Exception as e:
            print(f"  Error generating audio: {e}")
        finally:
            # Clean up temporary file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
    
    def generate_all_audio_cues(self):
        """Generate all required audio cues for the StrikeSense timer."""
        
        # Define all audio cues with their text and optional duration limits
        audio_cues = [
            # Core timer events
            ("Round start", "round_start", 1.0),
            ("Round end", "round_end", 1.0),
            ("Timer complete", "timer_complete", 1.5),
            
            # Work/Rest periods
            ("Work period", "work_start", 1.0),
            ("Rest period", "rest_start", 1.0),
            
            # Timer controls
            ("Timer paused", "pause", 0.8),
            ("Timer resumed", "resume", 0.8),
            
            # Warnings and countdown
            ("Warning", "warning", 0.8),
            ("Countdown", "countdown", 0.5),
        ]
        
        print("Generating TTS audio files for StrikeSense timer...")
        print("=" * 50)
        
        for text, filename, duration_limit in audio_cues:
            self.generate_audio_file(text, filename, duration_limit)
        
        print("=" * 50)
        print("All audio files generated successfully!")
        
        # List generated files
        print("\nGenerated files:")
        for file_path in sorted(self.output_dir.glob("*.wav")):
            file_size = file_path.stat().st_size
            print(f"  {file_path.name} ({file_size:,} bytes)")
    
    def test_audio_quality(self):
        """Generate a test audio file to verify quality."""
        print("\nGenerating test audio file...")
        self.generate_audio_file(
            "StrikeSense timer audio test. All systems working correctly.",
            "test_audio",
            3.0
        )
        print("Test audio generated. Play 'test_audio.wav' to verify quality.")

def main():
    parser = argparse.ArgumentParser(description="Generate TTS audio files for StrikeSense using macOS say")
    parser.add_argument("--output-dir", default="assets/audio", 
                       help="Output directory for audio files")
    parser.add_argument("--voice", default="Samantha",
                       help="macOS voice to use (e.g., Samantha, Alex, Victoria)")
    parser.add_argument("--rate", type=int, default=200,
                       help="Speech rate in words per minute")
    parser.add_argument("--test-only", action="store_true",
                       help="Generate only test audio file")
    
    args = parser.parse_args()
    
    try:
        # Initialize generator
        generator = SimpleTTSAudioGenerator(
            output_dir=args.output_dir,
            voice=args.voice,
            rate=args.rate
        )
        
        if args.test_only:
            generator.test_audio_quality()
        else:
            generator.generate_all_audio_cues()
            generator.test_audio_quality()
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nMake sure you have the required dependencies installed:")
        print("pip install pydub numpy")
        sys.exit(1)

if __name__ == "__main__":
    main()

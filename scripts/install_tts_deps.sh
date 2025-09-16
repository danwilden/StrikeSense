#!/bin/bash

# Install Python dependencies for TTS audio generation
# Run this script before using generate_tts_audio.py

echo "Installing Python dependencies for TTS audio generation..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed or not in PATH"
    echo "Please install Python 3 and try again"
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is not installed or not in PATH"
    echo "Please install pip3 and try again"
    exit 1
fi

# Install dependencies
echo "Installing pyttsx3, pydub, and numpy..."
pip3 install -r requirements.txt

echo "Dependencies installed successfully!"
echo ""
echo "You can now run the TTS audio generator:"
echo "python3 generate_tts_audio.py"
echo ""
echo "Or with custom options:"
echo "python3 generate_tts_audio.py --rate 200 --volume 0.9"

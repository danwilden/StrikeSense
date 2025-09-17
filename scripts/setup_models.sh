#!/bin/bash

# StrikeSense Model Setup Script
# Downloads pose estimation models or creates mock models for testing

set -e

echo "🚀 StrikeSense Model Setup"
echo "=========================="

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets/models"

echo "Project root: $PROJECT_ROOT"
echo "Assets directory: $ASSETS_DIR"

# Create assets directory
mkdir -p "$ASSETS_DIR"

# Function to download model with curl
download_model() {
    local url="$1"
    local filename="$2"
    local description="$3"
    local filepath="$ASSETS_DIR/$filename"
    
    echo ""
    echo "📦 Processing $filename..."
    echo "Description: $description"
    
    if [ -f "$filepath" ]; then
        echo "⚠️  File already exists: $filename"
        local size=$(ls -lh "$filepath" | awk '{print $5}')
        echo "   Size: $size"
        read -p "   Download anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   Skipping..."
            return 0
        fi
    fi
    
    echo "Downloading $description..."
    echo "URL: $url"
    echo "Destination: $filepath"
    
    if curl -L --fail --progress-bar -o "$filepath" "$url"; then
        local size=$(ls -lh "$filepath" | awk '{print $5}')
        echo "✅ Successfully downloaded $filename"
        echo "   Size: $size"
        return 0
    else
        echo "❌ Failed to download $filename"
        rm -f "$filepath"  # Remove partial file
        return 1
    fi
}

# Function to create mock model
create_mock_model() {
    local filename="$1"
    local description="$2"
    local filepath="$ASSETS_DIR/$filename"
    
    echo "📝 Creating mock model: $filename"
    
    # Create a more realistic mock model file
    cat > "$filepath" << EOF
# Mock TensorFlow Lite Model: $description
# This is a placeholder file for testing purposes.
# Replace with actual model file for production use.
# 
# Model: $filename
# Description: $description
# Created: $(date)
# 
# This file should be replaced with the actual .tflite model file
# downloaded from TensorFlow Hub or MediaPipe.
EOF
    
    # Add some binary data to make it look more like a real model
    dd if=/dev/urandom bs=1024 count=10 >> "$filepath" 2>/dev/null || true
    
    echo "✅ Created mock model: $filename"
}

# Model configurations
MODELS=(
    "movenet_lightning.tflite|https://tfhub.dev/google/movenet/singlepose/lightning/4?tf-hub-format=compressed|MoveNet Lightning - Fast single pose detection"
    "blazepose_lite.tflite|https://tfhub.dev/mediapipe/tfjs-model/blazepose_3dpose/1?tf-hub-format=compressed|BlazePose Lite - Balanced speed and accuracy"
    "blazepose_full.tflite|https://tfhub.dev/mediapipe/tfjs-model/blazepose_3dpose/1?tf-hub-format=compressed|BlazePose Full - High accuracy pose detection"
)

# Try to download models
success_count=0
total_count=${#MODELS[@]}

for model_info in "${MODELS[@]}"; do
    IFS='|' read -r filename url description <<< "$model_info"
    
    if download_model "$url" "$filename" "$description"; then
        success_count=$((success_count + 1))
    else
        echo "Creating mock model for $filename..."
        create_mock_model "$filename" "$description"
    fi
done

echo ""
echo "📊 Setup Summary:"
echo "   Total models: $total_count"
echo "   Downloaded: $success_count"
echo "   Mock models: $((total_count - success_count))"

echo ""
echo "📁 Models are located in: $ASSETS_DIR"
echo ""
echo "📋 Next steps:"
echo "1. Verify the models are properly included in pubspec.yaml"
echo "2. Test model loading in the app"
echo "3. Replace mock models with real models when available"

# List created files
echo ""
echo "📄 Created files:"
ls -la "$ASSETS_DIR"

echo ""
echo "✅ Model setup complete!"

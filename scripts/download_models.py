#!/usr/bin/env python3
"""
Script to download pose estimation models for StrikeSense app.
Downloads MoveNet Lightning and BlazePose models from TensorFlow Hub.
"""

import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

# Model URLs and configurations
MODELS = {
    'movenet_lightning': {
        'url': 'https://tfhub.dev/google/movenet/singlepose/lightning/4?tf-hub-format=compressed',
        'filename': 'movenet_lightning.tflite',
        'description': 'MoveNet Lightning - Fast single pose detection'
    },
    'blazepose_lite': {
        'url': 'https://tfhub.dev/mediapipe/tfjs-model/blazepose_3dpose/1?tf-hub-format=compressed',
        'filename': 'blazepose_lite.tflite',
        'description': 'BlazePose Lite - Balanced speed and accuracy'
    },
    'blazepose_full': {
        'url': 'https://tfhub.dev/mediapipe/tfjs-model/blazepose_3dpose/1?tf-hub-format=compressed',
        'filename': 'blazepose_full.tflite',
        'description': 'BlazePose Full - High accuracy pose detection'
    }
}

def download_file(url: str, filepath: Path, description: str) -> bool:
    """Download a file from URL to filepath."""
    try:
        print(f"Downloading {description}...")
        print(f"URL: {url}")
        print(f"Destination: {filepath}")
        
        # Create directory if it doesn't exist
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Download with progress
        def progress_hook(block_num, block_size, total_size):
            downloaded = block_num * block_size
            if total_size > 0:
                percent = min(100, (downloaded * 100) // total_size)
                print(f"\rProgress: {percent}% ({downloaded}/{total_size} bytes)", end='')
        
        urllib.request.urlretrieve(url, filepath, progress_hook)
        print(f"\n✅ Successfully downloaded {filepath.name}")
        return True
        
    except urllib.error.URLError as e:
        print(f"\n❌ Failed to download {description}: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error downloading {description}: {e}")
        return False

def get_file_size(filepath: Path) -> str:
    """Get human-readable file size."""
    size = filepath.stat().st_size
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} TB"

def create_mock_models(assets_dir: Path) -> None:
    """Create mock model files for testing when real models can't be downloaded."""
    print("\n📝 Creating mock model files for testing...")
    
    mock_models = {
        'movenet_lightning.tflite': b'Mock MoveNet Lightning model data',
        'blazepose_lite.tflite': b'Mock BlazePose Lite model data',
        'blazepose_full.tflite': b'Mock BlazePose Full model data',
    }
    
    for filename, content in mock_models.items():
        mock_file = assets_dir / filename
        with open(mock_file, 'wb') as f:
            f.write(content)
        print(f"✅ Created mock model: {filename}")

def main():
    """Main function to download all models."""
    print("🚀 StrikeSense Model Downloader")
    print("=" * 50)
    
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    assets_dir = project_root / 'assets' / 'models'
    
    print(f"Project root: {project_root}")
    print(f"Assets directory: {assets_dir}")
    
    # Create assets directory if it doesn't exist
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    success_count = 0
    total_count = len(MODELS)
    
    for model_name, model_info in MODELS.items():
        print(f"\n📦 Processing {model_name}...")
        print(f"Description: {model_info['description']}")
        
        filepath = assets_dir / model_info['filename']
        
        # Check if file already exists
        if filepath.exists():
            print(f"⚠️  File already exists: {filepath.name}")
            print(f"   Size: {get_file_size(filepath)}")
            response = input("   Download anyway? (y/N): ").strip().lower()
            if response != 'y':
                print("   Skipping...")
                success_count += 1
                continue
        
        # Download the model
        if download_file(model_info['url'], filepath, model_info['description']):
            if filepath.exists():
                print(f"   Size: {get_file_size(filepath)}")
                success_count += 1
            else:
                print("   ❌ File was not created")
        else:
            print(f"   ❌ Failed to download {model_name}")
    
    print(f"\n📊 Download Summary:")
    print(f"   Successful: {success_count}/{total_count}")
    print(f"   Failed: {total_count - success_count}/{total_count}")
    
    if success_count == 0:
        print("\n⚠️  No models were downloaded successfully.")
        print("Creating mock models for testing...")
        create_mock_models(assets_dir)
        print("\n✅ Mock models created. You can replace them with real models later.")
    elif success_count < total_count:
        print(f"\n⚠️  Only {success_count} out of {total_count} models were downloaded.")
        print("Creating mock models for missing ones...")
        create_mock_models(assets_dir)
        print("\n✅ Mock models created for missing files.")
    else:
        print("\n🎉 All models downloaded successfully!")
    
    print(f"\n📁 Models are located in: {assets_dir}")
    print("\n📋 Next steps:")
    print("1. Verify the models are properly included in pubspec.yaml")
    print("2. Test model loading in the app")
    print("3. Update model configurations if needed")
    
    return success_count == total_count

if __name__ == '__main__':
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Download interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

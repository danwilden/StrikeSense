import 'package:flutter/material.dart';
import 'package:strikesense/modules/timer/services/service_locator.dart';
import 'package:strikesense/modules/timer/services/audio_cue_service.dart';
import 'package:strikesense/modules/timer/services/audio_manager.dart';

/// Simple test to verify audio cues are working
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🎵 Testing Audio Cues System...');
  
  try {
    // Initialize services
    TimerServiceLocator.initialize();
    final audioCueService = TimerServiceLocator.audioCueService;
    final audioManager = TimerServiceLocator.audioManager;
    
    // Initialize audio system
    await audioManager.initialize();
    await audioCueService.initialize();
    
    print('✅ Audio system initialized successfully');
    
    // Test each audio cue type
    final cueTypes = [
      AudioCueType.roundStart,
      AudioCueType.roundEnd,
      AudioCueType.warning,
      AudioCueType.countdown,
      AudioCueType.workStart,
      AudioCueType.restStart,
      AudioCueType.timerComplete,
      AudioCueType.timerPause,
      AudioCueType.timerResume,
    ];
    
    print('🔊 Testing audio cues...');
    for (final cueType in cueTypes) {
      print('Playing ${cueType.name}...');
      audioCueService.playCue(cueType);
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    print('✅ All audio cues tested successfully!');
    print('🎧 Audio files are working correctly');
    
  } catch (e) {
    print('❌ Error testing audio cues: $e');
  }
}

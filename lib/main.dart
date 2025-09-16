import 'package:flutter/material.dart';

import 'modules/timer/services/audio_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service
  try {
    await AudioService().initialize();
    print('Audio service initialized successfully');
  } catch (e) {
    print('Warning: Failed to initialize audio service: $e');
    // Continue without audio - app will still work
  }

  runApp(const StrikeSenseApp());
}

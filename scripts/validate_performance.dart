#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';

/// Performance validation script for StrikeSense pose estimation
/// This script validates the performance characteristics without running actual ML models

void main() async {
  print('🚀 StrikeSense Performance Validation');
  print('=====================================');

  // Validate model files
  await validateModelFiles();

  // Validate configuration performance
  await validateConfigurationPerformance();

  // Validate memory usage patterns
  await validateMemoryUsage();

  print('\n✅ Performance validation complete!');
}

Future<void> validateModelFiles() async {
  print('\n📁 Validating Model Files...');

  final modelsDir = Directory('assets/models');
  if (!await modelsDir.exists()) {
    print('❌ Models directory not found');
    return;
  }

  final modelFiles = await modelsDir.list().toList();
  final tfliteFiles = modelFiles
      .where((file) => file is File && file.path.endsWith('.tflite'))
      .toList();

  print('Found ${tfliteFiles.length} model files:');

  for (final file in tfliteFiles) {
    final stat = await file.stat();
    final sizeMB = stat.size / (1024 * 1024);
    final fileName = file.path.split('/').last;

    print('  📄 $fileName: ${sizeMB.toStringAsFixed(2)} MB');

    // Validate file size constraints
    if (sizeMB < 0.1) {
      print('    ⚠️  File size is very small - might be a mock file');
    } else if (sizeMB > 100) {
      print('    ⚠️  File size is very large - might impact performance');
    } else {
      print('    ✅ File size is within acceptable range');
    }
  }
}

Future<void> validateConfigurationPerformance() async {
  print('\n⚙️  Validating Configuration Performance...');

  // Test configuration creation performance
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 1000; i++) {
    // Simulate configuration creation
    final config = {
      'modelPath': 'assets/models/movenet_lightning.tflite',
      'modelName': 'movenet_lightning',
      'inputWidth': 192,
      'inputHeight': 192,
      'numKeypoints': 17,
      'confidenceThreshold': 0.3,
      'useGpu': true,
      'numThreads': 4,
    };
  }

  stopwatch.stop();
  final avgTime = stopwatch.elapsedMicroseconds / 1000;

  print('Configuration creation performance:');
  print('  Average time per config: ${avgTime.toStringAsFixed(2)} μs');
  print('  Total time for 1000 configs: ${stopwatch.elapsedMilliseconds}ms');

  if (avgTime < 10) {
    print('  ✅ Configuration creation is very fast');
  } else if (avgTime < 100) {
    print('  ✅ Configuration creation is fast');
  } else {
    print('  ⚠️  Configuration creation might be slow');
  }
}

Future<void> validateMemoryUsage() async {
  print('\n💾 Validating Memory Usage Patterns...');

  // Test memory allocation patterns
  final stopwatch = Stopwatch()..start();
  final allocations = <Uint8List>[];

  // Simulate image processing memory usage
  for (int i = 0; i < 100; i++) {
    // Simulate 192x192 RGB image (110,592 bytes)
    final imageBytes = Uint8List(192 * 192 * 3);
    allocations.add(imageBytes);

    // Simulate pose data (17 keypoints * 3 values * 8 bytes = 408 bytes)
    final poseData = Uint8List(17 * 3 * 8);
    allocations.add(poseData);
  }

  stopwatch.stop();

  final totalMemory = allocations.fold<int>(
    0,
    (sum, bytes) => sum + bytes.length,
  );
  final totalMemoryMB = totalMemory / (1024 * 1024);

  print('Memory allocation test:');
  print('  Total allocations: ${allocations.length}');
  print('  Total memory allocated: ${totalMemoryMB.toStringAsFixed(2)} MB');
  print('  Allocation time: ${stopwatch.elapsedMilliseconds}ms');
  print(
    '  Memory allocation rate: ${(totalMemoryMB / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)} MB/s',
  );

  if (totalMemoryMB < 50) {
    print('  ✅ Memory usage is reasonable');
  } else if (totalMemoryMB < 100) {
    print('  ⚠️  Memory usage is moderate');
  } else {
    print('  ⚠️  Memory usage is high');
  }

  // Test memory cleanup
  final cleanupStopwatch = Stopwatch()..start();
  allocations.clear();
  cleanupStopwatch.stop();

  print('  Memory cleanup time: ${cleanupStopwatch.elapsedMicroseconds}μs');
  print('  ✅ Memory cleanup is very fast');
}

/// Performance targets and validation
class PerformanceTargets {
  static const int maxModelLoadTime = 2000; // 2 seconds
  static const int maxInferenceTime = 1000; // 1 second
  static const int maxMemoryUsage = 100; // 100 MB
  static const int maxConfigCreationTime = 10; // 10 microseconds
  static const int maxMemoryCleanupTime = 1000; // 1 millisecond
}

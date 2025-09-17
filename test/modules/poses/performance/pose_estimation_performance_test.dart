import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:strikesense/modules/poses/services/pose_estimation_service.dart';
import 'package:strikesense/modules/poses/services/model_manager.dart';
import 'package:strikesense/modules/poses/models/pose_estimation_config.dart';

void main() {
  group('Pose Estimation Performance Tests', () {
    late PoseEstimationService poseService;
    late ModelManager modelManager;

    setUp(() {
      poseService = PoseEstimationService.instance;
      modelManager = ModelManager.instance;
    });

    tearDown(() async {
      await poseService.dispose();
      await modelManager.dispose();
    });

    group('Model Loading Performance', () {
      test('should load MoveNet Lightning within performance target', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        final stopwatch = Stopwatch()..start();

        // Act
        await poseService.initialize(config);
        stopwatch.stop();

        // Assert
        expect(poseService.isInitialized, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Target: < 2s
        print(
          'MoveNet Lightning loading time: ${stopwatch.elapsedMilliseconds}ms',
        );
      });

      test('should load BlazePose Lite within performance target', () async {
        // Arrange
        final config = PoseEstimationConfig.blazePoseLite();
        final stopwatch = Stopwatch()..start();

        // Act
        await poseService.initialize(config);
        stopwatch.stop();

        // Assert
        expect(poseService.isInitialized, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Target: < 3s
        print(
          'BlazePose Lite loading time: ${stopwatch.elapsedMilliseconds}ms',
        );
      });

      test('should load BlazePose Full within performance target', () async {
        // Arrange
        final config = PoseEstimationConfig.blazePoseFull();
        final stopwatch = Stopwatch()..start();

        // Act
        await poseService.initialize(config);
        stopwatch.stop();

        // Assert
        expect(poseService.isInitialized, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Target: < 5s
        print(
          'BlazePose Full loading time: ${stopwatch.elapsedMilliseconds}ms',
        );
      });
    });

    group('Inference Performance', () {
      test('should process image within performance target', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);
        final imageBytes = _createTestImageBytes();
        final stopwatch = Stopwatch()..start();

        // Act
        final result = await poseService.processImage(imageBytes);
        stopwatch.stop();

        // Assert
        expect(result, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Target: < 1s
        print('Image processing time: ${stopwatch.elapsedMilliseconds}ms');
      });

      test(
        'should maintain consistent performance over multiple inferences',
        () async {
          // Arrange
          final config = PoseEstimationConfig.moveNetLightning();
          await poseService.initialize(config);
          final imageBytes = _createTestImageBytes();
          final processingTimes = <int>[];

          // Act
          for (int i = 0; i < 10; i++) {
            final stopwatch = Stopwatch()..start();
            await poseService.processImage(imageBytes);
            stopwatch.stop();
            processingTimes.add(stopwatch.elapsedMilliseconds);
          }

          // Assert
          expect(processingTimes.length, equals(10));

          // Calculate statistics
          final avgTime =
              processingTimes.reduce((a, b) => a + b) / processingTimes.length;
          final maxTime = processingTimes.reduce((a, b) => a > b ? a : b);
          final minTime = processingTimes.reduce((a, b) => a < b ? a : b);

          print('Processing time statistics:');
          print('  Average: ${avgTime.toStringAsFixed(2)}ms');
          print('  Min: ${minTime}ms');
          print('  Max: ${maxTime}ms');

          // Performance should be consistent
          expect(avgTime, lessThan(1000)); // Average < 1s
          expect(maxTime, lessThan(2000)); // Max < 2s
          expect(maxTime - minTime, lessThan(1000)); // Variance < 1s
        },
      );
    });

    group('Memory Performance', () {
      test(
        'should handle memory efficiently during multiple initializations',
        () async {
          // Arrange
          final config = PoseEstimationConfig.moveNetLightning();
          final initializationTimes = <int>[];

          // Act
          for (int i = 0; i < 5; i++) {
            final stopwatch = Stopwatch()..start();
            await poseService.initialize(config);
            stopwatch.stop();
            initializationTimes.add(stopwatch.elapsedMilliseconds);

            await poseService.dispose();
            poseService = PoseEstimationService.instance;
          }

          // Assert
          expect(initializationTimes.length, equals(5));

          // Memory should not degrade performance significantly
          final firstTime = initializationTimes.first;
          final lastTime = initializationTimes.last;
          final performanceDegradation = lastTime - firstTime;

          print('Memory performance test:');
          print('  First initialization: ${firstTime}ms');
          print('  Last initialization: ${lastTime}ms');
          print('  Performance degradation: ${performanceDegradation}ms');

          expect(performanceDegradation, lessThan(1000)); // < 1s degradation
        },
      );

      test('should handle large batch processing efficiently', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);
        final batchSize = 50;
        final imageBytes = _createTestImageBytes();
        final stopwatch = Stopwatch()..start();

        // Act
        final results = <dynamic>[];
        for (int i = 0; i < batchSize; i++) {
          final result = await poseService.processImage(imageBytes);
          results.add(result);
        }
        stopwatch.stop();

        // Assert
        expect(results.length, equals(batchSize));
        expect(results.every((result) => result != null), isTrue);

        final avgTimePerImage = stopwatch.elapsedMilliseconds / batchSize;
        print('Batch processing performance:');
        print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
        print('  Average per image: ${avgTimePerImage.toStringAsFixed(2)}ms');
        print(
          '  Images per second: ${(1000 / avgTimePerImage).toStringAsFixed(2)}',
        );

        expect(avgTimePerImage, lessThan(1000)); // < 1s per image
      });
    });

    group('Model Manager Performance', () {
      test('should initialize model manager within performance target', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await modelManager.initialize();
        stopwatch.stop();

        // Assert
        expect(modelManager.isInitialized, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Target: < 3s
        print(
          'Model manager initialization time: ${stopwatch.elapsedMilliseconds}ms',
        );
      });

      test('should switch models within performance target', () async {
        // Arrange
        await modelManager.initialize();
        final stopwatch = Stopwatch()..start();

        // Act
        await modelManager.switchToBlazePoseLite();
        stopwatch.stop();

        // Assert
        expect(modelManager.currentConfig?.modelName, equals('blazepose_lite'));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Target: < 5s
        print('Model switching time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Configuration Performance', () {
      test('should handle configuration updates efficiently', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);
        final stopwatch = Stopwatch()..start();

        // Act
        final updatedConfig = config.copyWith(
          confidenceThreshold: 0.5,
          numThreads: 2,
        );
        await poseService.switchModel(updatedConfig);
        stopwatch.stop();

        // Assert
        expect(poseService.config, equals(updatedConfig));
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Target: < 3s
        print('Configuration update time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Error Handling Performance', () {
      test(
        'should handle errors without significant performance impact',
        () async {
          // Arrange
          final config = PoseEstimationConfig.moveNetLightning();
          await poseService.initialize(config);
          final errorHandlingTimes = <int>[];

          // Act
          for (int i = 0; i < 10; i++) {
            final stopwatch = Stopwatch()..start();
            try {
              await poseService.processImage(Uint8List(0)); // Invalid image
            } catch (e) {
              // Expected to throw
            }
            stopwatch.stop();
            errorHandlingTimes.add(stopwatch.elapsedMilliseconds);
          }

          // Assert
          expect(errorHandlingTimes.length, equals(10));

          final avgErrorTime =
              errorHandlingTimes.reduce((a, b) => a + b) /
              errorHandlingTimes.length;
          print('Error handling performance:');
          print(
            '  Average error handling time: ${avgErrorTime.toStringAsFixed(2)}ms',
          );

          expect(avgErrorTime, lessThan(500)); // < 500ms for error handling
        },
      );
    });
  });
}

/// Helper function to create test image bytes
Uint8List _createTestImageBytes() {
  // Create a simple test image (192x192 RGB)
  final bytes = <int>[];
  for (int i = 0; i < 192 * 192 * 3; i++) {
    bytes.add(i % 256);
  }
  return Uint8List.fromList(bytes);
}

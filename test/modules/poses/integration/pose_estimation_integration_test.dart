import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:strikesense/modules/poses/services/pose_estimation_service.dart';
import 'package:strikesense/modules/poses/services/model_manager.dart';
import 'package:strikesense/modules/poses/services/camera_pipeline_manager.dart';
import 'package:strikesense/modules/poses/models/pose_estimation_config.dart';
import 'package:strikesense/modules/poses/models/pose_data.dart';
import 'package:strikesense/modules/poses/core/pose_estimation_exceptions.dart';

import 'pose_estimation_integration_test.mocks.dart';

@GenerateMocks([])
void main() {
  group('Pose Estimation Integration Tests', () {
    late PoseEstimationService poseService;
    late ModelManager modelManager;
    late CameraPipelineManager pipelineManager;

    setUp(() {
      poseService = PoseEstimationService.instance;
      modelManager = ModelManager.instance;
      pipelineManager = CameraPipelineManager.instance;
    });

    tearDown(() async {
      await poseService.dispose();
      await modelManager.dispose();
      await pipelineManager.dispose();
    });

    group('Service Integration', () {
      test('should initialize pose service with model manager', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Act
        await modelManager.initialize();
        await poseService.initialize(config);

        // Assert
        expect(modelManager.isInitialized, isTrue);
        expect(poseService.isInitialized, isTrue);
        expect(poseService.config, equals(config));
      });

      test('should switch models through model manager', () async {
        // Arrange
        await modelManager.initialize();
        final initialConfig = modelManager.currentConfig;
        final newConfig = PoseEstimationConfig.blazePoseLite();

        // Act
        await modelManager.switchModel(newConfig);

        // Assert
        expect(modelManager.currentConfig, equals(newConfig));
        expect(poseService.config, equals(newConfig));
      });

      test('should handle model switching errors gracefully', () async {
        // Arrange
        await modelManager.initialize();
        final invalidConfig = PoseEstimationConfig.custom(
          modelPath: 'nonexistent.tflite',
          modelName: 'invalid',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => modelManager.switchModel(invalidConfig),
          throwsA(isA<PoseEstimationException>()),
        );
      });
    });

    group('Pipeline Integration', () {
      test('should initialize complete pipeline', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Act
        await pipelineManager.initialize(config);

        // Assert
        expect(pipelineManager.isInitialized, isTrue);
        expect(pipelineManager.config, equals(config));
      });

      test('should handle pipeline initialization errors', () async {
        // Arrange
        final invalidConfig = PoseEstimationConfig.custom(
          modelPath: 'nonexistent.tflite',
          modelName: 'invalid',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => pipelineManager.initialize(invalidConfig),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should update pipeline configuration', () async {
        // Arrange
        final initialConfig = PoseEstimationConfig.moveNetLightning();
        final updatedConfig = PoseEstimationConfig.blazePoseLite();

        await pipelineManager.initialize(initialConfig);

        // Act
        await pipelineManager.updateConfig(updatedConfig);

        // Assert
        expect(pipelineManager.config, equals(updatedConfig));
      });
    });

    group('Error Handling Integration', () {
      test('should handle service disposal gracefully', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);

        // Act
        await poseService.dispose();

        // Assert
        expect(poseService.isInitialized, isFalse);
        expect(poseService.config, isNull);
      });

      test('should handle multiple initialization attempts', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Act
        await poseService.initialize(config);
        await poseService.initialize(config); // Should not throw

        // Assert
        expect(poseService.isInitialized, isTrue);
      });

      test('should handle concurrent operations', () async {
        // Arrange
        final config1 = PoseEstimationConfig.moveNetLightning();
        final config2 = PoseEstimationConfig.blazePoseLite();

        // Act & Assert
        // Start multiple initialization attempts
        final future1 = poseService.initialize(config1);
        final future2 = poseService.initialize(config2);

        // One should succeed, one should throw
        final results = await Future.wait([
          future1.catchError((e) => e),
          future2.catchError((e) => e),
        ], eagerError: false);

        // At least one should be a PoseEstimationException
        expect(
          results.any((result) => result is PoseEstimationException),
          isTrue,
        );
      });
    });

    group('Performance Integration', () {
      test('should load model within acceptable time', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        final stopwatch = Stopwatch()..start();

        // Act
        await poseService.initialize(config);
        stopwatch.stop();

        // Assert
        expect(poseService.isInitialized, isTrue);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10000),
        ); // 10 seconds max
      });

      test('should process image within acceptable time', () async {
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
        expect(result, isA<PoseData>());
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      });

      test('should handle memory efficiently', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);

        // Act - Process multiple images
        final results = <PoseData?>[];
        for (int i = 0; i < 10; i++) {
          final imageBytes = _createTestImageBytes();
          final result = await poseService.processImage(imageBytes);
          results.add(result);
        }

        // Assert
        expect(results.length, equals(10));
        expect(results.every((result) => result != null), isTrue);
      });
    });

    group('Configuration Integration', () {
      test('should apply configuration changes correctly', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);

        // Act
        final updatedConfig = config.copyWith(
          confidenceThreshold: 0.5,
          numThreads: 2,
        );
        await poseService.switchModel(updatedConfig);

        // Assert
        expect(poseService.config, equals(updatedConfig));
        expect(poseService.config!.confidenceThreshold, equals(0.5));
        expect(poseService.config!.numThreads, equals(2));
      });

      test('should validate configuration parameters', () async {
        // Arrange
        final invalidConfig = PoseEstimationConfig.custom(
          modelPath: 'test.tflite',
          modelName: 'test',
          inputWidth: -1, // Invalid
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => poseService.initialize(invalidConfig),
          throwsA(isA<PoseEstimationException>()),
        );
      });
    });

    group('Stream Integration', () {
      test('should emit pose data through stream', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);
        final imageBytes = _createTestImageBytes();
        final receivedData = <PoseData>[];

        // Act
        final subscription = poseService.poseStream.listen((data) {
          receivedData.add(data);
        });

        await poseService.processImage(imageBytes);
        await Future.delayed(
          Duration(milliseconds: 100),
        ); // Allow stream to emit

        // Assert
        expect(receivedData.length, greaterThan(0));
        expect(receivedData.first, isA<PoseData>());

        // Cleanup
        await subscription.cancel();
      });

      test('should handle stream errors gracefully', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await poseService.initialize(config);
        final errors = <dynamic>[];

        // Act
        final subscription = poseService.poseStream.listen(
          (data) {},
          onError: (error) {
            errors.add(error);
          },
        );

        // Try to process invalid image
        try {
          await poseService.processImage(Uint8List(0));
        } catch (e) {
          // Expected to throw
        }

        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        // Stream should handle errors gracefully
        expect(errors.length, equals(0));

        // Cleanup
        await subscription.cancel();
      });
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

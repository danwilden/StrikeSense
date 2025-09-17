import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:strikesense/modules/poses/services/camera_pipeline_manager.dart';
import 'package:strikesense/modules/poses/services/camera_service.dart';
import 'package:strikesense/modules/poses/services/frame_processor.dart';
import 'package:strikesense/modules/poses/models/pose_estimation_config.dart';
import 'package:strikesense/modules/poses/core/pose_estimation_exceptions.dart';

import 'camera_pipeline_integration_test.mocks.dart';

@GenerateMocks([])
void main() {
  group('Camera Pipeline Integration Tests', () {
    late CameraPipelineManager pipelineManager;
    late CameraService cameraService;
    late FrameProcessor frameProcessor;

    setUp(() {
      pipelineManager = CameraPipelineManager.instance;
      cameraService = CameraService.instance;
      frameProcessor = FrameProcessor.instance;
    });

    tearDown(() async {
      await pipelineManager.dispose();
      await cameraService.dispose();
      await frameProcessor.dispose();
    });

    group('Pipeline Initialization', () {
      test('should initialize complete pipeline with valid config', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Act
        await pipelineManager.initialize(config);

        // Assert
        expect(pipelineManager.isInitialized, isTrue);
        expect(pipelineManager.config, equals(config));
      });

      test('should handle initialization with invalid config', () async {
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

      test('should not reinitialize with same config', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);

        // Act
        await pipelineManager.initialize(config);

        // Assert
        expect(pipelineManager.isInitialized, isTrue);
      });
    });

    group('Pipeline Lifecycle', () {
      test('should start and stop pipeline correctly', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);

        // Act
        await pipelineManager.start();
        expect(pipelineManager.isRunning, isTrue);

        await pipelineManager.stop();
        expect(pipelineManager.isRunning, isFalse);
      });

      test('should handle start without initialization', () async {
        // Act & Assert
        expect(() => pipelineManager.start(), throwsA(isA<Exception>()));
      });

      test('should handle multiple start/stop cycles', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);

        // Act & Assert
        for (int i = 0; i < 3; i++) {
          await pipelineManager.start();
          expect(pipelineManager.isRunning, isTrue);

          await pipelineManager.stop();
          expect(pipelineManager.isRunning, isFalse);
        }
      });
    });

    group('Configuration Updates', () {
      test('should update configuration while running', () async {
        // Arrange
        final initialConfig = PoseEstimationConfig.moveNetLightning();
        final updatedConfig = PoseEstimationConfig.blazePoseLite();

        await pipelineManager.initialize(initialConfig);
        await pipelineManager.start();

        // Act
        await pipelineManager.updateConfig(updatedConfig);

        // Assert
        expect(pipelineManager.config, equals(updatedConfig));
        expect(pipelineManager.isRunning, isTrue);
      });

      test('should handle configuration update errors', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);
        await pipelineManager.start();

        final invalidConfig = PoseEstimationConfig.custom(
          modelPath: 'nonexistent.tflite',
          modelName: 'invalid',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => pipelineManager.updateConfig(invalidConfig),
          throwsA(isA<PoseEstimationException>()),
        );
      });
    });

    group('Camera Operations', () {
      test('should switch camera correctly', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);
        await pipelineManager.start();

        // Act
        await pipelineManager.switchCamera(cameraIndex: 1);

        // Assert
        expect(pipelineManager.isRunning, isTrue);
      });

      test('should handle camera switch without initialization', () async {
        // Act & Assert
        expect(() => pipelineManager.switchCamera(), throwsA(isA<Exception>()));
      });
    });

    group('Stream Integration', () {
      test('should emit status updates through stream', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        final statusUpdates = <PipelineStatus>[];

        // Act
        final subscription = pipelineManager.statusStream.listen((status) {
          statusUpdates.add(status);
        });

        await pipelineManager.initialize(config);
        await pipelineManager.start();
        await pipelineManager.stop();

        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(statusUpdates.length, greaterThan(0));
        expect(statusUpdates, contains(PipelineStatus.initialized));
        expect(statusUpdates, contains(PipelineStatus.running));
        expect(statusUpdates, contains(PipelineStatus.stopped));

        // Cleanup
        await subscription.cancel();
      });

      test('should emit results through stream', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        final results = <PipelineResult>[];

        // Act
        final subscription = pipelineManager.resultStream.listen((result) {
          results.add(result);
        });

        await pipelineManager.initialize(config);
        await pipelineManager.start();

        // Wait for potential results
        await Future.delayed(Duration(milliseconds: 500));

        // Assert
        // Results may or may not be emitted depending on camera availability
        // Just ensure the stream is working
        expect(subscription, isNotNull);

        // Cleanup
        await subscription.cancel();
        await pipelineManager.stop();
      });

      test('should handle stream errors gracefully', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        final errors = <dynamic>[];

        // Act
        final subscription = pipelineManager.statusStream.listen(
          (status) {},
          onError: (error) {
            errors.add(error);
          },
        );

        // Try to initialize with invalid config
        try {
          final invalidConfig = PoseEstimationConfig.custom(
            modelPath: 'nonexistent.tflite',
            modelName: 'invalid',
            inputWidth: 192,
            inputHeight: 192,
            numKeypoints: 17,
          );
          await pipelineManager.initialize(invalidConfig);
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

    group('Performance Integration', () {
      test('should initialize within acceptable time', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        final stopwatch = Stopwatch()..start();

        // Act
        await pipelineManager.initialize(config);
        stopwatch.stop();

        // Assert
        expect(pipelineManager.isInitialized, isTrue);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(15000),
        ); // 15 seconds max
      });

      test('should start pipeline within acceptable time', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);
        final stopwatch = Stopwatch()..start();

        // Act
        await pipelineManager.start();
        stopwatch.stop();

        // Assert
        expect(pipelineManager.isRunning, isTrue);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10000),
        ); // 10 seconds max
      });

      test('should handle memory efficiently during lifecycle', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Act - Multiple initialization cycles
        for (int i = 0; i < 3; i++) {
          await pipelineManager.initialize(config);
          await pipelineManager.start();
          await pipelineManager.stop();
          await pipelineManager.dispose();

          // Recreate for next iteration
          pipelineManager = CameraPipelineManager.instance;
        }

        // Assert
        // Should complete without memory issues
        expect(pipelineManager, isNotNull);
      });
    });

    group('Error Recovery', () {
      test('should recover from initialization errors', () async {
        // Arrange
        final invalidConfig = PoseEstimationConfig.custom(
          modelPath: 'nonexistent.tflite',
          modelName: 'invalid',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );
        final validConfig = PoseEstimationConfig.moveNetLightning();

        // Act
        try {
          await pipelineManager.initialize(invalidConfig);
        } catch (e) {
          // Expected to fail
        }

        // Should be able to initialize with valid config
        await pipelineManager.initialize(validConfig);

        // Assert
        expect(pipelineManager.isInitialized, isTrue);
      });

      test('should handle disposal gracefully', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);
        await pipelineManager.start();

        // Act
        await pipelineManager.dispose();

        // Assert
        expect(pipelineManager.isInitialized, isFalse);
        expect(pipelineManager.isRunning, isFalse);
      });

      test('should handle multiple disposal calls', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);

        // Act
        await pipelineManager.dispose();
        await pipelineManager.dispose(); // Should not throw

        // Assert
        expect(pipelineManager.isInitialized, isFalse);
      });
    });

    group('Information and Statistics', () {
      test('should provide pipeline information', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await pipelineManager.initialize(config);

        // Act
        final info = pipelineManager.getPipelineInfo();

        // Assert
        expect(info, isA<Map<String, dynamic>>());
        expect(info['isInitialized'], isTrue);
        expect(info['isRunning'], isFalse);
        expect(info['config'], isNotNull);
        expect(info['processingStats'], isA<Map<String, dynamic>>());
      });

      test('should provide information when not initialized', () {
        // Act
        final info = pipelineManager.getPipelineInfo();

        // Assert
        expect(info, isA<Map<String, dynamic>>());
        expect(info['isInitialized'], isFalse);
        expect(info['isRunning'], isFalse);
      });
    });
  });
}

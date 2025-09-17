import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:strikesense/modules/poses/services/pose_estimation_service.dart';
import 'package:strikesense/modules/poses/models/pose_estimation_config.dart';
import 'package:strikesense/modules/poses/models/pose_data.dart';
import 'package:strikesense/modules/poses/models/pose_keypoint.dart';
import 'package:strikesense/modules/poses/core/pose_estimation_exceptions.dart';

import 'pose_estimation_service_test.mocks.dart';

@GenerateMocks([Interpreter, InterpreterOptions])
void main() {
  group('PoseEstimationService', () {
    late PoseEstimationService service;
    late MockInterpreter mockInterpreter;
    late MockInterpreterOptions mockOptions;

    setUp(() {
      service = PoseEstimationService.instance;
      mockInterpreter = MockInterpreter();
      mockOptions = MockInterpreterOptions();
    });

    tearDown(() async {
      await service.dispose();
    });

    group('Initialization', () {
      test('should initialize with valid configuration', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Act & Assert
        expect(() => service.initialize(config), returnsNormally);
        expect(service.isInitialized, isTrue);
        expect(service.config, equals(config));
      });

      test('should throw exception for invalid configuration', () async {
        // Arrange
        final invalidConfig = PoseEstimationConfig.custom(
          modelPath: '', // Invalid empty path
          modelName: 'test',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => service.initialize(invalidConfig),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should throw exception when already loading', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();

        // Start loading
        final loadingFuture = service.initialize(config);

        // Act & Assert
        expect(
          () => service.initialize(config),
          throwsA(isA<PoseEstimationException>()),
        );

        // Clean up
        await loadingFuture;
      });

      test('should not reinitialize with same model', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await service.initialize(config);

        // Act
        await service.initialize(config);

        // Assert
        expect(service.isInitialized, isTrue);
      });
    });

    group('Configuration Validation', () {
      test('should validate empty model path', () {
        // Arrange
        final config = PoseEstimationConfig.custom(
          modelPath: '',
          modelName: 'test',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => service.initialize(config),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should validate negative input dimensions', () {
        // Arrange
        final config = PoseEstimationConfig.custom(
          modelPath: 'test.tflite',
          modelName: 'test',
          inputWidth: -1,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(
          () => service.initialize(config),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should validate confidence threshold range', () {
        // Arrange
        final config = PoseEstimationConfig.custom(
          modelPath: 'test.tflite',
          modelName: 'test',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          confidenceThreshold: 1.5, // Invalid > 1.0
        );

        // Act & Assert
        expect(
          () => service.initialize(config),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should validate number of threads', () {
        // Arrange
        final config = PoseEstimationConfig.custom(
          modelPath: 'test.tflite',
          modelName: 'test',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          numThreads: 0, // Invalid
        );

        // Act & Assert
        expect(
          () => service.initialize(config),
          throwsA(isA<PoseEstimationException>()),
        );
      });
    });

    group('Image Processing', () {
      setUp(() async {
        final config = PoseEstimationConfig.moveNetLightning();
        await service.initialize(config);
      });

      test('should throw exception when not initialized', () async {
        // Arrange
        await service.dispose();
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

        // Act & Assert
        expect(
          () => service.processImage(imageBytes),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should throw exception for empty image bytes', () async {
        // Arrange
        final emptyBytes = Uint8List(0);

        // Act & Assert
        expect(
          () => service.processImage(emptyBytes),
          throwsA(isA<PoseEstimationException>()),
        );
      });

      test('should process valid image bytes', () async {
        // Arrange
        final imageBytes = _createMockImageBytes();

        // Act
        final result = await service.processImage(imageBytes);

        // Assert
        expect(result, isNotNull);
        expect(result, isA<PoseData>());
      });
    });

    group('Model Information', () {
      test('should return model info when initialized', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await service.initialize(config);

        // Act
        final info = service.getModelInfo();

        // Assert
        expect(info, isA<Map<String, dynamic>>());
        expect(info['modelName'], equals('movenet_lightning'));
        expect(info['isInitialized'], isTrue);
      });

      test('should return error info when not initialized', () {
        // Act
        final info = service.getModelInfo();

        // Assert
        expect(info, isA<Map<String, dynamic>>());
        expect(info['error'], equals('Model not loaded'));
      });
    });

    group('Performance Statistics', () {
      test('should return performance stats', () {
        // Act
        final stats = service.getPerformanceStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['isInitialized'], isA<bool>());
        expect(stats['isLoading'], isA<bool>());
      });
    });

    group('Disposal', () {
      test('should dispose service properly', () async {
        // Arrange
        final config = PoseEstimationConfig.moveNetLightning();
        await service.initialize(config);

        // Act
        await service.dispose();

        // Assert
        expect(service.isInitialized, isFalse);
        expect(service.config, isNull);
      });
    });
  });

  group('PoseEstimationException', () {
    test('should create exception with proper message', () {
      // Arrange
      const message = 'Test error';
      const errorType = PoseEstimationErrorType.modelNotFound;

      // Act
      final exception = PoseEstimationException(message, errorType);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.errorType, equals(errorType));
    });

    test('should include original error', () {
      // Arrange
      const message = 'Test error';
      const errorType = PoseEstimationErrorType.modelNotFound;
      final originalError = Exception('Original error');

      // Act
      final exception = PoseEstimationException(
        message,
        errorType,
        originalError: originalError,
      );

      // Assert
      expect(exception.originalError, equals(originalError));
    });

    test('should provide user-friendly message', () {
      // Arrange
      const errorType = PoseEstimationErrorType.modelNotFound;

      // Act
      final userMessage = errorType.userMessage;

      // Assert
      expect(userMessage, isNotEmpty);
      expect(userMessage, contains('model'));
    });

    test('should indicate if error is recoverable', () {
      // Arrange
      const recoverableError = PoseEstimationErrorType.gpuDelegateFailed;
      const nonRecoverableError = PoseEstimationErrorType.modelNotFound;

      // Act & Assert
      expect(recoverableError.isRecoverable, isTrue);
      expect(nonRecoverableError.isRecoverable, isFalse);
    });

    test('should provide suggested action', () {
      // Arrange
      const errorType = PoseEstimationErrorType.modelNotFound;

      // Act
      final suggestedAction = errorType.suggestedAction;

      // Assert
      expect(suggestedAction, isNotEmpty);
      expect(suggestedAction, contains('model'));
    });
  });
}

/// Helper function to create mock image bytes for testing
Uint8List _createMockImageBytes() {
  // Create a simple 3x3 RGB image (27 bytes)
  final bytes = <int>[];
  for (int i = 0; i < 27; i++) {
    bytes.add(i % 256);
  }
  return Uint8List.fromList(bytes);
}

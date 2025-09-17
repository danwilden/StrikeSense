import 'package:flutter_test/flutter_test.dart';
import 'package:strikesense/modules/poses/models/pose_estimation_config.dart';

void main() {
  group('PoseEstimationConfig', () {
    group('Constructor', () {
      test('should create config with required parameters', () {
        // Act
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Assert
        expect(config.modelPath, equals('test.tflite'));
        expect(config.modelName, equals('test_model'));
        expect(config.inputWidth, equals(192));
        expect(config.inputHeight, equals(192));
        expect(config.numKeypoints, equals(17));
        expect(config.confidenceThreshold, equals(0.3));
        expect(config.useGpu, isTrue);
        expect(config.numThreads, equals(4));
        expect(config.useQuantization, isFalse);
        expect(config.maxPoses, equals(1));
      });

      test('should create config with all parameters', () {
        // Act
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          confidenceThreshold: 0.5,
          useGpu: false,
          numThreads: 2,
          useQuantization: true,
          maxPoses: 2,
        );

        // Assert
        expect(config.confidenceThreshold, equals(0.5));
        expect(config.useGpu, isFalse);
        expect(config.numThreads, equals(2));
        expect(config.useQuantization, isTrue);
        expect(config.maxPoses, equals(2));
      });
    });

    group('Factory Constructors', () {
      test('should create MoveNet Lightning config', () {
        // Act
        final config = PoseEstimationConfig.moveNetLightning();

        // Assert
        expect(
          config.modelPath,
          equals('assets/models/movenet_lightning.tflite'),
        );
        expect(config.modelName, equals('movenet_lightning'));
        expect(config.inputWidth, equals(192));
        expect(config.inputHeight, equals(192));
        expect(config.numKeypoints, equals(17));
        expect(config.confidenceThreshold, equals(0.3));
        expect(config.useGpu, isTrue);
        expect(config.numThreads, equals(4));
        expect(config.useQuantization, isTrue);
        expect(config.maxPoses, equals(1));
      });

      test('should create BlazePose Lite config', () {
        // Act
        final config = PoseEstimationConfig.blazePoseLite();

        // Assert
        expect(config.modelPath, equals('assets/models/blazepose_lite.tflite'));
        expect(config.modelName, equals('blazepose_lite'));
        expect(config.inputWidth, equals(256));
        expect(config.inputHeight, equals(256));
        expect(config.numKeypoints, equals(33));
        expect(config.confidenceThreshold, equals(0.3));
        expect(config.useGpu, isTrue);
        expect(config.numThreads, equals(4));
        expect(config.useQuantization, isTrue);
        expect(config.maxPoses, equals(1));
      });

      test('should create BlazePose Full config', () {
        // Act
        final config = PoseEstimationConfig.blazePoseFull();

        // Assert
        expect(config.modelPath, equals('assets/models/blazepose_full.tflite'));
        expect(config.modelName, equals('blazepose_full'));
        expect(config.inputWidth, equals(256));
        expect(config.inputHeight, equals(256));
        expect(config.numKeypoints, equals(33));
        expect(config.confidenceThreshold, equals(0.3));
        expect(config.useGpu, isTrue);
        expect(config.numThreads, equals(4));
        expect(config.useQuantization, isFalse);
        expect(config.maxPoses, equals(1));
      });

      test('should create custom config', () {
        // Act
        final config = PoseEstimationConfig.custom(
          modelPath: 'custom.tflite',
          modelName: 'custom_model',
          inputWidth: 320,
          inputHeight: 320,
          numKeypoints: 25,
          confidenceThreshold: 0.6,
          useGpu: false,
          numThreads: 1,
          useQuantization: true,
          maxPoses: 3,
        );

        // Assert
        expect(config.modelPath, equals('custom.tflite'));
        expect(config.modelName, equals('custom_model'));
        expect(config.inputWidth, equals(320));
        expect(config.inputHeight, equals(320));
        expect(config.numKeypoints, equals(25));
        expect(config.confidenceThreshold, equals(0.6));
        expect(config.useGpu, isFalse);
        expect(config.numThreads, equals(1));
        expect(config.useQuantization, isTrue);
        expect(config.maxPoses, equals(3));
      });
    });

    group('Computed Properties', () {
      test('should calculate input shape correctly', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act
        final inputShape = config.inputShape;

        // Assert
        expect(inputShape, equals([1, 192, 192, 3]));
      });

      test('should calculate output shape correctly', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act
        final outputShape = config.outputShape;

        // Assert
        expect(outputShape, equals([1, 17, 3]));
      });

      test('should calculate aspect ratio correctly', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act
        final aspectRatio = config.aspectRatio;

        // Assert
        expect(aspectRatio, equals(1.0));
      });

      test('should return GPU support status', () {
        // Arrange
        const configWithGpu = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          useGpu: true,
        );
        const configWithoutGpu = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          useGpu: false,
        );

        // Act & Assert
        expect(configWithGpu.supportsGpu, isTrue);
        expect(configWithoutGpu.supportsGpu, isFalse);
      });
    });

    group('Model Size Classification', () {
      test('should classify MoveNet Lightning as small', () {
        // Act
        final config = PoseEstimationConfig.moveNetLightning();
        final modelSize = config.modelSize;

        // Assert
        expect(modelSize, equals(ModelSize.small));
      });

      test('should classify BlazePose Lite as medium', () {
        // Act
        final config = PoseEstimationConfig.blazePoseLite();
        final modelSize = config.modelSize;

        // Assert
        expect(modelSize, equals(ModelSize.medium));
      });

      test('should classify BlazePose Full as large', () {
        // Act
        final config = PoseEstimationConfig.blazePoseFull();
        final modelSize = config.modelSize;

        // Assert
        expect(modelSize, equals(ModelSize.large));
      });

      test('should classify unknown model as unknown', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'unknown.tflite',
          modelName: 'unknown_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act
        final modelSize = config.modelSize;

        // Assert
        expect(modelSize, equals(ModelSize.unknown));
      });
    });

    group('Performance Category Classification', () {
      test('should classify MoveNet Lightning as fast', () {
        // Act
        final config = PoseEstimationConfig.moveNetLightning();
        final performanceCategory = config.performanceCategory;

        // Assert
        expect(performanceCategory, equals(PerformanceCategory.fast));
      });

      test('should classify BlazePose Lite as balanced', () {
        // Act
        final config = PoseEstimationConfig.blazePoseLite();
        final performanceCategory = config.performanceCategory;

        // Assert
        expect(performanceCategory, equals(PerformanceCategory.balanced));
      });

      test('should classify BlazePose Full as accurate', () {
        // Act
        final config = PoseEstimationConfig.blazePoseFull();
        final performanceCategory = config.performanceCategory;

        // Assert
        expect(performanceCategory, equals(PerformanceCategory.accurate));
      });

      test('should classify unknown model as unknown', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'unknown.tflite',
          modelName: 'unknown_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act
        final performanceCategory = config.performanceCategory;

        // Assert
        expect(performanceCategory, equals(PerformanceCategory.unknown));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        // Arrange
        const original = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act
        final copy = original.copyWith(
          confidenceThreshold: 0.5,
          useGpu: false,
          numThreads: 2,
        );

        // Assert
        expect(copy.modelPath, equals(original.modelPath));
        expect(copy.modelName, equals(original.modelName));
        expect(copy.inputWidth, equals(original.inputWidth));
        expect(copy.inputHeight, equals(original.inputHeight));
        expect(copy.numKeypoints, equals(original.numKeypoints));
        expect(copy.confidenceThreshold, equals(0.5));
        expect(copy.useGpu, isFalse);
        expect(copy.numThreads, equals(2));
        expect(copy.useQuantization, equals(original.useQuantization));
        expect(copy.maxPoses, equals(original.maxPoses));
      });

      test(
        'should create copy with all values unchanged when no parameters provided',
        () {
          // Arrange
          const original = PoseEstimationConfig(
            modelPath: 'test.tflite',
            modelName: 'test_model',
            inputWidth: 192,
            inputHeight: 192,
            numKeypoints: 17,
          );

          // Act
          final copy = original.copyWith();

          // Assert
          expect(copy.modelPath, equals(original.modelPath));
          expect(copy.modelName, equals(original.modelName));
          expect(copy.inputWidth, equals(original.inputWidth));
          expect(copy.inputHeight, equals(original.inputHeight));
          expect(copy.numKeypoints, equals(original.numKeypoints));
          expect(
            copy.confidenceThreshold,
            equals(original.confidenceThreshold),
          );
          expect(copy.useGpu, equals(original.useGpu));
          expect(copy.numThreads, equals(original.numThreads));
          expect(copy.useQuantization, equals(original.useQuantization));
          expect(copy.maxPoses, equals(original.maxPoses));
        },
      );
    });

    group('Serialization', () {
      test('should convert to map', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          confidenceThreshold: 0.5,
          useGpu: false,
          numThreads: 2,
          useQuantization: true,
          maxPoses: 2,
        );

        // Act
        final map = config.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['modelPath'], equals('test.tflite'));
        expect(map['modelName'], equals('test_model'));
        expect(map['inputWidth'], equals(192));
        expect(map['inputHeight'], equals(192));
        expect(map['numKeypoints'], equals(17));
        expect(map['confidenceThreshold'], equals(0.5));
        expect(map['useGpu'], isFalse);
        expect(map['numThreads'], equals(2));
        expect(map['useQuantization'], isTrue);
        expect(map['maxPoses'], equals(2));
      });

      test('should create from map', () {
        // Arrange
        final map = {
          'modelPath': 'test.tflite',
          'modelName': 'test_model',
          'inputWidth': 192,
          'inputHeight': 192,
          'numKeypoints': 17,
          'confidenceThreshold': 0.5,
          'useGpu': false,
          'numThreads': 2,
          'useQuantization': true,
          'maxPoses': 2,
        };

        // Act
        final config = PoseEstimationConfig.fromMap(map);

        // Assert
        expect(config.modelPath, equals('test.tflite'));
        expect(config.modelName, equals('test_model'));
        expect(config.inputWidth, equals(192));
        expect(config.inputHeight, equals(192));
        expect(config.numKeypoints, equals(17));
        expect(config.confidenceThreshold, equals(0.5));
        expect(config.useGpu, isFalse);
        expect(config.numThreads, equals(2));
        expect(config.useQuantization, isTrue);
        expect(config.maxPoses, equals(2));
      });

      test('should handle map with missing values', () {
        // Arrange
        final map = {
          'modelPath': 'test.tflite',
          'modelName': 'test_model',
          'inputWidth': 192,
          'inputHeight': 192,
          'numKeypoints': 17,
          // Missing other values
        };

        // Act
        final config = PoseEstimationConfig.fromMap(map);

        // Assert
        expect(config.modelPath, equals('test.tflite'));
        expect(config.modelName, equals('test_model'));
        expect(config.inputWidth, equals(192));
        expect(config.inputHeight, equals(192));
        expect(config.numKeypoints, equals(17));
        expect(config.confidenceThreshold, equals(0.3)); // Default
        expect(config.useGpu, isTrue); // Default
        expect(config.numThreads, equals(4)); // Default
        expect(config.useQuantization, isFalse); // Default
        expect(config.maxPoses, equals(1)); // Default
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        const config1 = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );
        const config2 = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(config1, equals(config2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        const config1 = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
        );
        const config2 = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 256,
          inputHeight: 192,
          numKeypoints: 17,
        );

        // Act & Assert
        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('should return descriptive string representation', () {
        // Arrange
        const config = PoseEstimationConfig(
          modelPath: 'test.tflite',
          modelName: 'test_model',
          inputWidth: 192,
          inputHeight: 192,
          numKeypoints: 17,
          confidenceThreshold: 0.5,
        );

        // Act
        final string = config.toString();

        // Assert
        expect(string, contains('PoseEstimationConfig'));
        expect(string, contains('model: test_model'));
        expect(string, contains('input: 192x192'));
        expect(string, contains('keypoints: 17'));
        expect(string, contains('confidence: 0.5'));
      });
    });
  });

  group('PoseEstimationPresets', () {
    test('should create boxing training preset', () {
      // Act
      final preset = PoseEstimationPresets.boxingTraining;

      // Assert
      expect(preset.modelName, equals('movenet_lightning'));
      expect(preset.confidenceThreshold, equals(0.4));
      expect(preset.numThreads, equals(2));
    });

    test('should create form analysis preset', () {
      // Act
      final preset = PoseEstimationPresets.formAnalysis;

      // Assert
      expect(preset.modelName, equals('blazepose_lite'));
      expect(preset.confidenceThreshold, equals(0.5));
      expect(preset.numThreads, equals(4));
    });

    test('should create low-end device preset', () {
      // Act
      final preset = PoseEstimationPresets.lowEndDevice;

      // Assert
      expect(preset.modelName, equals('movenet_lightning'));
      expect(preset.useGpu, isFalse);
      expect(preset.numThreads, equals(1));
      expect(preset.useQuantization, isTrue);
    });

    test('should create high-end device preset', () {
      // Act
      final preset = PoseEstimationPresets.highEndDevice;

      // Assert
      expect(preset.modelName, equals('blazepose_full'));
      expect(preset.useGpu, isTrue);
      expect(preset.numThreads, equals(8));
      expect(preset.useQuantization, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:strikesense/modules/poses/models/pose_keypoint.dart';

void main() {
  group('PoseKeypoint', () {
    group('Constructor', () {
      test('should create PoseKeypoint with required parameters', () {
        // Act
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Assert
        expect(keypoint.x, equals(0.5));
        expect(keypoint.y, equals(0.3));
        expect(keypoint.confidence, equals(0.9));
        expect(keypoint.name, equals('nose'));
        expect(keypoint.index, equals(0));
      });
    });

    group('fromModelOutput', () {
      test('should create PoseKeypoint from model output coordinates', () {
        // Arrange
        const coordinates = [0.5, 0.3, 0.9];

        // Act
        final keypoint = PoseKeypoint.fromModelOutput(
          coordinates: coordinates,
          name: 'nose',
          index: 0,
          confidenceThreshold: 0.5,
        );

        // Assert
        expect(keypoint.x, equals(0.5));
        expect(keypoint.y, equals(0.3));
        expect(keypoint.confidence, equals(0.9));
        expect(keypoint.name, equals('nose'));
        expect(keypoint.index, equals(0));
      });

      test('should handle coordinates with missing values', () {
        // Arrange
        const coordinates = [0.5]; // Missing y and confidence

        // Act
        final keypoint = PoseKeypoint.fromModelOutput(
          coordinates: coordinates,
          name: 'nose',
          index: 0,
        );

        // Assert
        expect(keypoint.x, equals(0.5));
        expect(keypoint.y, equals(0.0));
        expect(keypoint.confidence, equals(0.0));
      });

      test('should handle empty coordinates', () {
        // Arrange
        const coordinates = <double>[];

        // Act
        final keypoint = PoseKeypoint.fromModelOutput(
          coordinates: coordinates,
          name: 'nose',
          index: 0,
        );

        // Assert
        expect(keypoint.x, equals(0.0));
        expect(keypoint.y, equals(0.0));
        expect(keypoint.confidence, equals(0.0));
      });
    });

    group('isVisible', () {
      test('should return true when confidence is above threshold', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.8,
          name: 'nose',
          index: 0,
        );

        // Act
        final isVisible = keypoint.isVisible(0.5);

        // Assert
        expect(isVisible, isTrue);
      });

      test('should return false when confidence is below threshold', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.3,
          name: 'nose',
          index: 0,
        );

        // Act
        final isVisible = keypoint.isVisible(0.5);

        // Assert
        expect(isVisible, isFalse);
      });

      test('should return true when confidence equals threshold', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.5,
          name: 'nose',
          index: 0,
        );

        // Act
        final isVisible = keypoint.isVisible(0.5);

        // Assert
        expect(isVisible, isTrue);
      });

      test('should use default threshold of 0.3', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.4,
          name: 'nose',
          index: 0,
        );

        // Act
        final isVisible = keypoint.isVisible();

        // Assert
        expect(isVisible, isTrue);
      });
    });

    group('isValid', () {
      test('should return true for valid coordinates', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final isValid = keypoint.isValid();

        // Assert
        expect(isValid, isTrue);
      });

      test('should return true for boundary coordinates', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 1.0,
          y: 0.0,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final isValid = keypoint.isValid();

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false for negative x coordinate', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: -0.1,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final isValid = keypoint.isValid();

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for x coordinate greater than 1', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 1.1,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final isValid = keypoint.isValid();

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for negative y coordinate', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: -0.1,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final isValid = keypoint.isValid();

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for y coordinate greater than 1', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 1.1,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final isValid = keypoint.isValid();

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        // Arrange
        const original = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final copy = original.copyWith(x: 0.6, confidence: 0.8);

        // Assert
        expect(copy.x, equals(0.6));
        expect(copy.y, equals(0.3)); // Unchanged
        expect(copy.confidence, equals(0.8));
        expect(copy.name, equals('nose')); // Unchanged
        expect(copy.index, equals(0)); // Unchanged
      });

      test(
        'should create copy with all values unchanged when no parameters provided',
        () {
          // Arrange
          const original = PoseKeypoint(
            x: 0.5,
            y: 0.3,
            confidence: 0.9,
            name: 'nose',
            index: 0,
          );

          // Act
          final copy = original.copyWith();

          // Assert
          expect(copy.x, equals(original.x));
          expect(copy.y, equals(original.y));
          expect(copy.confidence, equals(original.confidence));
          expect(copy.name, equals(original.name));
          expect(copy.index, equals(original.index));
        },
      );
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        const keypoint1 = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );
        const keypoint2 = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act & Assert
        expect(keypoint1, equals(keypoint2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        const keypoint1 = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );
        const keypoint2 = PoseKeypoint(
          x: 0.6,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act & Assert
        expect(keypoint1, isNot(equals(keypoint2)));
      });
    });

    group('Serialization', () {
      test('should convert to map', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final map = keypoint.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['x'], equals(0.5));
        expect(map['y'], equals(0.3));
        expect(map['confidence'], equals(0.9));
        expect(map['name'], equals('nose'));
        expect(map['index'], equals(0));
      });

      test('should create from map', () {
        // Arrange
        final map = {
          'x': 0.5,
          'y': 0.3,
          'confidence': 0.9,
          'name': 'nose',
          'index': 0,
        };

        // Act
        final keypoint = PoseKeypointDeserialization.fromMap(map);

        // Assert
        expect(keypoint.x, equals(0.5));
        expect(keypoint.y, equals(0.3));
        expect(keypoint.confidence, equals(0.9));
        expect(keypoint.name, equals('nose'));
        expect(keypoint.index, equals(0));
      });

      test('should handle map with missing values', () {
        // Arrange
        final map = {
          'x': 0.5,
          'name': 'nose',
          // Missing y, confidence, index
        };

        // Act
        final keypoint = PoseKeypointDeserialization.fromMap(map);

        // Assert
        expect(keypoint.x, equals(0.5));
        expect(keypoint.y, equals(0.0));
        expect(keypoint.confidence, equals(0.0));
        expect(keypoint.name, equals('nose'));
        expect(keypoint.index, equals(0));
      });
    });

    group('toString', () {
      test('should return descriptive string representation', () {
        // Arrange
        const keypoint = PoseKeypoint(
          x: 0.5,
          y: 0.3,
          confidence: 0.9,
          name: 'nose',
          index: 0,
        );

        // Act
        final string = keypoint.toString();

        // Assert
        expect(string, contains('PoseKeypoint'));
        expect(string, contains('name: nose'));
        expect(string, contains('x: 0.5'));
        expect(string, contains('y: 0.3'));
        expect(string, contains('confidence: 0.9'));
      });
    });
  });

  group('PoseKeypointNames', () {
    test('should contain all MoveNet keypoints', () {
      // Assert
      expect(PoseKeypointNames.moveNetKeypoints.length, equals(17));
      expect(PoseKeypointNames.moveNetKeypoints, contains('nose'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_eye'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_eye'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_shoulder'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_shoulder'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_elbow'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_elbow'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_wrist'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_wrist'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_hip'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_hip'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_knee'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_knee'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('left_ankle'));
      expect(PoseKeypointNames.moveNetKeypoints, contains('right_ankle'));
    });

    test('should contain upper body keypoints', () {
      // Assert
      expect(PoseKeypointNames.upperBodyKeypoints, contains('nose'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('left_eye'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('right_eye'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('left_shoulder'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('right_shoulder'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('left_elbow'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('right_elbow'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('left_wrist'));
      expect(PoseKeypointNames.upperBodyKeypoints, contains('right_wrist'));

      // Should not contain lower body keypoints
      expect(PoseKeypointNames.upperBodyKeypoints, isNot(contains('left_hip')));
      expect(
        PoseKeypointNames.upperBodyKeypoints,
        isNot(contains('right_hip')),
      );
      expect(
        PoseKeypointNames.upperBodyKeypoints,
        isNot(contains('left_knee')),
      );
      expect(
        PoseKeypointNames.upperBodyKeypoints,
        isNot(contains('right_knee')),
      );
      expect(
        PoseKeypointNames.upperBodyKeypoints,
        isNot(contains('left_ankle')),
      );
      expect(
        PoseKeypointNames.upperBodyKeypoints,
        isNot(contains('right_ankle')),
      );
    });

    test('should contain lower body keypoints', () {
      // Assert
      expect(PoseKeypointNames.lowerBodyKeypoints, contains('left_hip'));
      expect(PoseKeypointNames.lowerBodyKeypoints, contains('right_hip'));
      expect(PoseKeypointNames.lowerBodyKeypoints, contains('left_knee'));
      expect(PoseKeypointNames.lowerBodyKeypoints, contains('right_knee'));
      expect(PoseKeypointNames.lowerBodyKeypoints, contains('left_ankle'));
      expect(PoseKeypointNames.lowerBodyKeypoints, contains('right_ankle'));

      // Should not contain upper body keypoints
      expect(PoseKeypointNames.lowerBodyKeypoints, isNot(contains('nose')));
      expect(PoseKeypointNames.lowerBodyKeypoints, isNot(contains('left_eye')));
      expect(
        PoseKeypointNames.lowerBodyKeypoints,
        isNot(contains('right_eye')),
      );
      expect(
        PoseKeypointNames.lowerBodyKeypoints,
        isNot(contains('left_shoulder')),
      );
      expect(
        PoseKeypointNames.lowerBodyKeypoints,
        isNot(contains('right_shoulder')),
      );
    });
  });
}

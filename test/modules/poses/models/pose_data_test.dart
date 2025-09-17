import 'package:flutter_test/flutter_test.dart';
import 'package:strikesense/modules/poses/models/pose_data.dart';
import 'package:strikesense/modules/poses/models/pose_keypoint.dart';

void main() {
  group('PoseData', () {
    late List<PoseKeypoint> mockKeypoints;

    setUp(() {
      mockKeypoints = [
        PoseKeypoint(x: 0.5, y: 0.3, confidence: 0.9, name: 'nose', index: 0),
        PoseKeypoint(
          x: 0.4,
          y: 0.2,
          confidence: 0.8,
          name: 'left_eye',
          index: 1,
        ),
        PoseKeypoint(
          x: 0.6,
          y: 0.2,
          confidence: 0.7,
          name: 'right_eye',
          index: 2,
        ),
        PoseKeypoint(
          x: 0.3,
          y: 0.4,
          confidence: 0.2, // Below threshold
          name: 'left_shoulder',
          index: 3,
        ),
        PoseKeypoint(
          x: 0.7,
          y: 0.4,
          confidence: 0.6,
          name: 'right_shoulder',
          index: 4,
        ),
      ];
    });

    group('Constructor', () {
      test('should create PoseData with required parameters', () {
        // Act
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Assert
        expect(poseData.keypoints, equals(mockKeypoints));
        expect(poseData.timestamp, equals(1234567890.0));
        expect(poseData.modelVersion, equals('test_model'));
        expect(poseData.confidenceThreshold, equals(0.3));
        expect(poseData.imageWidth, equals(0));
        expect(poseData.imageHeight, equals(0));
      });

      test('should create PoseData with all parameters', () {
        // Act
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
          imageWidth: 640,
          imageHeight: 480,
        );

        // Assert
        expect(poseData.confidenceThreshold, equals(0.5));
        expect(poseData.imageWidth, equals(640));
        expect(poseData.imageHeight, equals(480));
      });
    });

    group('fromModelOutput', () {
      test('should create PoseData from raw model output', () {
        // Arrange
        final rawKeypoints = [
          [0.5, 0.3, 0.9], // nose
          [0.4, 0.2, 0.8], // left_eye
          [0.6, 0.2, 0.7], // right_eye
        ];

        // Act
        final poseData = PoseData.fromModelOutput(
          rawKeypoints: rawKeypoints,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
          imageWidth: 640,
          imageHeight: 480,
        );

        // Assert
        expect(poseData.keypoints.length, equals(3));
        expect(poseData.modelVersion, equals('test_model'));
        expect(poseData.confidenceThreshold, equals(0.5));
        expect(poseData.imageWidth, equals(640));
        expect(poseData.imageHeight, equals(480));
        expect(poseData.keypoints[0].name, equals('nose'));
        expect(poseData.keypoints[0].x, equals(0.5));
        expect(poseData.keypoints[0].y, equals(0.3));
        expect(poseData.keypoints[0].confidence, equals(0.9));
      });
    });

    group('visibleKeypoints', () {
      test('should return only keypoints above confidence threshold', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final visible = poseData.visibleKeypoints;

        // Assert
        expect(visible.length, equals(4)); // 4 keypoints above 0.5 threshold
        expect(visible.every((kp) => kp.confidence >= 0.5), isTrue);
      });

      test('should return empty list when no keypoints meet threshold', () {
        // Arrange
        final lowConfidenceKeypoints = mockKeypoints
            .map((kp) => kp.copyWith(confidence: 0.1))
            .toList();

        final poseData = PoseData(
          keypoints: lowConfidenceKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final visible = poseData.visibleKeypoints;

        // Assert
        expect(visible, isEmpty);
      });
    });

    group('getKeypointsByGroup', () {
      test('should return keypoints matching specified names', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final eyeKeypoints = poseData.getKeypointsByGroup([
          'left_eye',
          'right_eye',
        ]);

        // Assert
        expect(eyeKeypoints.length, equals(2));
        expect(eyeKeypoints.any((kp) => kp.name == 'left_eye'), isTrue);
        expect(eyeKeypoints.any((kp) => kp.name == 'right_eye'), isTrue);
      });

      test('should return empty list for non-matching names', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final nonMatching = poseData.getKeypointsByGroup(['non_existent']);

        // Assert
        expect(nonMatching, isEmpty);
      });
    });

    group('upperBodyKeypoints', () {
      test('should return upper body keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final upperBody = poseData.upperBodyKeypoints;

        // Assert
        expect(upperBody.isNotEmpty, isTrue);
        expect(
          upperBody.every(
            (kp) => PoseKeypointNames.upperBodyKeypoints.contains(kp.name),
          ),
          isTrue,
        );
      });
    });

    group('getKeypointByName', () {
      test('should return keypoint with matching name', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final noseKeypoint = poseData.getKeypointByName('nose');

        // Assert
        expect(noseKeypoint, isNotNull);
        expect(noseKeypoint!.name, equals('nose'));
        expect(noseKeypoint.x, equals(0.5));
        expect(noseKeypoint.y, equals(0.3));
      });

      test('should return null for non-existent keypoint', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final nonExistent = poseData.getKeypointByName('non_existent');

        // Assert
        expect(nonExistent, isNull);
      });
    });

    group('centerPoint', () {
      test('should calculate center point from visible keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final center = poseData.centerPoint;

        // Assert
        expect(center, isNotNull);
        expect(center!.name, equals('center'));
        expect(center.x, greaterThan(0));
        expect(center.y, greaterThan(0));
        expect(center.confidence, greaterThan(0));
      });

      test('should return null when no visible keypoints', () {
        // Arrange
        final lowConfidenceKeypoints = mockKeypoints
            .map((kp) => kp.copyWith(confidence: 0.1))
            .toList();

        final poseData = PoseData(
          keypoints: lowConfidenceKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final center = poseData.centerPoint;

        // Assert
        expect(center, isNull);
      });
    });

    group('boundingBox', () {
      test('should calculate bounding box from visible keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final boundingBox = poseData.boundingBox;

        // Assert
        expect(boundingBox, isNotNull);
        expect(boundingBox!['x'], isA<double>());
        expect(boundingBox['y'], isA<double>());
        expect(boundingBox['width'], isA<double>());
        expect(boundingBox['height'], isA<double>());
        expect(boundingBox['width'], greaterThan(0));
        expect(boundingBox['height'], greaterThan(0));
      });

      test('should return null when no visible keypoints', () {
        // Arrange
        final lowConfidenceKeypoints = mockKeypoints
            .map((kp) => kp.copyWith(confidence: 0.1))
            .toList();

        final poseData = PoseData(
          keypoints: lowConfidenceKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final boundingBox = poseData.boundingBox;

        // Assert
        expect(boundingBox, isNull);
      });
    });

    group('isValid', () {
      test('should return true when enough visible keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final isValid = poseData.isValid(3);

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false when not enough visible keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final isValid = poseData.isValid(10);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('averageConfidence', () {
      test('should calculate average confidence of all keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final avgConfidence = poseData.averageConfidence;

        // Assert
        expect(avgConfidence, isA<double>());
        expect(avgConfidence, greaterThan(0));
        expect(avgConfidence, lessThanOrEqualTo(1));
      });

      test('should return 0 for empty keypoints', () {
        // Arrange
        final poseData = PoseData(
          keypoints: [],
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final avgConfidence = poseData.averageConfidence;

        // Assert
        expect(avgConfidence, equals(0.0));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        // Arrange
        final original = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act
        final copy = original.copyWith(
          timestamp: 9876543210.0,
          confidenceThreshold: 0.7,
        );

        // Assert
        expect(copy.keypoints, equals(original.keypoints));
        expect(copy.timestamp, equals(9876543210.0));
        expect(copy.modelVersion, equals(original.modelVersion));
        expect(copy.confidenceThreshold, equals(0.7));
        expect(copy.imageWidth, equals(original.imageWidth));
        expect(copy.imageHeight, equals(original.imageHeight));
      });
    });

    group('Serialization', () {
      test('should convert to map', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
          imageWidth: 640,
          imageHeight: 480,
        );

        // Act
        final map = poseData.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['timestamp'], equals(1234567890.0));
        expect(map['modelVersion'], equals('test_model'));
        expect(map['confidenceThreshold'], equals(0.5));
        expect(map['imageWidth'], equals(640));
        expect(map['imageHeight'], equals(480));
        expect(map['keypoints'], isA<List>());
        expect(map['keypoints'].length, equals(mockKeypoints.length));
      });

      test('should create from map', () {
        // Arrange
        final map = {
          'keypoints': mockKeypoints.map((kp) => kp.toMap()).toList(),
          'timestamp': 1234567890.0,
          'modelVersion': 'test_model',
          'confidenceThreshold': 0.5,
          'imageWidth': 640,
          'imageHeight': 480,
        };

        // Act
        final poseData = PoseData.fromMap(map);

        // Assert
        expect(poseData.keypoints.length, equals(mockKeypoints.length));
        expect(poseData.timestamp, equals(1234567890.0));
        expect(poseData.modelVersion, equals('test_model'));
        expect(poseData.confidenceThreshold, equals(0.5));
        expect(poseData.imageWidth, equals(640));
        expect(poseData.imageHeight, equals(480));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final poseData1 = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );
        final poseData2 = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );

        // Act & Assert
        expect(poseData1, equals(poseData2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final poseData1 = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
        );
        final poseData2 = PoseData(
          keypoints: mockKeypoints,
          timestamp: 9876543210.0,
          modelVersion: 'test_model',
        );

        // Act & Assert
        expect(poseData1, isNot(equals(poseData2)));
      });
    });

    group('toString', () {
      test('should return descriptive string representation', () {
        // Arrange
        final poseData = PoseData(
          keypoints: mockKeypoints,
          timestamp: 1234567890.0,
          modelVersion: 'test_model',
          confidenceThreshold: 0.5,
        );

        // Act
        final string = poseData.toString();

        // Assert
        expect(string, contains('PoseData'));
        expect(string, contains('keypoints: ${mockKeypoints.length}'));
        expect(string, contains('visible:'));
        expect(string, contains('confidence:'));
        expect(string, contains('timestamp:'));
      });
    });
  });
}

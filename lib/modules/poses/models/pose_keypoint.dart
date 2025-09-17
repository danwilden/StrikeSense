import 'package:equatable/equatable.dart';

/// Types of pose keypoints supported by ML Kit (33 landmarks)
enum PoseKeypointType {
  // Face landmarks
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  mouth,

  // Upper body landmarks
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,

  // Hand landmarks
  leftPinky,
  rightPinky,
  leftIndex,
  rightIndex,
  leftThumb,
  rightThumb,

  // Lower body landmarks
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

/// Represents a single keypoint in a pose estimation result
class PoseKeypoint extends Equatable {
  /// X coordinate of the keypoint (0.0 to 1.0, relative to image width)
  final double x;

  /// Y coordinate of the keypoint (0.0 to 1.0, relative to image height)
  final double y;

  /// Confidence score of the keypoint detection (0.0 to 1.0)
  final double confidence;

  /// Type of the keypoint
  final PoseKeypointType type;

  /// Name/identifier of the keypoint (e.g., 'nose', 'left_shoulder')
  final String name;

  /// Index of the keypoint in the model output
  final int index;

  const PoseKeypoint({
    required this.x,
    required this.y,
    required this.confidence,
    required this.type,
    required this.name,
    required this.index,
  });

  /// Creates a PoseKeypoint from raw model output
  factory PoseKeypoint.fromModelOutput({
    required List<double> coordinates,
    required String name,
    required int index,
    required PoseKeypointType type,
    double confidenceThreshold = 0.3,
  }) {
    final x = coordinates.isNotEmpty ? coordinates[0] : 0.0;
    final y = coordinates.length > 1 ? coordinates[1] : 0.0;
    final confidence = coordinates.length > 2 ? coordinates[2] : 0.0;

    return PoseKeypoint(
      x: x,
      y: y,
      confidence: confidence,
      type: type,
      name: name,
      index: index,
    );
  }

  /// Returns true if the keypoint confidence is above the threshold
  bool isVisible([double threshold = 0.3]) {
    return confidence >= threshold;
  }

  /// Returns true if the keypoint is valid (within image bounds)
  bool isValid() {
    return x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0;
  }

  /// Creates a copy with updated values
  PoseKeypoint copyWith({
    double? x,
    double? y,
    double? confidence,
    PoseKeypointType? type,
    String? name,
    int? index,
  }) {
    return PoseKeypoint(
      x: x ?? this.x,
      y: y ?? this.y,
      confidence: confidence ?? this.confidence,
      type: type ?? this.type,
      name: name ?? this.name,
      index: index ?? this.index,
    );
  }

  @override
  List<Object?> get props => [x, y, confidence, type, name, index];

  @override
  String toString() {
    return 'PoseKeypoint(name: $name, x: $x, y: $y, confidence: $confidence)';
  }
}

/// Extension to add toMap method to PoseKeypoint
extension PoseKeypointSerialization on PoseKeypoint {
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'confidence': confidence,
      'type': type.name,
      'name': name,
      'index': index,
    };
  }
}

/// Extension to add fromMap method to PoseKeypoint
extension PoseKeypointDeserialization on PoseKeypoint {
  static PoseKeypoint fromMap(Map<String, dynamic> map) {
    return PoseKeypoint(
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      confidence: map['confidence']?.toDouble() ?? 0.0,
      type: PoseKeypointType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PoseKeypointType.nose,
      ),
      name: map['name'] ?? '',
      index: map['index']?.toInt() ?? 0,
    );
  }
}

/// Standard keypoint names for ML Kit pose estimation (33 landmarks)
class PoseKeypointNames {
  // Face landmarks
  static const String nose = 'nose';
  static const String leftEye = 'left_eye';
  static const String rightEye = 'right_eye';
  static const String leftEar = 'left_ear';
  static const String rightEar = 'right_ear';
  static const String mouth = 'mouth';

  // Upper body landmarks
  static const String leftShoulder = 'left_shoulder';
  static const String rightShoulder = 'right_shoulder';
  static const String leftElbow = 'left_elbow';
  static const String rightElbow = 'right_elbow';
  static const String leftWrist = 'left_wrist';
  static const String rightWrist = 'right_wrist';

  // Hand landmarks
  static const String leftPinky = 'left_pinky';
  static const String rightPinky = 'right_pinky';
  static const String leftIndex = 'left_index';
  static const String rightIndex = 'right_index';
  static const String leftThumb = 'left_thumb';
  static const String rightThumb = 'right_thumb';

  // Lower body landmarks
  static const String leftHip = 'left_hip';
  static const String rightHip = 'right_hip';
  static const String leftKnee = 'left_knee';
  static const String rightKnee = 'right_knee';
  static const String leftAnkle = 'left_ankle';
  static const String rightAnkle = 'right_ankle';
  static const String leftHeel = 'left_heel';
  static const String rightHeel = 'right_heel';
  static const String leftFootIndex = 'left_foot_index';
  static const String rightFootIndex = 'right_foot_index';

  /// List of all ML Kit keypoint names in order
  static const List<String> mlKitKeypoints = [
    nose,
    leftEye,
    rightEye,
    leftEar,
    rightEar,
    mouth,
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftPinky,
    rightPinky,
    leftIndex,
    rightIndex,
    leftThumb,
    rightThumb,
    leftHip,
    rightHip,
    leftKnee,
    rightKnee,
    leftAnkle,
    rightAnkle,
    leftHeel,
    rightHeel,
    leftFootIndex,
    rightFootIndex,
  ];

  /// List of keypoint names for upper body (useful for boxing poses)
  static const List<String> upperBodyKeypoints = [
    nose,
    leftEye,
    rightEye,
    leftEar,
    rightEar,
    mouth,
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftPinky,
    rightPinky,
    leftIndex,
    rightIndex,
    leftThumb,
    rightThumb,
  ];

  /// List of keypoint names for lower body
  static const List<String> lowerBodyKeypoints = [
    leftHip,
    rightHip,
    leftKnee,
    rightKnee,
    leftAnkle,
    rightAnkle,
    leftHeel,
    rightHeel,
    leftFootIndex,
    rightFootIndex,
  ];

  /// List of keypoint names for face
  static const List<String> faceKeypoints = [
    nose,
    leftEye,
    rightEye,
    leftEar,
    rightEar,
    mouth,
  ];

  /// List of keypoint names for hands
  static const List<String> handKeypoints = [
    leftPinky,
    rightPinky,
    leftIndex,
    rightIndex,
    leftThumb,
    rightThumb,
  ];
}

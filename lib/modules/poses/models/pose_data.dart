import 'package:equatable/equatable.dart';
import 'pose_keypoint.dart';

/// Represents a complete pose estimation result containing all keypoints
class PoseData extends Equatable {
  /// List of all detected keypoints
  final List<PoseKeypoint> keypoints;

  /// Timestamp when the pose was detected (milliseconds since epoch)
  final double timestamp;

  /// Version of the model used for detection
  final String modelVersion;

  /// Confidence threshold used for filtering keypoints
  final double confidenceThreshold;

  /// Image dimensions used for pose detection
  final int imageWidth;
  final int imageHeight;

  const PoseData({
    required this.keypoints,
    required this.timestamp,
    required this.modelVersion,
    this.confidenceThreshold = 0.3,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  /// Creates PoseData from raw model output
  factory PoseData.fromModelOutput({
    required List<List<double>> rawKeypoints,
    required String modelVersion,
    double confidenceThreshold = 0.3,
    int imageWidth = 0,
    int imageHeight = 0,
  }) {
    final keypoints = <PoseKeypoint>[];

    for (int i = 0; i < rawKeypoints.length; i++) {
      final keypointName = i < PoseKeypointNames.mlKitKeypoints.length
          ? PoseKeypointNames.mlKitKeypoints[i]
          : 'keypoint_$i';

      final keypoint = PoseKeypoint.fromModelOutput(
        coordinates: rawKeypoints[i],
        name: keypointName,
        index: i,
        type: PoseKeypointType.values[i % PoseKeypointType.values.length],
        confidenceThreshold: confidenceThreshold,
      );

      keypoints.add(keypoint);
    }

    return PoseData(
      keypoints: keypoints,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      modelVersion: modelVersion,
      confidenceThreshold: confidenceThreshold,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Returns only keypoints that meet the confidence threshold
  List<PoseKeypoint> get visibleKeypoints {
    return keypoints.where((kp) => kp.isVisible(confidenceThreshold)).toList();
  }

  /// Returns keypoints for a specific body part group
  List<PoseKeypoint> getKeypointsByGroup(List<String> keypointNames) {
    return keypoints.where((kp) => keypointNames.contains(kp.name)).toList();
  }

  /// Returns upper body keypoints (useful for boxing poses)
  List<PoseKeypoint> get upperBodyKeypoints {
    return getKeypointsByGroup(PoseKeypointNames.upperBodyKeypoints);
  }

  /// Returns lower body keypoints
  List<PoseKeypoint> get lowerBodyKeypoints {
    return getKeypointsByGroup(PoseKeypointNames.lowerBodyKeypoints);
  }

  /// Returns a specific keypoint by name
  PoseKeypoint? getKeypointByName(String name) {
    try {
      return keypoints.firstWhere((kp) => kp.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Returns the center point of the pose (average of all visible keypoints)
  PoseKeypoint? get centerPoint {
    final visible = visibleKeypoints;
    if (visible.isEmpty) return null;

    final avgX =
        visible.map((kp) => kp.x).reduce((a, b) => a + b) / visible.length;
    final avgY =
        visible.map((kp) => kp.y).reduce((a, b) => a + b) / visible.length;
    final avgConfidence =
        visible.map((kp) => kp.confidence).reduce((a, b) => a + b) /
        visible.length;

    return PoseKeypoint(
      x: avgX,
      y: avgY,
      confidence: avgConfidence,
      type: PoseKeypointType.nose, // Use nose as default type for center
      name: 'center',
      index: -1,
    );
  }

  /// Returns the bounding box of all visible keypoints
  Map<String, double>? get boundingBox {
    final visible = visibleKeypoints;
    if (visible.isEmpty) return null;

    final xCoords = visible.map((kp) => kp.x);
    final yCoords = visible.map((kp) => kp.y);

    return {
      'x': xCoords.reduce((a, b) => a < b ? a : b),
      'y': yCoords.reduce((a, b) => a < b ? a : b),
      'width':
          xCoords.reduce((a, b) => a > b ? a : b) -
          xCoords.reduce((a, b) => a < b ? a : b),
      'height':
          yCoords.reduce((a, b) => a > b ? a : b) -
          yCoords.reduce((a, b) => a < b ? a : b),
    };
  }

  /// Returns true if the pose has enough visible keypoints to be considered valid
  bool isValid([int minKeypoints = 5]) {
    return visibleKeypoints.length >= minKeypoints;
  }

  /// Returns the average confidence of all keypoints
  double get averageConfidence {
    if (keypoints.isEmpty) return 0.0;
    return keypoints.map((kp) => kp.confidence).reduce((a, b) => a + b) /
        keypoints.length;
  }

  /// Creates a copy with updated values
  PoseData copyWith({
    List<PoseKeypoint>? keypoints,
    double? timestamp,
    String? modelVersion,
    double? confidenceThreshold,
    int? imageWidth,
    int? imageHeight,
  }) {
    return PoseData(
      keypoints: keypoints ?? this.keypoints,
      timestamp: timestamp ?? this.timestamp,
      modelVersion: modelVersion ?? this.modelVersion,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'keypoints': keypoints.map((kp) => kp.toMap()).toList(),
      'timestamp': timestamp,
      'modelVersion': modelVersion,
      'confidenceThreshold': confidenceThreshold,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    };
  }

  /// Creates from a map (for deserialization)
  factory PoseData.fromMap(Map<String, dynamic> map) {
    return PoseData(
      keypoints: (map['keypoints'] as List)
          .map((kp) => PoseKeypointDeserialization.fromMap(kp))
          .toList(),
      timestamp: map['timestamp']?.toDouble() ?? 0.0,
      modelVersion: map['modelVersion'] ?? '',
      confidenceThreshold: map['confidenceThreshold']?.toDouble() ?? 0.3,
      imageWidth: map['imageWidth']?.toInt() ?? 0,
      imageHeight: map['imageHeight']?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    keypoints,
    timestamp,
    modelVersion,
    confidenceThreshold,
    imageWidth,
    imageHeight,
  ];

  @override
  String toString() {
    return 'PoseData(keypoints: ${keypoints.length}, visible: ${visibleKeypoints.length}, '
        'confidence: ${averageConfidence.toStringAsFixed(2)}, '
        'timestamp: $timestamp)';
  }
}

import 'package:flutter/material.dart';
import '../models/pose_data.dart';

/// Widget that overlays pose landmarks on the camera preview
class PoseOverlayWidget extends StatelessWidget {
  final List<PoseData> poses;
  final Size imageSize;
  final Size previewSize;

  const PoseOverlayWidget({
    Key? key,
    required this.poses,
    required this.imageSize,
    required this.previewSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PosePainter(
        poses: poses,
        imageSize: imageSize,
        previewSize: previewSize,
      ),
      size: previewSize,
    );
  }
}

/// Custom painter for drawing pose landmarks and connections
class PosePainter extends CustomPainter {
  final List<PoseData> poses;
  final Size imageSize;
  final Size previewSize;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    // Calculate proper scaling with aspect ratio preservation
    final imageAspectRatio = imageSize.width / imageSize.height;
    final previewAspectRatio = previewSize.width / previewSize.height;

    double scaleX, scaleY;
    double offsetX = 0, offsetY = 0;

    if (imageAspectRatio > previewAspectRatio) {
      // Image is wider - fit to width, center vertically
      scaleX = previewSize.width / imageSize.width;
      scaleY = scaleX; // Keep aspect ratio
      offsetY = (previewSize.height - imageSize.height * scaleY) / 2;
    } else {
      // Image is taller - fit to height, center horizontally
      scaleY = previewSize.height / imageSize.height;
      scaleX = scaleY; // Keep aspect ratio
      offsetX = (previewSize.width - imageSize.width * scaleX) / 2;
    }

    // Debug logging
    debugPrint(
      'PoseOverlayWidget: imageSize: $imageSize, previewSize: $previewSize',
    );
    debugPrint(
      'PoseOverlayWidget: imageAspectRatio: $imageAspectRatio, previewAspectRatio: $previewAspectRatio',
    );
    debugPrint(
      'PoseOverlayWidget: scaleX: $scaleX, scaleY: $scaleY, offsetX: $offsetX, offsetY: $offsetY',
    );
    debugPrint('PoseOverlayWidget: canvas size: $size');

    // Draw debug bounding boxes to visualize coordinate spaces
    _drawDebugBoxes(canvas, size, scaleX, scaleY, offsetX, offsetY);

    for (final poseData in poses) {
      _drawPose(canvas, poseData, scaleX, scaleY, offsetX, offsetY);
    }
  }

  void _drawDebugBoxes(
    Canvas canvas,
    Size size,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Draw bounding box for image size (properly scaled and positioned)
    final imagePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(
        offsetX,
        offsetY,
        imageSize.width * scaleX,
        imageSize.height * scaleY,
      ),
      imagePaint,
    );

    // Draw bounding box for preview size (should match display area)
    final previewPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, previewSize.width, previewSize.height),
      previewPaint,
    );

    // Draw canvas size box
    final canvasPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), canvasPaint);
  }

  void _drawPose(
    Canvas canvas,
    PoseData poseData,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Draw skeleton connections first
    _drawSkeleton(canvas, poseData, scaleX, scaleY, offsetX, offsetY);

    // Draw landmarks
    for (final keypoint in poseData.keypoints) {
      if (keypoint.confidence > 0.3) {
        final x = keypoint.x * scaleX + offsetX;
        final y = keypoint.y * scaleY + offsetY;

        // Debug logging for first few keypoints
        if (keypoint.name == 'nose' || keypoint.name == 'left_shoulder') {
          debugPrint(
            'PoseOverlayWidget: ${keypoint.name} - raw: (${keypoint.x}, ${keypoint.y}), scaled: ($x, $y)',
          );
        }

        // Draw keypoint with confidence-based color and size
        final confidence = keypoint.confidence;
        final color =
            Color.lerp(Colors.red, Colors.green, confidence) ?? Colors.red;

        // Size based on confidence (higher confidence = larger keypoint)
        final keypointSize =
            4.0 + (confidence * 4.0); // 4-8 pixels based on confidence
        final outlineSize = keypointSize + 2.0;

        // Draw keypoint circle with gradient effect
        canvas.drawCircle(
          Offset(x, y),
          keypointSize,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );

        // Draw keypoint outline with better contrast
        canvas.drawCircle(
          Offset(x, y),
          outlineSize,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Draw inner highlight for high-confidence keypoints
        if (confidence > 0.8) {
          canvas.drawCircle(
            Offset(x, y),
            keypointSize * 0.6,
            Paint()
              ..color = Colors.white.withOpacity(0.6)
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  void _drawSkeleton(
    Canvas canvas,
    PoseData poseData,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Debug: Print all available keypoint names
    debugPrint(
      'PoseOverlayWidget: Available keypoints: ${poseData.keypoints.map((kp) => kp.name).toList()}',
    );

    // Define skeleton connections with different colors for different body parts
    // Using enum names (without underscores) as that's what the keypoints actually use
    final connections = [
      // Face connections (yellow)
      {'start': 'nose', 'end': 'leftEye', 'color': Colors.yellow, 'width': 2.0},
      {
        'start': 'nose',
        'end': 'rightEye',
        'color': Colors.yellow,
        'width': 2.0,
      },
      {
        'start': 'leftEye',
        'end': 'leftEar',
        'color': Colors.yellow,
        'width': 2.0,
      },
      {
        'start': 'rightEye',
        'end': 'rightEar',
        'color': Colors.yellow,
        'width': 2.0,
      },
      {
        'start': 'leftEar',
        'end': 'leftShoulder',
        'color': Colors.yellow,
        'width': 2.0,
      },
      {
        'start': 'rightEar',
        'end': 'rightShoulder',
        'color': Colors.yellow,
        'width': 2.0,
      },

      // Torso connections (blue)
      {
        'start': 'leftShoulder',
        'end': 'rightShoulder',
        'color': Colors.blue,
        'width': 3.0,
      },
      {
        'start': 'leftShoulder',
        'end': 'leftHip',
        'color': Colors.blue,
        'width': 3.0,
      },
      {
        'start': 'rightShoulder',
        'end': 'rightHip',
        'color': Colors.blue,
        'width': 3.0,
      },
      {
        'start': 'leftHip',
        'end': 'rightHip',
        'color': Colors.blue,
        'width': 3.0,
      },

      // Left arm connections (green)
      {
        'start': 'leftShoulder',
        'end': 'leftElbow',
        'color': Colors.green,
        'width': 3.0,
      },
      {
        'start': 'leftElbow',
        'end': 'leftWrist',
        'color': Colors.green,
        'width': 3.0,
      },
      {
        'start': 'leftWrist',
        'end': 'leftPinky',
        'color': Colors.green,
        'width': 2.0,
      },
      {
        'start': 'leftWrist',
        'end': 'leftIndex',
        'color': Colors.green,
        'width': 2.0,
      },
      {
        'start': 'leftWrist',
        'end': 'leftThumb',
        'color': Colors.green,
        'width': 2.0,
      },

      // Right arm connections (orange)
      {
        'start': 'rightShoulder',
        'end': 'rightElbow',
        'color': Colors.orange,
        'width': 3.0,
      },
      {
        'start': 'rightElbow',
        'end': 'rightWrist',
        'color': Colors.orange,
        'width': 3.0,
      },
      {
        'start': 'rightWrist',
        'end': 'rightPinky',
        'color': Colors.orange,
        'width': 2.0,
      },
      {
        'start': 'rightWrist',
        'end': 'rightIndex',
        'color': Colors.orange,
        'width': 2.0,
      },
      {
        'start': 'rightWrist',
        'end': 'rightThumb',
        'color': Colors.orange,
        'width': 2.0,
      },

      // Left leg connections (purple)
      {
        'start': 'leftHip',
        'end': 'leftKnee',
        'color': Colors.purple,
        'width': 3.0,
      },
      {
        'start': 'leftKnee',
        'end': 'leftAnkle',
        'color': Colors.purple,
        'width': 3.0,
      },
      {
        'start': 'leftAnkle',
        'end': 'leftHeel',
        'color': Colors.purple,
        'width': 2.0,
      },
      {
        'start': 'leftAnkle',
        'end': 'leftFootIndex',
        'color': Colors.purple,
        'width': 2.0,
      },

      // Right leg connections (red)
      {
        'start': 'rightHip',
        'end': 'rightKnee',
        'color': Colors.red,
        'width': 3.0,
      },
      {
        'start': 'rightKnee',
        'end': 'rightAnkle',
        'color': Colors.red,
        'width': 3.0,
      },
      {
        'start': 'rightAnkle',
        'end': 'rightHeel',
        'color': Colors.red,
        'width': 2.0,
      },
      {
        'start': 'rightAnkle',
        'end': 'rightFootIndex',
        'color': Colors.red,
        'width': 2.0,
      },
    ];

    int connectionsDrawn = 0;
    for (final connection in connections) {
      final startKeypoint = poseData.getKeypointByName(
        connection['start'] as String,
      );
      final endKeypoint = poseData.getKeypointByName(
        connection['end'] as String,
      );

      if (startKeypoint != null &&
          endKeypoint != null &&
          startKeypoint.confidence > 0.3 &&
          endKeypoint.confidence > 0.3) {
        final startX = startKeypoint.x * scaleX + offsetX;
        final startY = startKeypoint.y * scaleY + offsetY;
        final endX = endKeypoint.x * scaleX + offsetX;
        final endY = endKeypoint.y * scaleY + offsetY;

        // Create paint with connection-specific color and width
        final linePaint = Paint()
          ..color = connection['color'] as Color
          ..strokeWidth = connection['width'] as double
          ..style = PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round; // Rounded line caps for better appearance

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
        connectionsDrawn++;
      }
    }

    debugPrint(
      'PoseOverlayWidget: Drew $connectionsDrawn skeleton connections',
    );
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    // Only repaint if poses have actually changed
    return oldDelegate.poses != poses ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.previewSize != previewSize;
  }
}

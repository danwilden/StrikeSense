import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:strikesense/modules/poses/models/pose_data.dart';

import '../core/pose_estimation_bloc.dart';
import '../core/pose_estimation_state.dart';
import '../models/pose_estimation_config.dart';
import '../services/camera_pipeline_manager.dart';

/// Widget for displaying camera preview with pose estimation overlay
class CameraPreviewWidget extends StatefulWidget {
  final bool showPoseOverlay;
  final bool showDebugInfo;
  final VoidCallback? onCameraReady;
  final VoidCallback? onCameraError;

  const CameraPreviewWidget({
    super.key,
    this.showPoseOverlay = true,
    this.showDebugInfo = false,
    this.onCameraReady,
    this.onCameraError,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  final CameraPipelineManager _pipelineManager = CameraPipelineManager.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _pipelineManager.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Initialize with debug configuration for testing pose detection
      await _pipelineManager.initialize(PoseEstimationConfig.debug());

      setState(() {
        _isInitialized = true;
      });

      widget.onCameraReady?.call();
    } catch (e) {
      debugPrint('CameraPreviewWidget: Failed to initialize camera: $e');
      widget.onCameraError?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return BlocBuilder<PoseEstimationBloc, PoseEstimationState>(
      builder: (context, state) {
        return Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),

            // Pose overlay
            if (widget.showPoseOverlay) _buildPoseOverlay(state),

            // Debug info
            if (widget.showDebugInfo) _buildDebugInfo(state),

            // Controls
            _buildControls(),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    final preview = _pipelineManager.getCameraPreview();

    if (preview == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return SizedBox.expand(child: preview);
  }

  Widget _buildPoseOverlay(PoseEstimationState state) {
    if (state is! PoseEstimationResult) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: PoseOverlayPainter(
        poseData: state.poseData,
        screenSize: MediaQuery.of(context).size,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildDebugInfo(PoseEstimationState state) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Status: ${state.runtimeType}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (state is PoseEstimationResult) ...[
              Text(
                'Keypoints: ${state.poseData.visibleKeypoints.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                'Confidence: ${state.poseData.averageConfidence.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
            if (state is PoseEstimationProcessing) ...[
              const Text(
                'Processing...',
                style: TextStyle(color: Colors.yellow, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Test button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Test simplified approach button
              ElevatedButton.icon(
                onPressed: _testSimplifiedApproach,
                icon: const Icon(Icons.science),
                label: const Text('Simple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              // Test pose detection button
              ElevatedButton.icon(
                onPressed: _testPoseDetection,
                icon: const Icon(Icons.science),
                label: const Text('Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              // Basic ML Kit test button
              ElevatedButton.icon(
                onPressed: _testMLKitBasic,
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),

              // Model testing button
              ElevatedButton.icon(
                onPressed: _testDifferentModels,
                icon: const Icon(Icons.model_training),
                label: const Text('Models'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),

              // Complete integration test button
              ElevatedButton.icon(
                onPressed: _testCompleteIntegration,
                icon: const Icon(Icons.integration_instructions),
                label: const Text('Full'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              // Debug folder button
              ElevatedButton.icon(
                onPressed: _showDebugFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Debug'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),

              // Start/Stop button
              ElevatedButton.icon(
                onPressed: _toggleCamera,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Second row of controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Switch camera button
              ElevatedButton.icon(
                onPressed: _switchCamera,
                icon: const Icon(Icons.switch_camera),
                label: const Text('Switch'),
              ),

              // Settings button
              ElevatedButton.icon(
                onPressed: _showSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleCamera() async {
    try {
      if (_pipelineManager.isRunning) {
        await _pipelineManager.stop();
        debugPrint('CameraPreviewWidget: Camera pipeline stopped');
      } else {
        await _pipelineManager.start();
        debugPrint('CameraPreviewWidget: Camera pipeline started');
      }
    } catch (e) {
      debugPrint('CameraPreviewWidget: Failed to toggle camera: $e');
    }
  }

  void _switchCamera() async {
    try {
      // Switch between front (1) and back (0) camera
      final currentCamera = _pipelineManager.poseService.detector != null
          ? 1
          : 0;
      final newCamera = currentCamera == 1 ? 0 : 1;

      await _pipelineManager.switchCamera(cameraIndex: newCamera);
      debugPrint('CameraPreviewWidget: Switched to camera $newCamera');
    } catch (e) {
      debugPrint('CameraPreviewWidget: Failed to switch camera: $e');
    }
  }

  void _showSettings() {
    // Implementation for showing settings
    // This would show a settings dialog
  }

  void _testSimplifiedApproach() async {
    try {
      debugPrint('CameraPreviewWidget: Testing simplified approach...');
      // Access the pose estimation service through the pipeline manager
      final poseService = _pipelineManager.poseService;
      await poseService.testSimplifiedApproach();
    } catch (e) {
      debugPrint('CameraPreviewWidget: Simplified approach test failed: $e');
    }
  }

  void _testPoseDetection() async {
    try {
      debugPrint('CameraPreviewWidget: Testing pose detection...');
      // Access the pose estimation service through the pipeline manager
      final poseService = _pipelineManager.poseService;
      await poseService.testPoseDetection();
    } catch (e) {
      debugPrint('CameraPreviewWidget: Test failed: $e');
    }
  }

  void _testMLKitBasic() async {
    try {
      debugPrint('CameraPreviewWidget: Running basic ML Kit debug tests...');
      // Access the pose estimation service through the pipeline manager
      final poseService = _pipelineManager.poseService;
      await poseService.testMLKitBasic();
    } catch (e) {
      debugPrint('CameraPreviewWidget: Basic test failed: $e');
    }
  }

  void _testDifferentModels() async {
    try {
      debugPrint('CameraPreviewWidget: Testing different ML Kit models...');
      // Access the pose estimation service through the pipeline manager
      final poseService = _pipelineManager.poseService;
      await poseService.testDifferentModels();
    } catch (e) {
      debugPrint('CameraPreviewWidget: Model testing failed: $e');
    }
  }

  void _testCompleteIntegration() async {
    try {
      debugPrint('CameraPreviewWidget: Running complete integration test...');
      // Access the pose estimation service through the pipeline manager
      final poseService = _pipelineManager.poseService;
      await poseService.testCompleteIntegration();
    } catch (e) {
      debugPrint('CameraPreviewWidget: Complete integration test failed: $e');
    }
  }

  void _showDebugFolder() async {
    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final debugDir = Directory('${directory.path}/pose_debug');

      // Check if debug directory exists
      final exists = await debugDir.exists();

      // List files in debug directory if it exists
      List<FileSystemEntity> files = [];
      if (exists) {
        files = debugDir.listSync();
      }

      // Show a simple dialog with the path
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Debug images are saved to:'),
              const SizedBox(height: 8),
              SelectableText(
                debugDir.path,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  backgroundColor: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text('Files: ${files.length}'),
              if (files.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Recent files:'),
                ...files
                    .take(3)
                    .map(
                      (file) => Text(
                        '• ${file.path.split('/').last}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: debugDir.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard!')),
                );
              },
              child: const Text('Copy Path'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('CameraPreviewWidget: Failed to show debug folder: $e');
    }
  }
}

/// Custom painter for drawing pose overlay
class PoseOverlayPainter extends CustomPainter {
  final PoseData poseData;
  final Size screenSize;

  PoseOverlayPainter({required this.poseData, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw keypoints
    for (final keypoint in poseData.visibleKeypoints) {
      final x = keypoint.x * size.width;
      final y = keypoint.y * size.height;

      canvas.drawCircle(Offset(x, y), 5.0, pointPaint);
    }

    // Draw skeleton connections
    _drawSkeleton(canvas, paint);
  }

  void _drawSkeleton(Canvas canvas, Paint paint) {
    // Define skeleton connections (simplified)
    final connections = [
      ['nose', 'left_eye'],
      ['nose', 'right_eye'],
      ['left_eye', 'left_ear'],
      ['right_eye', 'right_ear'],
      ['left_shoulder', 'right_shoulder'],
      ['left_shoulder', 'left_elbow'],
      ['left_elbow', 'left_wrist'],
      ['right_shoulder', 'right_elbow'],
      ['right_elbow', 'right_wrist'],
      ['left_shoulder', 'left_hip'],
      ['right_shoulder', 'right_hip'],
      ['left_hip', 'right_hip'],
      ['left_hip', 'left_knee'],
      ['left_knee', 'left_ankle'],
      ['right_hip', 'right_knee'],
      ['right_knee', 'right_ankle'],
    ];

    for (final connection in connections) {
      final startKeypoint = poseData.getKeypointByName(connection[0]);
      final endKeypoint = poseData.getKeypointByName(connection[1]);

      if (startKeypoint != null && endKeypoint != null) {
        final startX = startKeypoint.x * screenSize.width;
        final startY = startKeypoint.y * screenSize.height;
        final endX = endKeypoint.x * screenSize.width;
        final endY = endKeypoint.y * screenSize.height;

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.poseData != poseData;
  }
}

/// Settings dialog for camera and pose estimation configuration
class CameraSettingsDialog extends StatefulWidget {
  const CameraSettingsDialog({super.key});

  @override
  State<CameraSettingsDialog> createState() => _CameraSettingsDialogState();
}

class _CameraSettingsDialogState extends State<CameraSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Camera Settings'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Settings will be implemented here'),
          // Add settings controls here
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

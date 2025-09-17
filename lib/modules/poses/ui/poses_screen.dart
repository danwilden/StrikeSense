import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme.dart';
import '../services/pose_estimation_service.dart';
import '../services/model_manager.dart';
import '../services/camera_pipeline_manager.dart';
import '../models/pose_data.dart';
import '../models/pose_estimation_config.dart';
import 'pose_overlay_widget.dart';

class PosesScreen extends StatefulWidget {
  const PosesScreen({super.key});

  @override
  State<PosesScreen> createState() => _PosesScreenState();
}

class _PosesScreenState extends State<PosesScreen> {
  final PoseEstimationService _poseService = PoseEstimationService.instance;
  final ModelManager _modelManager = ModelManager.instance;
  final CameraPipelineManager _pipelineManager = CameraPipelineManager.instance;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isCameraActive = false;
  String _status = 'Ready to initialize';
  String _modelInfo = '';
  StreamSubscription? _pipelineSubscription;
  List<PoseData> _detectedPoses = [];
  Size _cameraPreviewSize = const Size(480, 640);
  Size _actualPreviewSize = const Size(300, 300); // Actual camera preview size
  int _throttleInterval = 3; // Current throttling setting

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _pipelineSubscription?.cancel();
    _pipelineManager.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _status = 'Initializing Model Manager...';
        _isLoading = true;
      });

      // Initialize model manager
      await _modelManager.initialize();

      setState(() {
        _status = 'Model Manager initialized successfully!';
        _isInitialized = true;
        _isLoading = false;
      });

      // Get model information
      final info = _modelManager.getModelInfo();
      setState(() {
        _modelInfo =
            'Model: ${info['currentConfig']?['modelName'] ?? 'Unknown'}\n'
            'Initialized: ${info['isInitialized']}\n'
            'Service Status: ${_poseService.getPerformanceStats()}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testPoseEstimation() async {
    try {
      setState(() {
        _status = 'Starting camera for pose estimation...';
        _isLoading = true;
      });

      // Initialize camera pipeline
      await _pipelineManager.initialize(PoseEstimationConfig.boxingTraining());

      // Test pose detection with synthetic image first
      await _pipelineManager.poseService.testPoseDetection();

      // Start camera with timeout
      await _pipelineManager.start().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Camera start timed out after 20 seconds');
        },
      );

      setState(() {
        _status = 'Camera active - detecting poses...';
        _isLoading = false;
        _isCameraActive = true;
      });

      // Listen to pose estimation results
      _pipelineSubscription = _pipelineManager.resultStream.listen(
        (result) {
          setState(() {
            _status =
                'Pose detected! Keypoints: ${result.poseData.visibleKeypoints.length}';
            _detectedPoses = [
              result.poseData,
            ]; // Store the detected pose for overlay
            // Update camera preview size from pose data
            _cameraPreviewSize = Size(
              result.poseData.imageWidth.toDouble(),
              result.poseData.imageHeight.toDouble(),
            );
            debugPrint(
              'PosesScreen: Updated camera preview size to $_cameraPreviewSize',
            );
            debugPrint(
              'PosesScreen: Actual preview size is $_actualPreviewSize',
            );
          });
          // Removed _showPoseResult to prevent pop-up spam
        },
        onError: (error) {
          setState(() {
            _status = 'Pose estimation error: $error';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Failed to start camera: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _pipelineManager.stop();
      _pipelineSubscription?.cancel();
      setState(() {
        _status = 'Camera stopped';
        _isCameraActive = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error stopping camera: $e';
      });
    }
  }

  Future<void> _forceStopCamera() async {
    try {
      await _pipelineManager.forceStop();
      _pipelineSubscription?.cancel();
      setState(() {
        _status = 'Camera force stopped';
        _isCameraActive = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error force stopping camera: $e';
        _isLoading = false;
      });
    }
  }

  // Removed _showPoseResult method to prevent pop-up spam

  Future<void> _switchModel() async {
    try {
      setState(() {
        _status = 'Switching model...';
        _isLoading = true;
      });

      // Switch to BlazePose Lite
      await _modelManager.switchToBlazePoseLite();

      setState(() {
        _status = 'Model switched to BlazePose Lite!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to switch model: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifySetup() async {
    try {
      setState(() {
        _status = 'Verifying ML Kit setup...';
        _isLoading = true;
      });

      // Verify pose estimation service setup
      final verification = await _poseService.verifySetup();

      setState(() {
        _status = 'ML Kit verification complete!';
        _isLoading = false;
        _modelInfo =
            'Verification Results:\n'
            'Initialized: ${verification['isInitialized']}\n'
            'Detector: ${verification['detectorExists']}\n'
            'Config: ${verification['configExists']}\n'
            'Test Result: ${verification['testResult']}';
      });

      // Show detailed results in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ML Kit Verification Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Initialized: ${verification['isInitialized']}'),
                Text('Detector Exists: ${verification['detectorExists']}'),
                Text('Config Exists: ${verification['configExists']}'),
                if (verification['config'] != null) ...[
                  const Text('\nConfiguration:'),
                  Text('  Mode: ${verification['config']['performanceMode']}'),
                  Text(
                    '  Min Confidence: ${verification['config']['minConfidence']}',
                  ),
                  Text(
                    '  Smoothing: ${verification['config']['smoothingEnabled']}',
                  ),
                ],
                if (verification['testResult'] != null) ...[
                  const Text('\nTest Results:'),
                  Text('  Success: ${verification['testResult']['success']}'),
                  if (verification['testResult']['success']) ...[
                    Text(
                      '  Poses Detected: ${verification['testResult']['posesDetected']}',
                    ),
                    Text(
                      '  Processing Time: ${verification['testResult']['processingTimeMs']}ms',
                    ),
                  ] else ...[
                    Text('  Error: ${verification['testResult']['error']}'),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Verification failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showDebugFolder() async {
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

      // Show dialog with debug folder information
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Folder Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Debug Folder Path:'),
                SelectableText(
                  debugDir.path,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Folder Exists: ${exists ? "Yes" : "No"}'),
                if (exists) ...[
                  const SizedBox(height: 8),
                  Text('Files in folder: ${files.length}'),
                  if (files.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Files:'),
                    ...files.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          file.path.split('/').last,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Debug folder does not exist yet. Run some tests first to generate debug images.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'To access the folder:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Copy the path above'),
                const Text('2. Open Finder (macOS) or File Explorer'),
                const Text('3. Press Cmd+Shift+G (macOS) or Ctrl+L (Windows)'),
                const Text('4. Paste the path and press Enter'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Copy path to clipboard
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to get debug folder info: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Pose Estimation Test',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isInitialized ? Icons.check_circle : Icons.info,
                            color: _isInitialized
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Model Info Card
              if (_modelInfo.isNotEmpty) ...[
                Card(
                  color: AppTheme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _modelInfo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Camera Preview
              if (_isCameraActive) ...[
                Card(
                  color: AppTheme.cardColor,
                  child: Container(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Update actual preview size when layout changes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_actualPreviewSize != constraints.biggest) {
                              setState(() {
                                _actualPreviewSize = constraints.biggest;
                              });
                            }
                          });

                          // Calculate the actual rendered size of the camera preview
                          Size actualCameraPreviewSize = _actualPreviewSize;
                          if (_cameraPreviewSize.width > 0 &&
                              _cameraPreviewSize.height > 0) {
                            final imageAspectRatio =
                                _cameraPreviewSize.width /
                                _cameraPreviewSize.height;
                            final containerAspectRatio =
                                constraints.maxWidth / constraints.maxHeight;

                            if (imageAspectRatio > containerAspectRatio) {
                              // Image is wider - fit to width
                              actualCameraPreviewSize = Size(
                                constraints.maxWidth,
                                constraints.maxWidth / imageAspectRatio,
                              );
                            } else {
                              // Image is taller - fit to height
                              actualCameraPreviewSize = Size(
                                constraints.maxHeight * imageAspectRatio,
                                constraints.maxHeight,
                              );
                            }
                          }

                          return Stack(
                            children: [
                              // Center the camera preview and maintain aspect ratio
                              Center(
                                child:
                                    _cameraPreviewSize.width > 0 &&
                                        _cameraPreviewSize.height > 0
                                    ? AspectRatio(
                                        aspectRatio:
                                            _cameraPreviewSize.width /
                                            _cameraPreviewSize.height,
                                        child:
                                            _pipelineManager
                                                .getCameraPreview() ??
                                            const Center(
                                              child: Text(
                                                'Camera preview not available',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                      )
                                    : _pipelineManager.getCameraPreview() ??
                                          const Center(
                                            child: Text(
                                              'Camera preview not available',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                              ),
                              // Pose overlay - use the calculated actual camera preview size
                              if (_detectedPoses.isNotEmpty)
                                Positioned.fill(
                                  child: PoseOverlayWidget(
                                    poses: _detectedPoses,
                                    imageSize: _cameraPreviewSize,
                                    previewSize: actualCameraPreviewSize,
                                  ),
                                ),

                              // Status overlay
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Status: $_status',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_detectedPoses.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Keypoints: ${_detectedPoses.first.visibleKeypoints.length}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Confidence: ${_detectedPoses.first.averageConfidence.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.cyan,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Test Buttons
              if (_isInitialized) ...[
                if (!_isCameraActive) ...[
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testPoseEstimation,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Camera & Test Pose Estimation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _stopCamera,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _forceStopCamera,
                    icon: const Icon(Icons.emergency),
                    label: const Text('Force Stop (if stuck)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Performance Controls
                if (_isCameraActive) ...[
                  Card(
                    color: AppTheme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Performance Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Frame Throttling: '),
                              Expanded(
                                child: Slider(
                                  value: _throttleInterval.toDouble(),
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  label: 'Every $_throttleInterval frame(s)',
                                  onChanged: (value) {
                                    setState(() {
                                      _throttleInterval = value.round();
                                    });
                                    _poseService.setThrottleInterval(
                                      _throttleInterval,
                                    );
                                  },
                                ),
                              ),
                              Text('$_throttleInterval'),
                            ],
                          ),
                          Text(
                            'Processing ~${(30 / _throttleInterval).toStringAsFixed(1)} FPS',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _switchModel,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch Model'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _initializeServices,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reinitialize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifySetup,
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Verify ML Kit Setup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _showDebugFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Debug Folder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Instructions
              Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Instructions:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Tap "Start Camera & Test Pose Estimation" to begin\n'
                        '2. Position yourself in front of the camera\n'
                        '3. Watch for pose detection results\n'
                        '4. Use "Stop Camera" when done\n'
                        '5. Try "Switch Model" to test different models',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';

import '../models/pose_data.dart';
import '../models/pose_estimation_config.dart';
import 'camera_service.dart';
import 'frame_processor.dart';
import 'pose_estimation_service.dart';

/// Manages the complete camera pipeline from capture to pose estimation
class CameraPipelineManager {
  static CameraPipelineManager? _instance;
  static CameraPipelineManager get instance =>
      _instance ??= CameraPipelineManager._();

  CameraPipelineManager._();

  final CameraService _cameraService = CameraService.instance;
  final FrameProcessor _frameProcessor = FrameProcessor.instance;
  final PoseEstimationService _poseService = PoseEstimationService.instance;

  /// Get the pose estimation service
  PoseEstimationService get poseService => _poseService;

  bool _isInitialized = false;
  bool _isRunning = false;
  PoseEstimationConfig? _config;

  // Stream subscriptions
  StreamSubscription<CameraImage>? _cameraImageSubscription;
  StreamSubscription<CameraImage>? _processedFrameSubscription;
  StreamSubscription<CameraStatus>? _cameraStatusSubscription;

  /// Stream controller for pipeline status
  final StreamController<PipelineStatus> _statusController =
      StreamController<PipelineStatus>.broadcast();

  /// Stream controller for pose estimation results
  final StreamController<PipelineResult> _resultController =
      StreamController<PipelineResult>.broadcast();

  /// Stream of pipeline status updates
  Stream<PipelineStatus> get statusStream => _statusController.stream;

  /// Stream of pose estimation results
  Stream<PipelineResult> get resultStream => _resultController.stream;

  /// Returns true if the pipeline is initialized
  bool get isInitialized => _isInitialized;

  /// Returns true if the pipeline is currently running
  bool get isRunning => _isRunning;

  /// Returns the current configuration
  PoseEstimationConfig? get config => _config;

  /// Initialize the camera pipeline
  Future<void> initialize(PoseEstimationConfig config) async {
    if (_isInitialized) return;

    try {
      debugPrint('CameraPipelineManager: Initializing...');

      _config = config;

      // Initialize camera service
      await _cameraService.initialize();

      // Initialize frame processor
      await _frameProcessor.initialize(config);

      // Initialize pose estimation service
      await _poseService.initialize(config);

      // Set up stream subscriptions
      _setupStreamSubscriptions();

      _isInitialized = true;
      _emitStatus(PipelineStatus.initialized);

      debugPrint('CameraPipelineManager: Successfully initialized');
    } catch (e) {
      debugPrint('CameraPipelineManager: Failed to initialize: $e');
      _emitStatus(PipelineStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Set up stream subscriptions
  void _setupStreamSubscriptions() {
    // Listen to camera images directly (for ML Kit)
    _cameraImageSubscription = _cameraService.imageStream.listen(
      (cameraImage) {
        if (_isRunning) {
          // Process frame directly with frame processor
          _frameProcessor.processFrame(cameraImage);
        }
      },
      onError: (error) {
        debugPrint('CameraPipelineManager: Camera image error: $error');
        _emitStatus(PipelineStatus.error, error: error.toString());
      },
    );

    // Listen to processed frames
    _processedFrameSubscription = _frameProcessor.processedFrameStream.listen(
      (frame) async {
        if (_isRunning) {
          await _processFrameForPoseEstimation(frame);
        }
      },
      onError: (error) {
        debugPrint('CameraPipelineManager: Frame processing error: $error');
        _emitStatus(PipelineStatus.error, error: error.toString());
      },
    );

    // Listen to camera status
    _cameraStatusSubscription = _cameraService.statusStream.listen((status) {
      debugPrint('CameraPipelineManager: Camera status: $status');
      if (status == CameraStatus.error) {
        _emitStatus(PipelineStatus.error, error: 'Camera error');
      }
    });

    // Listen to pose estimation results
    _poseService.poseStream.listen(
      (poseData) {
        if (_isRunning) {
          _emitResult(
            PipelineResult(
              poseData: poseData,
              timestamp: DateTime.now(),
              processingStats: _getProcessingStats(),
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('CameraPipelineManager: Pose estimation error: $error');
        _emitStatus(PipelineStatus.error, error: error.toString());
      },
    );
  }

  /// Process frame for pose estimation
  Future<void> _processFrameForPoseEstimation(CameraImage frame) async {
    try {
      debugPrint(
        'CameraPipelineManager: Processing frame for pose estimation (${frame.width}x${frame.height})',
      );
      await _poseService.processFrame(frame);
    } catch (e) {
      debugPrint(
        'CameraPipelineManager: Failed to process frame for pose estimation: $e',
      );
    }
  }

  /// Start the camera pipeline
  Future<void> start({int cameraIndex = 1}) async {
    // Default to front camera (index 1)
    if (!_isInitialized) {
      throw Exception('Pipeline not initialized');
    }

    try {
      debugPrint('CameraPipelineManager: Starting pipeline...');

      _emitStatus(PipelineStatus.starting);

      // Start camera with timeout
      await _cameraService
          .startCamera(cameraIndex: cameraIndex)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Camera pipeline start timed out after 15 seconds',
              );
            },
          );

      _isRunning = true;
      _emitStatus(PipelineStatus.running);

      debugPrint('CameraPipelineManager: Pipeline started successfully');
    } catch (e) {
      debugPrint('CameraPipelineManager: Failed to start pipeline: $e');
      _emitStatus(PipelineStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Stop the camera pipeline
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      debugPrint('CameraPipelineManager: Stopping pipeline...');

      _emitStatus(PipelineStatus.stopping);

      _isRunning = false;

      // Cancel stream subscriptions to stop processing
      await _cameraImageSubscription?.cancel();
      await _processedFrameSubscription?.cancel();
      _cameraImageSubscription = null;
      _processedFrameSubscription = null;

      // Stop camera streaming
      await _cameraService.stopStreaming();

      // Clear any pending frame processing
      _poseService.clearProcessing();

      _emitStatus(PipelineStatus.stopped);

      debugPrint('CameraPipelineManager: Pipeline stopped successfully');
    } catch (e) {
      debugPrint('CameraPipelineManager: Failed to stop pipeline: $e');
      _emitStatus(PipelineStatus.error, error: e.toString());
    }
  }

  /// Force stop the camera pipeline (emergency stop)
  Future<void> forceStop() async {
    try {
      debugPrint('CameraPipelineManager: Force stopping pipeline...');
      _isRunning = false;
      await _cameraService.forceStop();
      _emitStatus(PipelineStatus.stopped);
      debugPrint('CameraPipelineManager: Pipeline force stopped');
    } catch (e) {
      debugPrint('CameraPipelineManager: Error during force stop: $e');
    }
  }

  /// Switch camera
  Future<void> switchCamera({int cameraIndex = 0}) async {
    if (!_isInitialized) {
      throw Exception('Pipeline not initialized');
    }

    try {
      debugPrint('CameraPipelineManager: Switching camera...');

      final wasRunning = _isRunning;

      if (wasRunning) {
        await stop();
      }

      await _cameraService.switchCamera(cameraIndex: cameraIndex);

      if (wasRunning) {
        await start(cameraIndex: cameraIndex);
      }

      debugPrint('CameraPipelineManager: Camera switched successfully');
    } catch (e) {
      debugPrint('CameraPipelineManager: Failed to switch camera: $e');
      _emitStatus(PipelineStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Update configuration
  Future<void> updateConfig(PoseEstimationConfig config) async {
    if (!_isInitialized) {
      throw Exception('Pipeline not initialized');
    }

    try {
      debugPrint('CameraPipelineManager: Updating configuration...');

      _config = config;

      // Update frame processor configuration
      _frameProcessor.updateConfig(config);

      // Update pose estimation service configuration
      await _poseService.switchModel(config);

      debugPrint('CameraPipelineManager: Configuration updated successfully');
    } catch (e) {
      debugPrint('CameraPipelineManager: Failed to update configuration: $e');
      _emitStatus(PipelineStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Get camera preview widget
  Widget? getCameraPreview() {
    return _cameraService.getPreviewWidget();
  }

  /// Get processing statistics
  Map<String, dynamic> _getProcessingStats() {
    return {
      'camera': _cameraService.getCameraInfo(),
      'frameProcessor': _frameProcessor.getProcessingStats(),
      'poseService': _poseService.isInitialized
          ? 'initialized'
          : 'not initialized',
    };
  }

  /// Get comprehensive pipeline information
  Map<String, dynamic> getPipelineInfo() {
    return {
      'isInitialized': _isInitialized,
      'isRunning': _isRunning,
      'config': _config?.toMap(),
      'processingStats': _getProcessingStats(),
    };
  }

  /// Emit pipeline status
  void _emitStatus(PipelineStatus status, {String? error}) {
    _statusController.add(status);
    debugPrint(
      'CameraPipelineManager: Status changed to $status${error != null ? ' - $error' : ''}',
    );
  }

  /// Emit pipeline result
  void _emitResult(PipelineResult result) {
    _resultController.add(result);
  }

  /// Dispose the camera pipeline
  Future<void> dispose() async {
    await stop();

    await _cameraImageSubscription?.cancel();
    await _processedFrameSubscription?.cancel();
    await _cameraStatusSubscription?.cancel();

    await _cameraService.dispose();
    await _frameProcessor.dispose();
    await _poseService.dispose();

    await _statusController.close();
    await _resultController.close();

    _isInitialized = false;
    debugPrint('CameraPipelineManager: Disposed');
  }
}

/// Pipeline status enumeration
enum PipelineStatus {
  initializing,
  initialized,
  starting,
  running,
  stopping,
  stopped,
  error,
  disposed,
}

/// Pipeline result data structure
class PipelineResult {
  final PoseData poseData;
  final DateTime timestamp;
  final Map<String, dynamic> processingStats;

  const PipelineResult({
    required this.poseData,
    required this.timestamp,
    required this.processingStats,
  });

  /// Get processing latency
  Duration get processingLatency => timestamp.difference(
    DateTime.fromMillisecondsSinceEpoch(poseData.timestamp.toInt()),
  );

  /// Get FPS from processing stats
  double get fps {
    final frameStats =
        processingStats['frameProcessor'] as Map<String, dynamic>?;
    return frameStats?['processingFps']?.toDouble() ?? 0.0;
  }

  /// Get drop rate from processing stats
  double get dropRate {
    final frameStats =
        processingStats['frameProcessor'] as Map<String, dynamic>?;
    return frameStats?['dropRate']?.toDouble() ?? 0.0;
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';

import '../models/pose_estimation_config.dart';

/// Service for processing camera frames for ML Kit pose estimation
class FrameProcessor {
  static FrameProcessor? _instance;
  static FrameProcessor get instance => _instance ??= FrameProcessor._();

  FrameProcessor._();

  PoseEstimationConfig? _config;
  bool _isInitialized = false;
  int _processedFrames = 0;
  int _droppedFrames = 0;
  DateTime _lastProcessTime = DateTime.now();

  /// Stream controller for processed frames
  final StreamController<CameraImage> _processedFrameController =
      StreamController<CameraImage>.broadcast();

  /// Stream of processed frames ready for pose estimation
  Stream<CameraImage> get processedFrameStream =>
      _processedFrameController.stream;

  /// Returns true if the frame processor is initialized
  bool get isInitialized => _isInitialized;

  /// Returns the number of processed frames
  int get processedFrames => _processedFrames;

  /// Returns the number of dropped frames
  int get droppedFrames => _droppedFrames;

  /// Returns the current processing FPS
  double get processingFps {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastProcessTime).inMilliseconds;
    if (timeDiff > 0) {
      return 1000.0 / timeDiff;
    }
    return 0.0;
  }

  /// Initialize the frame processor with configuration
  Future<void> initialize(PoseEstimationConfig config) async {
    _config = config;
    _isInitialized = true;
    _processedFrames = 0;
    _droppedFrames = 0;
    _lastProcessTime = DateTime.now();

    debugPrint('FrameProcessor: Initialized with ${config.performanceMode}');
  }

  /// Process a camera frame for pose estimation
  Future<void> processFrame(CameraImage frame) async {
    debugPrint(
      'FrameProcessor: Received frame ${_processedFrames + _droppedFrames + 1}',
    );

    if (!_isInitialized || _config == null) {
      _droppedFrames++;
      debugPrint(
        'FrameProcessor: Dropped frame - not initialized or no config',
      );
      return;
    }

    try {
      // Check if we should process this frame (frame rate control)
      if (!_shouldProcessFrame()) {
        _droppedFrames++;
        debugPrint('FrameProcessor: Dropped frame - frame rate control');
        return;
      }

      // ML Kit handles image preprocessing internally, so we just pass the frame
      // Emit the processed frame
      debugPrint(
        'FrameProcessor: Emitting processed frame (${frame.width}x${frame.height})',
      );
      _processedFrameController.add(frame);

      _processedFrames++;
      _lastProcessTime = DateTime.now();
    } catch (e) {
      debugPrint('FrameProcessor: Failed to process frame: $e');
      _droppedFrames++;
    }
  }

  /// Check if we should process this frame based on frame rate control
  bool _shouldProcessFrame() {
    if (_config == null) return false;

    // Temporarily disable frame skipping to debug continuous processing
    // TODO: Re-enable frame rate control once continuous processing is working
    const shouldProcess = true; // Process every frame for now

    debugPrint(
      'FrameProcessor: Frame ${_processedFrames}, shouldProcess: $shouldProcess',
    );

    return shouldProcess;
  }

  /// Update configuration
  void updateConfig(PoseEstimationConfig config) {
    _config = config;
    debugPrint(
      'FrameProcessor: Configuration updated to ${config.performanceMode}',
    );
  }

  /// Get processing statistics
  Map<String, dynamic> getProcessingStats() {
    final totalFrames = _processedFrames + _droppedFrames;
    final dropRate = totalFrames > 0
        ? (_droppedFrames / totalFrames) * 100
        : 0.0;

    return {
      'isInitialized': _isInitialized,
      'processedFrames': _processedFrames,
      'droppedFrames': _droppedFrames,
      'totalFrames': totalFrames,
      'dropRate': dropRate,
      'processingFps': processingFps,
      'config': _config?.performanceMode.name,
    };
  }

  /// Reset statistics
  void resetStats() {
    _processedFrames = 0;
    _droppedFrames = 0;
    _lastProcessTime = DateTime.now();
  }

  /// Dispose the frame processor
  Future<void> dispose() async {
    await _processedFrameController.close();
    _isInitialized = false;
    _config = null;
    debugPrint('FrameProcessor: Disposed');
  }
}

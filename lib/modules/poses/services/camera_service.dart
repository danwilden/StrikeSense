import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pose_estimation_service.dart';

/// Service for managing camera operations and frame capture
class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();

  CameraService._();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isStreaming = false;

  /// Stream controller for camera frames
  final StreamController<CameraFrame> _frameStreamController =
      StreamController<CameraFrame>.broadcast();

  /// Stream controller for camera status updates
  final StreamController<CameraStatus> _statusStreamController =
      StreamController<CameraStatus>.broadcast();

  /// Stream of camera frames
  Stream<CameraFrame> get frameStream => _frameStreamController.stream;

  /// Stream controller for camera images (for ML Kit)
  final StreamController<CameraImage> _imageStreamController =
      StreamController<CameraImage>.broadcast();

  /// Stream of camera images (for ML Kit)
  Stream<CameraImage> get imageStream => _imageStreamController.stream;

  /// Stream of camera status updates
  Stream<CameraStatus> get statusStream => _statusStreamController.stream;

  /// Returns the current camera controller
  CameraController? get controller => _controller;

  /// Returns true if the camera service is initialized
  bool get isInitialized => _isInitialized;

  /// Returns true if the camera is currently streaming
  bool get isStreaming => _isStreaming;

  /// Returns the list of available cameras
  List<CameraDescription> get cameras => _cameras;

  /// Returns the currently selected camera
  CameraDescription? get currentCamera => _controller?.description;

  /// Initialize the camera service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('CameraService: Initializing...');

      // Check camera permission
      await _checkCameraPermission();

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      debugPrint('CameraService: Found ${_cameras.length} cameras');

      _isInitialized = true;
      _emitStatus(CameraStatus.initialized);

      debugPrint('CameraService: Successfully initialized');
    } catch (e) {
      debugPrint('CameraService: Failed to initialize: $e');
      _emitStatus(CameraStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Check and request camera permission
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        throw Exception('Camera permission denied');
      }
    }

    if (status.isPermanentlyDenied) {
      throw Exception(
        'Camera permission permanently denied. Please enable in settings.',
      );
    }
  }

  /// Start camera with specified camera index
  Future<void> startCamera({int cameraIndex = 1}) async {
    // Default to front camera (index 1)
    if (!_isInitialized) {
      throw Exception('Camera service not initialized');
    }

    if (cameraIndex >= _cameras.length) {
      throw Exception('Invalid camera index: $cameraIndex');
    }

    try {
      final selectedCamera = _cameras[cameraIndex];
      debugPrint(
        'CameraService: Starting camera ${selectedCamera.name} (${selectedCamera.lensDirection})...',
      );
      debugPrint(
        'CameraService: Available cameras: ${_cameras.map((c) => '${c.name} (${c.lensDirection})').join(', ')}',
      );

      // Dispose existing controller
      await _disposeController();

      // Create new controller with BGRA8888 format like working example
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high, // Use high resolution like working example
        enableAudio: false,
        imageFormatGroup:
            ImageFormatGroup.bgra8888, // Use BGRA8888 like working example
      );

      // Initialize the controller with timeout and better error handling
      debugPrint('CameraService: Initializing camera controller...');
      try {
        await _controller!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Camera initialization timed out after 10 seconds');
          },
        );
        debugPrint('CameraService: Camera controller initialized successfully');
      } catch (e) {
        debugPrint(
          'CameraService: Camera controller initialization failed: $e',
        );
        debugPrint('CameraService: Trying fallback configuration...');

        // Try with lower resolution as fallback
        await _disposeController();
        _controller = CameraController(
          selectedCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.bgra8888, // Keep BGRA8888 format
        );

        await _controller!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Camera fallback initialization also timed out');
          },
        );
        debugPrint(
          'CameraService: Camera controller initialized with fallback settings',
        );
      }

      // Start image stream
      await _startImageStream();

      _emitStatus(CameraStatus.started);

      debugPrint('CameraService: Camera started successfully');
    } catch (e) {
      debugPrint('CameraService: Failed to start camera: $e');
      _emitStatus(CameraStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Start the image stream for frame processing
  Future<void> _startImageStream() async {
    if (_controller == null) return;

    _isStreaming = true;
    _emitStatus(CameraStatus.streaming);

    // Set rotation in pose estimation service based on camera sensor orientation
    final poseService = PoseEstimationService.instance;
    poseService.setRotationFromSensorOrientation(
      _controller!.description.sensorOrientation,
    );

    _controller!.startImageStream((CameraImage image) {
      if (_isStreaming) {
        _processCameraImage(image);
      }
    });
  }

  /// Process camera image and emit frame
  void _processCameraImage(CameraImage image) {
    try {
      // Emit both CameraFrame and CameraImage for different consumers
      final frame = CameraFrame.fromCameraImage(image);
      _frameStreamController.add(frame);
      _imageStreamController.add(image);
    } catch (e) {
      debugPrint('CameraService: Failed to process camera image: $e');
    }
  }

  /// Stop camera streaming
  Future<void> stopStreaming() async {
    if (_controller != null && _isStreaming) {
      await _controller!.stopImageStream();
      _isStreaming = false;
      _emitStatus(CameraStatus.stopped);
      debugPrint('CameraService: Streaming stopped');
    }
  }

  /// Force stop camera (emergency stop)
  Future<void> forceStop() async {
    try {
      debugPrint('CameraService: Force stopping camera...');
      _isStreaming = false;
      await _disposeController();
      _emitStatus(CameraStatus.stopped);
      debugPrint('CameraService: Camera force stopped');
    } catch (e) {
      debugPrint('CameraService: Error during force stop: $e');
    }
  }

  /// Switch to a different camera
  Future<void> switchCamera({int cameraIndex = 0}) async {
    if (!_isInitialized) {
      throw Exception('Camera service not initialized');
    }

    final wasStreaming = _isStreaming;

    if (wasStreaming) {
      await stopStreaming();
    }

    await startCamera(cameraIndex: cameraIndex);

    if (wasStreaming) {
      await _startImageStream();
    }
  }

  /// Get camera preview widget
  Widget? getPreviewWidget() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    return CameraPreview(_controller!);
  }

  /// Take a single photo
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final image = await _controller!.takePicture();
      debugPrint('CameraService: Photo taken: ${image.path}');
      return image;
    } catch (e) {
      debugPrint('CameraService: Failed to take picture: $e');
      rethrow;
    }
  }

  /// Get camera information
  Map<String, dynamic> getCameraInfo() {
    return {
      'isInitialized': _isInitialized,
      'isStreaming': _isStreaming,
      'availableCameras': _cameras.length,
      'currentCamera': _controller?.description.name,
      'cameraLensDirection': _controller?.description.lensDirection.toString(),
      'resolution': _controller?.value.previewSize?.toString(),
    };
  }

  /// Dispose the camera service
  Future<void> dispose() async {
    await stopStreaming();
    await _disposeController();
    await _frameStreamController.close();
    await _imageStreamController.close();
    await _statusStreamController.close();
    _isInitialized = false;
    debugPrint('CameraService: Disposed');
  }

  /// Dispose the camera controller
  Future<void> _disposeController() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  /// Emit camera status update
  void _emitStatus(CameraStatus status, {String? error}) {
    _statusStreamController.add(status);
    debugPrint(
      'CameraService: Status changed to $status${error != null ? ' - $error' : ''}',
    );
  }
}

/// Camera status enumeration
enum CameraStatus {
  initializing,
  initialized,
  starting,
  started,
  streaming,
  stopping,
  stopped,
  error,
  disposed,
}

/// Camera frame data structure
class CameraFrame {
  final Uint8List yPlane;
  final Uint8List? uPlane;
  final Uint8List? vPlane;
  final int width;
  final int height;
  final int format;
  final DateTime timestamp;

  const CameraFrame({
    required this.yPlane,
    this.uPlane,
    this.vPlane,
    required this.width,
    required this.height,
    required this.format,
    required this.timestamp,
  });

  /// Create CameraFrame from CameraImage
  factory CameraFrame.fromCameraImage(CameraImage image) {
    return CameraFrame(
      yPlane: image.planes[0].bytes,
      uPlane: image.planes.length > 1 ? image.planes[1].bytes : null,
      vPlane: image.planes.length > 2 ? image.planes[2].bytes : null,
      width: image.width,
      height: image.height,
      format: image.format.raw,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to RGB bytes for pose estimation
  Uint8List toRgbBytes() {
    // For YUV420 format, we need to convert to RGB
    // This is a simplified conversion - in production, use proper YUV to RGB conversion
    final rgbBytes = Uint8List(width * height * 3);

    for (int i = 0; i < yPlane.length; i++) {
      final y = yPlane[i];
      final u = uPlane != null && i < uPlane!.length ? uPlane![i] : 128;
      final v = vPlane != null && i < vPlane!.length ? vPlane![i] : 128;

      // Simple YUV to RGB conversion
      final r = (y + 1.402 * (v - 128)).clamp(0, 255).round();
      final g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
          .clamp(0, 255)
          .round();
      final b = (y + 1.772 * (u - 128)).clamp(0, 255).round();

      final rgbIndex = i * 3;
      rgbBytes[rgbIndex] = r;
      rgbBytes[rgbIndex + 1] = g;
      rgbBytes[rgbIndex + 2] = b;
    }

    return rgbBytes;
  }

  /// Get frame size
  Size get size => Size(width.toDouble(), height.toDouble());

  /// Check if frame is valid
  bool get isValid => yPlane.isNotEmpty && width > 0 && height > 0;
}

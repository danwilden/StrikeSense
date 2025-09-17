import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../models/pose_data.dart';
import '../models/pose_keypoint.dart';
import '../models/pose_estimation_config.dart';
import '../core/pose_estimation_exceptions.dart';

/// Service for pose estimation using ML Kit Pose Detection
class PoseEstimationService {
  static PoseEstimationService? _instance;
  static PoseEstimationService get instance =>
      _instance ??= PoseEstimationService._();

  PoseEstimationService._();

  PoseDetector? _detector;
  PoseEstimationConfig? _config;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _processing = false;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  // Frame throttling for performance
  int _frameCounter = 0;
  int _throttleInterval =
      3; // Process every 3rd frame (10 FPS instead of 30 FPS)
  DateTime _lastProcessTime = DateTime.now();

  /// Stream controller for pose estimation results
  final StreamController<PoseData> _poseStreamController =
      StreamController<PoseData>.broadcast();

  /// Stream of pose estimation results
  Stream<PoseData> get poseStream => _poseStreamController.stream;

  /// Returns true if the service is initialized and ready
  bool get isInitialized => _isInitialized;

  /// Returns true if the service is currently loading a model
  bool get isLoading => _isLoading;

  /// Returns the current configuration
  PoseEstimationConfig? get config => _config;

  /// Returns the current detector
  PoseDetector? get detector => _detector;

  /// Set rotation from camera sensor orientation (like working example)
  void setRotationFromSensorOrientation(int sensorOrientation) {
    _rotation = _rotationFromDegrees(sensorOrientation);
    debugPrint(
      'PoseEstimationService: Set rotation to $_rotation from sensor orientation $sensorOrientation',
    );
  }

  /// Convert sensor orientation degrees to InputImageRotation (from working example)
  InputImageRotation _rotationFromDegrees(int sensorOrientation) {
    // ML Kit enum expects 0/90/180/270
    return InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;
  }

  /// Set frame throttling interval (higher = less processing, better performance)
  void setThrottleInterval(int interval) {
    _throttleInterval = interval.clamp(1, 10); // Between 1 and 10 frames
    debugPrint(
      'PoseEstimationService: Throttle interval set to $_throttleInterval',
    );
  }

  /// Get current throttling settings
  Map<String, dynamic> getThrottleSettings() {
    return {
      'throttleInterval': _throttleInterval,
      'frameCounter': _frameCounter,
      'lastProcessTime': _lastProcessTime.toIso8601String(),
    };
  }

  /// Initialize the pose estimation service with a specific configuration
  Future<void> initialize(PoseEstimationConfig config) async {
    if (_isLoading) {
      throw PoseEstimationException(
        'Service is already loading a model',
        PoseEstimationErrorType.alreadyLoading,
      );
    }

    if (_isInitialized && _config?.performanceMode == config.performanceMode) {
      debugPrint(
        'PoseEstimationService: Already initialized with same performance mode',
      );
      return;
    }

    _isLoading = true;
    try {
      debugPrint(
        'PoseEstimationService: Initializing with config: ${config.performanceMode}',
      );

      // Dispose existing detector
      await _detector?.close();

      // Create new detector with ML Kit options
      // Use settings from the working example
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode
            .stream, // Always use stream mode for real-time camera processing
        model: PoseDetectionModel
            .base, // Use base model like working example (faster)
      );

      debugPrint('PoseEstimationService: Creating detector with options:');
      debugPrint('  Mode: ${options.mode}');
      debugPrint('  Model: ${options.model}');

      _detector = PoseDetector(options: options);
      _config = config;
      _isInitialized = true;
      _isLoading = false;

      debugPrint('PoseEstimationService: Initialized successfully with ML Kit');
      debugPrint(
        'PoseEstimationService: Mode: ${config.performanceMode}, MinConfidence: ${config.minConfidence}',
      );
    } catch (e) {
      _isLoading = false;
      throw PoseEstimationException(
        'Failed to initialize pose estimation service: $e',
        PoseEstimationErrorType.modelLoadFailed,
      );
    }
  }

  /// Process image bytes and return pose estimation results
  Future<PoseData?> processImage(Uint8List imageBytes) async {
    if (!_isInitialized || _detector == null) {
      debugPrint('PoseEstimationService: Not initialized');
      return null;
    }

    try {
      // Create InputImage from bytes
      // For test images, we'll use a simple RGB format
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: const Size(192, 192),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888, // Use BGRA format for RGB data
          bytesPerRow: 192 * 4, // BGRA bytes per row (4 bytes per pixel)
        ),
      );

      // Process with ML Kit
      final poses = await _detector!.processImage(inputImage);

      // Convert to our PoseData format
      final poseData = _mapMLKitPosesToPoseDataFromBytes(poses, imageBytes);

      if (poseData != null) {
        _poseStreamController.add(poseData);
      }

      return poseData;
    } catch (e) {
      debugPrint('PoseEstimationService: Error processing image: $e');
      return null;
    }
  }

  /// Test ML Kit with a real image file (if available)
  Future<void> testWithRealImage() async {
    try {
      debugPrint('PoseEstimationService: Testing with real image approach...');

      // Create a more realistic test image with actual human-like features
      final width = 640;
      final height = 480;
      final testImageBytes = Uint8List(width * height * 4);

      // Create a more realistic human silhouette
      final centerX = width ~/ 2;
      final centerY = height ~/ 2;

      // Fill background with light gray
      for (int i = 0; i < testImageBytes.length; i += 4) {
        testImageBytes[i] = 200; // B
        testImageBytes[i + 1] = 200; // G
        testImageBytes[i + 2] = 200; // R
        testImageBytes[i + 3] = 255; // A
      }

      // Draw a more detailed human figure
      _drawHumanFigure(testImageBytes, width, height, centerX, centerY);

      final inputImage = InputImage.fromBytes(
        bytes: testImageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final startTime = DateTime.now();
      final poses = await _detector!.processImage(inputImage);
      final endTime = DateTime.now();

      debugPrint(
        'PoseEstimationService: Realistic image test result: ${poses.length} poses in ${endTime.difference(startTime).inMilliseconds}ms',
      );

      // Save the test image
      await _saveDebugImage(testImageBytes, 'realistic_human_test.raw');
    } catch (e) {
      debugPrint('PoseEstimationService: Realistic image test failed: $e');
    }
  }

  /// Draw a more detailed human figure for testing
  void _drawHumanFigure(
    Uint8List bytes,
    int width,
    int height,
    int centerX,
    int centerY,
  ) {
    // Head (circle)
    for (int y = centerY - 80; y < centerY - 40; y++) {
      for (int x = centerX - 40; x < centerX + 40; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = (y * width + x) * 4;
          bytes[index] = 50; // B (dark)
          bytes[index + 1] = 50; // G (dark)
          bytes[index + 2] = 50; // R (dark)
        }
      }
    }

    // Body (rectangle)
    for (int y = centerY - 40; y < centerY + 120; y++) {
      for (int x = centerX - 50; x < centerX + 50; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = (y * width + x) * 4;
          bytes[index] = 50; // B (dark)
          bytes[index + 1] = 50; // G (dark)
          bytes[index + 2] = 50; // R (dark)
        }
      }
    }

    // Arms
    for (int y = centerY - 20; y < centerY + 80; y++) {
      for (int x = centerX - 80; x < centerX - 50; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = (y * width + x) * 4;
          bytes[index] = 50; // B (dark)
          bytes[index + 1] = 50; // G (dark)
          bytes[index + 2] = 50; // R (dark)
        }
      }
      for (int x = centerX + 50; x < centerX + 80; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = (y * width + x) * 4;
          bytes[index] = 50; // B (dark)
          bytes[index + 1] = 50; // G (dark)
          bytes[index + 2] = 50; // R (dark)
        }
      }
    }

    // Legs
    for (int y = centerY + 120; y < centerY + 200; y++) {
      for (int x = centerX - 30; x < centerX - 10; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = (y * width + x) * 4;
          bytes[index] = 50; // B (dark)
          bytes[index + 1] = 50; // G (dark)
          bytes[index + 2] = 50; // R (dark)
        }
      }
      for (int x = centerX + 10; x < centerX + 30; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = (y * width + x) * 4;
          bytes[index] = 50; // B (dark)
          bytes[index + 1] = 50; // G (dark)
          bytes[index + 2] = 50; // R (dark)
        }
      }
    }
  }

  /// Test with different ML Kit models
  Future<void> testDifferentModels() async {
    if (!_isInitialized) {
      debugPrint('PoseEstimationService: Not initialized for model testing');
      return;
    }

    try {
      debugPrint('PoseEstimationService: Testing different ML Kit models...');

      // Test with realistic human image first
      await testWithRealImage();

      // Test with default model (no model specified)
      await _testWithModel(null, 'default');

      // Test with accurate model
      await _testWithModel(PoseDetectionModel.accurate, 'accurate');
    } catch (e) {
      debugPrint('PoseEstimationService: Model testing failed: $e');
    }
  }

  /// Test with a specific model
  Future<void> _testWithModel(
    PoseDetectionModel? model,
    String modelName,
  ) async {
    try {
      debugPrint('PoseEstimationService: Testing with $modelName model...');

      // Create a simple test image
      final width = 640;
      final height = 480;
      final testImageBytes = Uint8List(width * height * 4);

      // Fill with a simple pattern
      for (int i = 0; i < testImageBytes.length; i += 4) {
        testImageBytes[i] = 128; // B
        testImageBytes[i + 1] = 128; // G
        testImageBytes[i + 2] = 128; // R
        testImageBytes[i + 3] = 255; // A
      }

      // Create detector with specific model
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: model ?? PoseDetectionModel.accurate,
      );

      final testDetector = PoseDetector(options: options);

      final inputImage = InputImage.fromBytes(
        bytes: testImageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final startTime = DateTime.now();
      final poses = await testDetector.processImage(inputImage);
      final endTime = DateTime.now();

      debugPrint(
        'PoseEstimationService: $modelName model result: ${poses.length} poses in ${endTime.difference(startTime).inMilliseconds}ms',
      );

      // Clean up test detector
      await testDetector.close();
    } catch (e) {
      debugPrint('PoseEstimationService: $modelName model test failed: $e');
    }
  }

  /// Test the complete integration with camera and simplified approach
  Future<void> testCompleteIntegration() async {
    if (!_isInitialized || _detector == null) {
      debugPrint('PoseEstimationService: Not initialized for integration test');
      return;
    }

    try {
      debugPrint('PoseEstimationService: Testing complete integration...');

      // Test 1: Simplified approach with synthetic image
      await testSimplifiedApproach();

      // Test 2: Verify setup
      final setupResults = await verifySetup();
      debugPrint('PoseEstimationService: Setup verification: $setupResults');

      // Test 3: Test with different models
      await testDifferentModels();

      debugPrint('PoseEstimationService: Complete integration test finished');
    } catch (e) {
      debugPrint('PoseEstimationService: Integration test failed: $e');
    }
  }

  /// Test the simplified approach with a realistic BGRA image
  Future<void> testSimplifiedApproach() async {
    if (!_isInitialized || _detector == null) {
      debugPrint('PoseEstimationService: Not initialized for simplified test');
      return;
    }

    try {
      debugPrint('PoseEstimationService: Testing simplified approach...');

      // Create a realistic BGRA test image (like the working example)
      final width = 640;
      final height = 480;
      final testImageBytes = Uint8List(width * height * 4);

      // Fill with background color (light gray)
      for (int i = 0; i < testImageBytes.length; i += 4) {
        testImageBytes[i] = 200; // B
        testImageBytes[i + 1] = 200; // G
        testImageBytes[i + 2] = 200; // R
        testImageBytes[i + 3] = 255; // A
      }

      // Draw a simple human-like silhouette
      final centerX = width ~/ 2;
      final centerY = height ~/ 2;

      // Head (circle)
      for (int y = centerY - 60; y < centerY - 20; y++) {
        for (int x = centerX - 30; x < centerX + 30; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final index = (y * width + x) * 4;
            testImageBytes[index] = 50; // B (dark)
            testImageBytes[index + 1] = 50; // G (dark)
            testImageBytes[index + 2] = 50; // R (dark)
          }
        }
      }

      // Body (rectangle)
      for (int y = centerY - 20; y < centerY + 100; y++) {
        for (int x = centerX - 40; x < centerX + 40; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final index = (y * width + x) * 4;
            testImageBytes[index] = 50; // B (dark)
            testImageBytes[index + 1] = 50; // G (dark)
            testImageBytes[index + 2] = 50; // R (dark)
          }
        }
      }

      // Create InputImage using the simplified approach
      final inputImage = InputImage.fromBytes(
        bytes: testImageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: _rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final startTime = DateTime.now();
      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: Simplified test timed out');
              return <Pose>[];
            },
          );
      final endTime = DateTime.now();

      debugPrint(
        'PoseEstimationService: Simplified approach test result: ${poses.length} poses in ${endTime.difference(startTime).inMilliseconds}ms',
      );

      // Save the test image
      await _saveDebugImage(testImageBytes, 'simplified_test.raw');
    } catch (e) {
      debugPrint('PoseEstimationService: Simplified approach test failed: $e');
    }
  }

  /// Test ML Kit with a simple solid color image (should fail gracefully)
  Future<void> testMLKitBasic() async {
    if (!_isInitialized || _detector == null) {
      debugPrint('PoseEstimationService: Not initialized for basic test');
      return;
    }

    try {
      debugPrint(
        'PoseEstimationService: Testing ML Kit with solid color image...',
      );

      // Create a simple solid color image (640x480 BGRA)
      final width = 640;
      final height = 480;
      final testImageBytes = Uint8List(width * height * 4);

      // Fill with solid blue color
      for (int i = 0; i < testImageBytes.length; i += 4) {
        testImageBytes[i] = 255; // B (blue)
        testImageBytes[i + 1] = 0; // G
        testImageBytes[i + 2] = 0; // R
        testImageBytes[i + 3] = 255; // A
      }

      final inputImage = InputImage.fromBytes(
        bytes: testImageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: Basic test timed out');
              return <Pose>[];
            },
          );

      debugPrint(
        'PoseEstimationService: Basic test result: ${poses.length} poses (expected: 0)',
      );

      // Save the test image for inspection
      await _saveDebugImage(testImageBytes, 'basic_test_solid_blue.raw');
    } catch (e) {
      debugPrint('PoseEstimationService: Basic test failed: $e');
    }
  }

  /// Test pose detection with a simple synthetic image
  Future<void> testPoseDetection() async {
    if (!_isInitialized || _detector == null) {
      debugPrint('PoseEstimationService: Not initialized for test');
      return;
    }

    try {
      // Create a more realistic test image (640x480 BGRA) with a simple human-like shape
      final width = 640;
      final height = 480;
      final testImageBytes = Uint8List(width * height * 4);

      // Fill with background color (light gray)
      for (int i = 0; i < testImageBytes.length; i += 4) {
        testImageBytes[i] = 200; // B
        testImageBytes[i + 1] = 200; // G
        testImageBytes[i + 2] = 200; // R
        testImageBytes[i + 3] = 255; // A
      }

      // Draw a simple human-like silhouette in the center
      final centerX = width ~/ 2;
      final centerY = height ~/ 2;

      // Head (circle)
      for (int y = centerY - 60; y < centerY - 20; y++) {
        for (int x = centerX - 30; x < centerX + 30; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final index = (y * width + x) * 4;
            testImageBytes[index] = 50; // B (dark)
            testImageBytes[index + 1] = 50; // G (dark)
            testImageBytes[index + 2] = 50; // R (dark)
          }
        }
      }

      // Body (rectangle)
      for (int y = centerY - 20; y < centerY + 100; y++) {
        for (int x = centerX - 40; x < centerX + 40; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final index = (y * width + x) * 4;
            testImageBytes[index] = 50; // B (dark)
            testImageBytes[index + 1] = 50; // G (dark)
            testImageBytes[index + 2] = 50; // R (dark)
          }
        }
      }

      final inputImage = InputImage.fromBytes(
        bytes: testImageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      debugPrint(
        'PoseEstimationService: Testing pose detection with human-like synthetic image...',
      );
      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: Synthetic test timed out');
              return <Pose>[];
            },
          );
      debugPrint(
        'PoseEstimationService: Test result: ${poses.length} poses detected',
      );

      // Also test with a simple grayscale image
      await _testWithGrayscaleImage();

      // Test with different image formats
      await _testWithDifferentFormats();
    } catch (e) {
      debugPrint('PoseEstimationService: Test failed: $e');
    }
  }

  /// Test with different image formats to identify format issues
  Future<void> _testWithDifferentFormats() async {
    try {
      debugPrint('PoseEstimationService: Testing different image formats...');

      // Test 1: YUV420 format (like camera)
      await _testYUV420Format();

      // Test 2: RGB format
      await _testRGBFormat();
    } catch (e) {
      debugPrint('PoseEstimationService: Format tests failed: $e');
    }
  }

  /// Test with YUV420 format
  Future<void> _testYUV420Format() async {
    try {
      debugPrint('PoseEstimationService: Testing YUV420 format...');

      final width = 640;
      final height = 480;
      final yPlane = Uint8List(width * height);

      // Fill Y plane with gradient
      for (int i = 0; i < yPlane.length; i++) {
        yPlane[i] = (i % 256);
      }

      final inputImage = InputImage.fromBytes(
        bytes: yPlane,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: width,
        ),
      );

      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: YUV420 test timed out');
              return <Pose>[];
            },
          );

      debugPrint(
        'PoseEstimationService: YUV420 test result: ${poses.length} poses',
      );
      await _saveDebugImage(yPlane, 'test_yuv420.raw');
    } catch (e) {
      debugPrint('PoseEstimationService: YUV420 test failed: $e');
    }
  }

  /// Test with RGB format
  Future<void> _testRGBFormat() async {
    try {
      debugPrint('PoseEstimationService: Testing RGB format...');

      final width = 640;
      final height = 480;
      final rgbBytes = Uint8List(width * height * 3);

      // Fill with RGB gradient
      for (int i = 0; i < rgbBytes.length; i += 3) {
        rgbBytes[i] = (i % 256); // R
        rgbBytes[i + 1] = ((i + 1) % 256); // G
        rgbBytes[i + 2] = ((i + 2) % 256); // B
      }

      final inputImage = InputImage.fromBytes(
        bytes: rgbBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888, // Use BGRA format instead of RGB
          bytesPerRow: width * 3,
        ),
      );

      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: RGB test timed out');
              return <Pose>[];
            },
          );

      debugPrint(
        'PoseEstimationService: RGB test result: ${poses.length} poses',
      );
      await _saveDebugImage(rgbBytes, 'test_rgb.raw');
    } catch (e) {
      debugPrint('PoseEstimationService: RGB test failed: $e');
    }
  }

  /// Test with a simple grayscale image
  Future<void> _testWithGrayscaleImage() async {
    try {
      debugPrint('PoseEstimationService: Testing with grayscale image...');

      // Create a simple grayscale image (640x480)
      final testImageBytes = Uint8List(640 * 480);
      for (int i = 0; i < testImageBytes.length; i++) {
        testImageBytes[i] = 128; // Gray value
      }

      final inputImage = InputImage.fromBytes(
        bytes: testImageBytes,
        metadata: InputImageMetadata(
          size: const Size(640, 480),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420, // Use YUV420 format
          bytesPerRow: 640,
        ),
      );

      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: Grayscale test timed out');
              return <Pose>[];
            },
          );
      debugPrint(
        'PoseEstimationService: Grayscale test result: ${poses.length} poses detected',
      );
    } catch (e) {
      debugPrint('PoseEstimationService: Grayscale test failed: $e');
    }
  }

  /// Process a camera frame and return pose estimation results
  Future<PoseData?> processFrame(CameraImage cameraImage) async {
    if (!_isInitialized || _detector == null) {
      debugPrint('PoseEstimationService: Not initialized');
      return null;
    }

    // Check if processing should continue (for cleanup after stop)
    if (_processing == false && _frameCounter == 0) {
      // This indicates we've been cleared, don't process
      return null;
    }

    // Frame throttling for performance
    _frameCounter++;
    if (_frameCounter % _throttleInterval != 0) {
      return null; // Skip this frame
    }

    // Prevent concurrent processing
    if (_processing) {
      debugPrint('PoseEstimationService: Already processing, skipping frame');
      return null;
    }
    _processing = true;

    try {
      // Convert camera image to input image using simplified approach
      final inputImage = _convertCameraImageToInputImageSimple(cameraImage);
      if (inputImage == null) {
        debugPrint('PoseEstimationService: Failed to convert camera image');
        return null;
      }

      // Process with ML Kit
      debugPrint('PoseEstimationService: Processing image with ML Kit...');
      debugPrint(
        'PoseEstimationService: InputImage size: ${inputImage.metadata?.size}',
      );
      debugPrint(
        'PoseEstimationService: InputImage format: ${inputImage.metadata?.format}',
      );
      debugPrint(
        'PoseEstimationService: InputImage bytesPerRow: ${inputImage.metadata?.bytesPerRow}',
      );
      debugPrint(
        'PoseEstimationService: Image bytes length: ${inputImage.bytes?.length}',
      );

      // Debug frame storage removed - no longer needed

      // Add timeout to prevent freezing
      final poses = await _detector!
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('PoseEstimationService: ML Kit processing timed out');
              return <Pose>[];
            },
          );
      debugPrint(
        'PoseEstimationService: ML Kit returned ${poses.length} poses',
      );

      // Debug: Print landmark details for first pose
      if (poses.isNotEmpty) {
        final pose = poses.first;
        debugPrint(
          'PoseEstimationService: First pose has ${pose.landmarks.length} landmarks',
        );
        for (final entry in pose.landmarks.entries.take(5)) {
          final landmark = entry.value;
          debugPrint(
            'PoseEstimationService: ${entry.key}: confidence=${landmark.likelihood.toStringAsFixed(3)}, pos=(${landmark.x.toStringAsFixed(3)}, ${landmark.y.toStringAsFixed(3)})',
          );
        }
      }

      // Convert to our PoseData format
      final poseData = _mapMLKitPosesToPoseData(poses, cameraImage);

      if (poseData != null) {
        debugPrint(
          'PoseEstimationService: Mapped to PoseData with ${poseData.visibleKeypoints.length} keypoints',
        );
        _poseStreamController.add(poseData);
      } else {
        debugPrint(
          'PoseEstimationService: No pose data created (poses: ${poses.length})',
        );
      }

      _lastProcessTime = DateTime.now();
      return poseData;
    } catch (e) {
      debugPrint('PoseEstimationService: Error processing frame: $e');
      return null;
    } finally {
      _processing = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit (simplified approach like working example)
  InputImage? _convertCameraImageToInputImageSimple(CameraImage cameraImage) {
    try {
      // Use the simplified approach from the working example
      // For BGRA8888 format, use the first plane directly
      if (cameraImage.planes.isNotEmpty) {
        final Plane plane = cameraImage.planes.first;
        final bytes = plane.bytes;

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(
              cameraImage.width.toDouble(),
              cameraImage.height.toDouble(),
            ),
            rotation: _rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: plane.bytesPerRow,
          ),
        );

        debugPrint(
          'PoseEstimationService: Converted camera image to InputImage (${cameraImage.width}x${cameraImage.height}) using direct BGRA plane',
        );
        return inputImage;
      } else {
        debugPrint(
          'PoseEstimationService: No planes available in camera image',
        );
        return null;
      }
    } catch (e) {
      debugPrint('PoseEstimationService: Failed to convert camera image: $e');
      return null;
    }
  }

  /// Map ML Kit poses to our PoseData format
  PoseData? _mapMLKitPosesToPoseData(
    List<Pose> poses,
    CameraImage cameraImage,
  ) {
    if (poses.isEmpty || _config == null) {
      return null;
    }

    // Use the first pose (ML Kit supports multi-pose, we use first)
    final pose = poses.first;
    final keypoints = <PoseKeypoint>[];

    // Map ML Kit landmarks to our keypoints
    // Use a more lenient confidence threshold like the Python app (0.5)
    final effectiveConfidence = _config!.minConfidence > 0.0
        ? _config!.minConfidence
        : 0.5;

    int index = 0;
    for (final landmark in pose.landmarks.values) {
      // Filter by confidence threshold - be more lenient for initial detection
      if (landmark.likelihood >= effectiveConfidence) {
        final keypointType = _mapMLKitLandmarkType(landmark.type);
        final keypoint = PoseKeypoint(
          x: landmark.x,
          y: landmark.y,
          confidence: landmark.likelihood,
          type: keypointType,
          name: keypointType.name,
          index: index,
        );
        keypoints.add(keypoint);
      }
      index++;
    }

    debugPrint(
      'PoseEstimationService: Filtered ${keypoints.length} keypoints from ${pose.landmarks.length} landmarks (threshold: $effectiveConfidence)',
    );

    return PoseData(
      keypoints: keypoints,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      modelVersion: 'mlkit_pose_detection',
      confidenceThreshold: _config!.minConfidence,
      imageWidth: cameraImage.width,
      imageHeight: cameraImage.height,
    );
  }

  /// Map ML Kit poses to our PoseData format from bytes
  PoseData? _mapMLKitPosesToPoseDataFromBytes(
    List<Pose> poses,
    Uint8List imageBytes,
  ) {
    if (poses.isEmpty || _config == null) {
      return null;
    }

    // Use the first pose (ML Kit supports multi-pose, we use first)
    final pose = poses.first;
    final keypoints = <PoseKeypoint>[];

    // Map ML Kit landmarks to our keypoints
    // Use a more lenient confidence threshold like the Python app (0.5)
    final effectiveConfidence = _config!.minConfidence > 0.0
        ? _config!.minConfidence
        : 0.5;

    int index = 0;
    for (final landmark in pose.landmarks.values) {
      // Filter by confidence threshold - be more lenient for initial detection
      if (landmark.likelihood >= effectiveConfidence) {
        final keypointType = _mapMLKitLandmarkType(landmark.type);
        final keypoint = PoseKeypoint(
          x: landmark.x,
          y: landmark.y,
          confidence: landmark.likelihood,
          type: keypointType,
          name: keypointType.name,
          index: index,
        );
        keypoints.add(keypoint);
      }
      index++;
    }

    debugPrint(
      'PoseEstimationService: Filtered ${keypoints.length} keypoints from ${pose.landmarks.length} landmarks (threshold: $effectiveConfidence)',
    );

    return PoseData(
      keypoints: keypoints,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      modelVersion: 'mlkit_pose_detection',
      confidenceThreshold: _config!.minConfidence,
      imageWidth: 192, // Default width for test images
      imageHeight: 192, // Default height for test images
    );
  }

  /// Map ML Kit landmark type to our keypoint type
  PoseKeypointType _mapMLKitLandmarkType(PoseLandmarkType mlKitType) {
    switch (mlKitType) {
      case PoseLandmarkType.nose:
        return PoseKeypointType.nose;
      case PoseLandmarkType.leftEyeInner:
      case PoseLandmarkType.leftEye:
      case PoseLandmarkType.leftEyeOuter:
        return PoseKeypointType.leftEye;
      case PoseLandmarkType.rightEyeInner:
      case PoseLandmarkType.rightEye:
      case PoseLandmarkType.rightEyeOuter:
        return PoseKeypointType.rightEye;
      case PoseLandmarkType.leftEar:
        return PoseKeypointType.leftEar;
      case PoseLandmarkType.rightEar:
        return PoseKeypointType.rightEar;
      case PoseLandmarkType.leftMouth:
      case PoseLandmarkType.rightMouth:
        return PoseKeypointType.mouth;
      case PoseLandmarkType.leftShoulder:
        return PoseKeypointType.leftShoulder;
      case PoseLandmarkType.rightShoulder:
        return PoseKeypointType.rightShoulder;
      case PoseLandmarkType.leftElbow:
        return PoseKeypointType.leftElbow;
      case PoseLandmarkType.rightElbow:
        return PoseKeypointType.rightElbow;
      case PoseLandmarkType.leftWrist:
        return PoseKeypointType.leftWrist;
      case PoseLandmarkType.rightWrist:
        return PoseKeypointType.rightWrist;
      case PoseLandmarkType.leftPinky:
        return PoseKeypointType.leftPinky;
      case PoseLandmarkType.rightPinky:
        return PoseKeypointType.rightPinky;
      case PoseLandmarkType.leftIndex:
        return PoseKeypointType.leftIndex;
      case PoseLandmarkType.rightIndex:
        return PoseKeypointType.rightIndex;
      case PoseLandmarkType.leftThumb:
        return PoseKeypointType.leftThumb;
      case PoseLandmarkType.rightThumb:
        return PoseKeypointType.rightThumb;
      case PoseLandmarkType.leftHip:
        return PoseKeypointType.leftHip;
      case PoseLandmarkType.rightHip:
        return PoseKeypointType.rightHip;
      case PoseLandmarkType.leftKnee:
        return PoseKeypointType.leftKnee;
      case PoseLandmarkType.rightKnee:
        return PoseKeypointType.rightKnee;
      case PoseLandmarkType.leftAnkle:
        return PoseKeypointType.leftAnkle;
      case PoseLandmarkType.rightAnkle:
        return PoseKeypointType.rightAnkle;
      case PoseLandmarkType.leftHeel:
        return PoseKeypointType.leftHeel;
      case PoseLandmarkType.rightHeel:
        return PoseKeypointType.rightHeel;
      case PoseLandmarkType.leftFootIndex:
        return PoseKeypointType.leftFootIndex;
      case PoseLandmarkType.rightFootIndex:
        return PoseKeypointType.rightFootIndex;
    }
  }

  /// Switch model (update configuration)
  Future<void> switchModel(PoseEstimationConfig newConfig) async {
    await initialize(newConfig);
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'config': _config?.toMap(),
      'detector': _detector != null ? 'initialized' : 'not initialized',
      'modelType': 'mlkit_pose_detection',
      'landmarks': 33,
    };
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'performanceMode': _config?.performanceMode.name ?? 'unknown',
      'minConfidence': _config?.minConfidence ?? 0.0,
      'smoothingEnabled': _config?.smoothing.enabled ?? false,
      'maxPoses': _config?.maxPoses ?? 1,
    };
  }

  /// Verify ML Kit setup and configuration
  Future<Map<String, dynamic>> verifySetup() async {
    final results = <String, dynamic>{};

    try {
      // Check initialization
      results['isInitialized'] = _isInitialized;
      results['detectorExists'] = _detector != null;
      results['configExists'] = _config != null;

      if (_config != null) {
        results['config'] = {
          'performanceMode': _config!.performanceMode.name,
          'minConfidence': _config!.minConfidence,
          'smoothingEnabled': _config!.smoothing.enabled,
          'maxPoses': _config!.maxPoses,
        };
      }

      // Test with a simple image
      if (_isInitialized && _detector != null) {
        debugPrint('PoseEstimationService: Verifying ML Kit setup...');

        // Create a simple test image
        final testBytes = Uint8List(100 * 100 * 4); // 100x100 BGRA
        for (int i = 0; i < testBytes.length; i += 4) {
          testBytes[i] = 128; // B
          testBytes[i + 1] = 128; // G
          testBytes[i + 2] = 128; // R
          testBytes[i + 3] = 255; // A
        }

        final testImage = InputImage.fromBytes(
          bytes: testBytes,
          metadata: InputImageMetadata(
            size: const Size(100, 100),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: 100 * 4,
          ),
        );

        final startTime = DateTime.now();
        final poses = await _detector!.processImage(testImage);
        final endTime = DateTime.now();

        results['testResult'] = {
          'posesDetected': poses.length,
          'processingTimeMs': endTime.difference(startTime).inMilliseconds,
          'success': true,
        };

        debugPrint(
          'PoseEstimationService: Setup verification - ${poses.length} poses in ${endTime.difference(startTime).inMilliseconds}ms',
        );
      } else {
        results['testResult'] = {
          'success': false,
          'error': 'Not initialized or detector missing',
        };
      }
    } catch (e) {
      results['testResult'] = {'success': false, 'error': e.toString()};
      debugPrint('PoseEstimationService: Setup verification failed: $e');
    }

    return results;
  }

  /// Save debug image to file system for inspection
  Future<void> _saveDebugImage(Uint8List imageBytes, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final debugDir = Directory('${directory.path}/pose_debug');
      if (!await debugDir.exists()) {
        await debugDir.create(recursive: true);
      }

      final file = File('${debugDir.path}/$filename');
      await file.writeAsBytes(imageBytes);
      debugPrint('PoseEstimationService: Saved debug image to ${file.path}');

      // Also save a text file with image info
      final infoFile = File('${debugDir.path}/${filename}_info.txt');
      final imageSize = _estimateImageSize(imageBytes);
      final info =
          '''
Debug Image Information
======================
Filename: $filename
Size: ${imageBytes.length} bytes
Estimated dimensions: ${imageSize['width']}x${imageSize['height']}
Format: BGRA (4 bytes per pixel)
Created: ${DateTime.now().toIso8601String()}

To view this image:
1. The file is in raw BGRA format
2. You can use image viewers that support raw formats
3. Or convert it using online tools
4. Expected dimensions: ${imageSize['width']}x${imageSize['height']}
''';
      await infoFile.writeAsString(info);
    } catch (e) {
      debugPrint('PoseEstimationService: Failed to save debug image: $e');
    }
  }

  /// Estimate image dimensions from byte array
  Map<String, int> _estimateImageSize(Uint8List bytes) {
    // Assume BGRA format (4 bytes per pixel)
    final totalPixels = bytes.length ~/ 4;

    // Common aspect ratios
    final commonRatios = [
      {'width': 640, 'height': 480}, // 4:3
      {'width': 480, 'height': 640}, // 3:4 (portrait)
      {'width': 192, 'height': 192}, // 1:1 (square)
      {'width': 100, 'height': 100}, // 1:1 (small square)
    ];

    for (final ratio in commonRatios) {
      if (ratio['width']! * ratio['height']! == totalPixels) {
        return ratio;
      }
    }

    // If no exact match, try to estimate
    final sqrt = (totalPixels / 4).round();
    return {'width': sqrt, 'height': sqrt};
  }

  /// Clear any pending processing and reset state
  void clearProcessing() {
    _processing = false;
    _frameCounter = 0;
    debugPrint('PoseEstimationService: Cleared processing state');
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _poseStreamController.close();
    _isInitialized = false;
    _config = null;
  }
}

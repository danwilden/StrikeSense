import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:strikesense/modules/poses/models/pose_estimation_config.dart';
import 'package:strikesense/modules/poses/services/camera_service.dart';
import 'package:strikesense/modules/poses/services/frame_processor.dart';

void main() {
  group('FrameProcessor', () {
    late FrameProcessor frameProcessor;

    setUp(() {
      frameProcessor = FrameProcessor.instance;
    });

    tearDown(() async {
      await frameProcessor.dispose();
    });

    test('should be a singleton', () {
      final instance1 = FrameProcessor.instance;
      final instance2 = FrameProcessor.instance;
      expect(instance1, equals(instance2));
    });

    test('should start uninitialized', () {
      expect(frameProcessor.isInitialized, false);
      expect(frameProcessor.processedFrames, 0);
      expect(frameProcessor.droppedFrames, 0);
    });

    test('should initialize with configuration', () async {
      final config = PoseEstimationConfig.moveNetLightning();
      await frameProcessor.initialize(config);

      expect(frameProcessor.isInitialized, true);
      expect(frameProcessor.processedFrames, 0);
      expect(frameProcessor.droppedFrames, 0);
    });

    test('should update configuration', () async {
      final config1 = PoseEstimationConfig.moveNetLightning();
      await frameProcessor.initialize(config1);

      final config2 = PoseEstimationConfig.blazePoseLite();
      frameProcessor.updateConfig(config2);

      expect(frameProcessor.isInitialized, true);
    });

    test('should reset statistics', () async {
      final config = PoseEstimationConfig.moveNetLightning();
      await frameProcessor.initialize(config);

      frameProcessor.resetStats();

      expect(frameProcessor.processedFrames, 0);
      expect(frameProcessor.droppedFrames, 0);
    });

    test('should return processing statistics', () async {
      final config = PoseEstimationConfig.moveNetLightning();
      await frameProcessor.initialize(config);

      final stats = frameProcessor.getProcessingStats();

      expect(stats['isInitialized'], true);
      expect(stats['processedFrames'], 0);
      expect(stats['droppedFrames'], 0);
      expect(stats['totalFrames'], 0);
      expect(stats['dropRate'], 0.0);
      expect(stats['processingFps'], 0.0);
      expect(stats['config'], 'movenet_lightning');
    });
  });

  group('ProcessedFrame', () {
    test('should create ProcessedFrame with valid data', () {
      final originalFrame = CameraFrame(
        yPlane: Uint8List.fromList(List.generate(100, (index) => index % 256)),
        width: 10,
        height: 10,
        format: 0,
        timestamp: DateTime.now(),
      );

      final processedImage = Uint8List.fromList(
        List.generate(1000, (index) => index % 256),
      );
      final originalImage = img.Image(10, 10);
      final config = PoseEstimationConfig.moveNetLightning();

      final processedFrame = ProcessedFrame(
        originalFrame: originalFrame,
        processedImage: processedImage,
        originalImage: originalImage,
        config: config,
        timestamp: DateTime.now(),
      );

      expect(processedFrame.originalFrame, originalFrame);
      expect(processedFrame.processedImage, processedImage);
      expect(processedFrame.config, config);
      expect(processedFrame.processedSize.width, 192.0);
      expect(processedFrame.processedSize.height, 192.0);
    });
  });

  group('FrameQueueManager', () {
    late FrameQueueManager queueManager;

    setUp(() {
      queueManager = FrameQueueManager.instance;
    });

    test('should be a singleton', () {
      final instance1 = FrameQueueManager.instance;
      final instance2 = FrameQueueManager.instance;
      expect(instance1, equals(instance2));
    });

    test('should start with empty queue', () {
      final stats = queueManager.getQueueStats();
      expect(stats['queueSize'], 0);
      expect(stats['maxQueueSize'], 5);
      expect(stats['isProcessing'], false);
    });

    test('should clear queue', () {
      queueManager.clearQueue();
      final stats = queueManager.getQueueStats();
      expect(stats['queueSize'], 0);
    });
  });
}

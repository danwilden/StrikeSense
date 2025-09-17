import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:strikesense/modules/poses/services/camera_service.dart';

void main() {
  group('CameraService', () {
    late CameraService cameraService;

    setUp(() {
      cameraService = CameraService.instance;
    });

    tearDown(() async {
      await cameraService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = CameraService.instance;
      final instance2 = CameraService.instance;
      expect(instance1, equals(instance2));
    });

    test('should start uninitialized', () {
      expect(cameraService.isInitialized, false);
      expect(cameraService.isStreaming, false);
      expect(cameraService.controller, null);
    });

    test('should have empty cameras list initially', () {
      expect(cameraService.cameras, isEmpty);
    });

    test('should have null current camera initially', () {
      expect(cameraService.currentCamera, null);
    });
  });

  group('CameraFrame', () {
    test('should create CameraFrame with valid data', () {
      final yPlane = Uint8List.fromList(
        List.generate(100, (index) => index % 256),
      );
      final frame = CameraFrame(
        yPlane: yPlane,
        width: 10,
        height: 10,
        format: 0,
        timestamp: DateTime.now(),
      );

      expect(frame.yPlane, yPlane);
      expect(frame.width, 10);
      expect(frame.height, 10);
      expect(frame.format, 0);
      expect(frame.isValid, true);
    });

    test('should return invalid for empty frame', () {
      final frame = CameraFrame(
        yPlane: Uint8List(0),
        width: 0,
        height: 0,
        format: 0,
        timestamp: DateTime.now(),
      );

      expect(frame.isValid, false);
    });

    test('should return correct size', () {
      final frame = CameraFrame(
        yPlane: Uint8List.fromList(List.generate(100, (index) => index % 256)),
        width: 10,
        height: 10,
        format: 0,
        timestamp: DateTime.now(),
      );

      expect(frame.size.width, 10.0);
      expect(frame.size.height, 10.0);
    });

    test('should convert to RGB bytes', () {
      final yPlane = Uint8List.fromList(List.generate(100, (index) => 128));
      final uPlane = Uint8List.fromList(List.generate(100, (index) => 128));
      final vPlane = Uint8List.fromList(List.generate(100, (index) => 128));

      final frame = CameraFrame(
        yPlane: yPlane,
        uPlane: uPlane,
        vPlane: vPlane,
        width: 10,
        height: 10,
        format: 0,
        timestamp: DateTime.now(),
      );

      final rgbBytes = frame.toRgbBytes();
      expect(rgbBytes.length, 300); // 10 * 10 * 3
    });
  });

  group('CameraStatus', () {
    test('should have all expected status values', () {
      expect(CameraStatus.values, contains(CameraStatus.initializing));
      expect(CameraStatus.values, contains(CameraStatus.initialized));
      expect(CameraStatus.values, contains(CameraStatus.starting));
      expect(CameraStatus.values, contains(CameraStatus.started));
      expect(CameraStatus.values, contains(CameraStatus.streaming));
      expect(CameraStatus.values, contains(CameraStatus.stopping));
      expect(CameraStatus.values, contains(CameraStatus.stopped));
      expect(CameraStatus.values, contains(CameraStatus.error));
      expect(CameraStatus.values, contains(CameraStatus.disposed));
    });
  });
}

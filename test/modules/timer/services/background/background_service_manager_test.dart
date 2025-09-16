import 'package:flutter_test/flutter_test.dart';
import 'package:strikesense/modules/timer/services/background/background_service_manager.dart';

void main() {
  group('BackgroundServiceManager', () {
    late BackgroundServiceManager manager;

    setUp(() {
      manager = BackgroundServiceManager.instance;
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('should initialize successfully', () async {
      await manager.initialize();
      expect(manager.isInitialized, isTrue);
    });

    test('should start and stop background operation', () async {
      await manager.initialize();
      expect(manager.isInitialized, isTrue);

      await manager.startBackgroundOperation();
      // Service should still be initialized after starting
      expect(manager.isInitialized, isTrue);

      await manager.stopBackgroundOperation();
      // Service should still be initialized after stopping
      expect(manager.isInitialized, isTrue);
    });

    test('should update timer state', () async {
      await manager.initialize();

      await manager.updateTimerState(
        title: 'Test Timer',
        content: 'Test Content',
        remainingTime: const Duration(minutes: 5),
        currentRound: 1,
        isWorkPeriod: true,
      );

      // No exceptions should be thrown
      expect(true, isTrue);
    });

    test('should handle multiple initializations gracefully', () async {
      await manager.initialize();
      await manager.initialize(); // Should not throw

      expect(manager.isInitialized, isTrue);
    });
  });
}

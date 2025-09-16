import 'dart:async';
import 'dart:io';

import 'android_background_service.dart';
import 'background_service.dart';
import 'ios_background_service.dart';

/// Platform-agnostic background service manager
class BackgroundServiceManager {
  static BackgroundServiceManager? _instance;
  static BackgroundServiceManager get instance =>
      _instance ??= BackgroundServiceManager._();

  BackgroundServiceManager._();

  BackgroundService? _backgroundService;
  StreamSubscription<BackgroundServiceEvent>? _eventSubscription;

  /// Initialize the appropriate background service for the current platform
  Future<void> initialize() async {
    if (_backgroundService != null) return;

    if (Platform.isAndroid) {
      _backgroundService = AndroidBackgroundService();
    } else if (Platform.isIOS) {
      _backgroundService = IOSBackgroundService();
    } else {
      // For other platforms, create a no-op service
      _backgroundService = NoOpBackgroundService();
    }

    await _backgroundService!.initialize();
    _setupEventSubscription();
  }

  void _setupEventSubscription() {
    _eventSubscription = _backgroundService!.events.listen((event) {
      // Handle background service events
      switch (event) {
        case BackgroundServiceStarted _:
          // Background service started
          break;
        case BackgroundServiceStopped _:
          // Background service stopped
          break;
        case BackgroundServiceError _:
          // Background service error occurred
          break;
      }
    });
  }

  /// Start background operation
  Future<void> startBackgroundOperation() async {
    if (_backgroundService == null) {
      throw StateError('Background service not initialized');
    }
    await _backgroundService!.startBackgroundOperation();
  }

  /// Stop background operation
  Future<void> stopBackgroundOperation() async {
    if (_backgroundService == null) return;
    await _backgroundService!.stopBackgroundOperation();
  }

  /// Update timer state in background
  Future<void> updateTimerState({
    required String title,
    required String content,
    required Duration remainingTime,
    required int currentRound,
    required bool isWorkPeriod,
  }) async {
    if (_backgroundService == null) return;

    await _backgroundService!.updateTimerState(
      title: title,
      content: content,
      remainingTime: remainingTime,
      currentRound: currentRound,
      isWorkPeriod: isWorkPeriod,
    );
  }

  /// Check if background service is initialized
  bool get isInitialized => _backgroundService != null;

  /// Get background service events stream
  Stream<BackgroundServiceEvent>? get events => _backgroundService?.events;

  /// Dispose resources
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _backgroundService?.dispose();
    _backgroundService = null;
  }
}

/// No-op background service for unsupported platforms
class NoOpBackgroundService implements BackgroundService {
  final StreamController<BackgroundServiceEvent> _eventController =
      StreamController<BackgroundServiceEvent>.broadcast();

  @override
  Stream<BackgroundServiceEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    // No-op
  }

  @override
  Future<void> startBackgroundOperation() async {
    _eventController.add(BackgroundServiceStarted());
  }

  @override
  Future<void> stopBackgroundOperation() async {
    _eventController.add(BackgroundServiceStopped());
  }

  @override
  Future<void> updateTimerState({
    required String title,
    required String content,
    required Duration remainingTime,
    required int currentRound,
    required bool isWorkPeriod,
  }) async {
    // No-op
  }

  @override
  Future<void> dispose() async {
    await _eventController.close();
  }
}

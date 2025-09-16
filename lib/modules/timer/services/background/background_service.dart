import 'dart:async';

/// Abstract interface for background timer services
abstract class BackgroundService {
  /// Stream of background service events
  Stream<BackgroundServiceEvent> get events;

  /// Initialize the background service
  Future<void> initialize();

  /// Start background operation
  Future<void> startBackgroundOperation();

  /// Stop background operation
  Future<void> stopBackgroundOperation();

  /// Update the background operation with current timer state
  Future<void> updateTimerState({
    required String title,
    required String content,
    required Duration remainingTime,
    required int currentRound,
    required bool isWorkPeriod,
  });

  /// Dispose resources
  Future<void> dispose();
}

/// Background service events
abstract class BackgroundServiceEvent {}

class BackgroundServiceStarted extends BackgroundServiceEvent {}

class BackgroundServiceStopped extends BackgroundServiceEvent {}

class BackgroundServiceError extends BackgroundServiceEvent {
  final String error;
  BackgroundServiceError(this.error);
}

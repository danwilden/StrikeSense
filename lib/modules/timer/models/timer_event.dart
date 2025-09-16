/// Base class for all timer events
abstract class TimerEvent {}

/// Timer started event
class TimerStarted extends TimerEvent {}

/// Timer paused event
class TimerPaused extends TimerEvent {}

/// Timer resumed event
class TimerResumed extends TimerEvent {}

/// Timer stopped event
class TimerStopped extends TimerEvent {}

/// Timer completed event
class TimerCompleted extends TimerEvent {}

/// Timer tick event with current time information
class TimerTick extends TimerEvent {
  final Duration remainingTime;
  final Duration elapsedTime;
  final int currentRound;
  final bool isWorkPeriod;
  final double progress;

  TimerTick({
    required this.remainingTime,
    required this.elapsedTime,
    required this.currentRound,
    required this.isWorkPeriod,
    required this.progress,
  });
}

/// Round started event
class RoundStarted extends TimerEvent {
  final int roundNumber;
  final bool isWorkPeriod;
  final Duration periodDuration;

  RoundStarted({
    required this.roundNumber,
    required this.isWorkPeriod,
    required this.periodDuration,
  });
}

/// Round ended event
class RoundEnded extends TimerEvent {
  final int roundNumber;
  final bool wasWorkPeriod;

  RoundEnded({required this.roundNumber, required this.wasWorkPeriod});
}

/// Warning reached event (when warning duration is reached)
class WarningReached extends TimerEvent {
  final Duration remainingTime;

  WarningReached({required this.remainingTime});
}

/// Countdown started event (final 3 seconds)
class CountdownStarted extends TimerEvent {
  final Duration remainingTime;

  CountdownStarted({required this.remainingTime});
}

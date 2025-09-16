import '../models/timer_config.dart';
import 'timer_engine.dart';

/// Factory for creating timer engine instances
class TimerEngineFactory {
  /// Create a new timer engine instance with the given configuration
  static TimerEngine createTimer(TimerConfig config) {
    return TimerEngine(config: config);
  }

  /// Create a round timer
  static TimerEngine createRoundTimer({
    int rounds = 5,
    Duration workDuration = const Duration(minutes: 3),
    Duration restDuration = const Duration(minutes: 1),
  }) {
    final config = TimerConfig.round(
      rounds: rounds,
      workDuration: workDuration,
      restDuration: restDuration,
    );
    return createTimer(config);
  }

  /// Create an interval timer
  static TimerEngine createIntervalTimer({
    int rounds = 8,
    Duration workDuration = const Duration(seconds: 30),
    Duration restDuration = const Duration(seconds: 15),
  }) {
    final config = TimerConfig.interval(
      rounds: rounds,
      workDuration: workDuration,
      restDuration: restDuration,
    );
    return createTimer(config);
  }

  /// Create a Tabata timer
  static TimerEngine createTabataTimer({int rounds = 8}) {
    final config = TimerConfig.tabata(rounds: rounds);
    return createTimer(config);
  }
}

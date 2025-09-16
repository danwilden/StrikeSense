import 'package:equatable/equatable.dart';
import 'timer_mode.dart';

/// Configuration for timer settings
class TimerConfig extends Equatable {
  final TimerMode mode;
  final int rounds;
  final Duration workDuration;
  final Duration restDuration;
  final Duration warningDuration;
  final bool enableSound;
  final bool enableHaptics;
  final double volume;

  const TimerConfig({
    required this.mode,
    required this.rounds,
    required this.workDuration,
    required this.restDuration,
    this.warningDuration = const Duration(seconds: 10),
    this.enableSound = true,
    this.enableHaptics = true,
    this.volume = 0.8,
  });

  /// Create a round timer configuration
  factory TimerConfig.round({
    int rounds = 5,
    Duration workDuration = const Duration(minutes: 3),
    Duration restDuration = const Duration(minutes: 1),
  }) {
    return TimerConfig(
      mode: TimerMode.round,
      rounds: rounds,
      workDuration: workDuration,
      restDuration: restDuration,
    );
  }

  /// Create an interval timer configuration
  factory TimerConfig.interval({
    int rounds = 8,
    Duration workDuration = const Duration(seconds: 30),
    Duration restDuration = const Duration(seconds: 15),
  }) {
    return TimerConfig(
      mode: TimerMode.interval,
      rounds: rounds,
      workDuration: workDuration,
      restDuration: restDuration,
    );
  }

  /// Create a Tabata timer configuration
  factory TimerConfig.tabata({int rounds = 8}) {
    return TimerConfig(
      mode: TimerMode.tabata,
      rounds: rounds,
      workDuration: const Duration(seconds: 20),
      restDuration: const Duration(seconds: 10),
    );
  }

  /// Calculate total duration for the entire timer session
  Duration get totalDuration {
    // Each round has work + rest, except the last round which only has work
    final totalRounds = rounds;
    final workTime = workDuration * totalRounds;
    final restTime = restDuration * (totalRounds - 1);
    return workTime + restTime;
  }

  @override
  List<Object?> get props => [
    mode,
    rounds,
    workDuration,
    restDuration,
    warningDuration,
    enableSound,
    enableHaptics,
    volume,
  ];
}

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

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'rounds': rounds,
      'workDuration': workDuration.inMilliseconds,
      'restDuration': restDuration.inMilliseconds,
      'warningDuration': warningDuration.inMilliseconds,
      'enableSound': enableSound,
      'enableHaptics': enableHaptics,
      'volume': volume,
    };
  }

  /// Create from JSON
  factory TimerConfig.fromJson(Map<String, dynamic> json) {
    return TimerConfig(
      mode: TimerMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => TimerMode.round,
      ),
      rounds: json['rounds'] as int,
      workDuration: Duration(milliseconds: json['workDuration'] as int),
      restDuration: Duration(milliseconds: json['restDuration'] as int),
      warningDuration: Duration(milliseconds: json['warningDuration'] as int),
      enableSound: json['enableSound'] as bool? ?? true,
      enableHaptics: json['enableHaptics'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
    );
  }

  /// Validate the timer configuration
  bool isValid() {
    try {
      // Check basic constraints
      if (rounds < 1 || rounds > 100) return false;
      if (workDuration.inSeconds < 1 || workDuration.inSeconds > 3600)
        return false;
      if (restDuration.inSeconds < 0 || restDuration.inSeconds > 3600)
        return false;
      if (warningDuration.inSeconds < 0 || warningDuration.inSeconds > 60)
        return false;
      if (volume < 0.0 || volume > 1.0) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get validation errors
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (rounds < 1) errors.add('Rounds must be at least 1');
    if (rounds > 100) errors.add('Rounds cannot exceed 100');
    if (workDuration.inSeconds < 1)
      errors.add('Work duration must be at least 1 second');
    if (workDuration.inSeconds > 3600)
      errors.add('Work duration cannot exceed 1 hour');
    if (restDuration.inSeconds < 0)
      errors.add('Rest duration cannot be negative');
    if (restDuration.inSeconds > 3600)
      errors.add('Rest duration cannot exceed 1 hour');
    if (warningDuration.inSeconds < 0)
      errors.add('Warning duration cannot be negative');
    if (warningDuration.inSeconds > 60)
      errors.add('Warning duration cannot exceed 60 seconds');
    if (volume < 0.0) errors.add('Volume cannot be negative');
    if (volume > 1.0) errors.add('Volume cannot exceed 1.0');

    return errors;
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

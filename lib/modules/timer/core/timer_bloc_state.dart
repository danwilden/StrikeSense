import 'package:equatable/equatable.dart';
import '../models/timer_config.dart';
import '../models/timer_state.dart';

/// State for the TimerBloc
class TimerBlocState extends Equatable {
  final TimerConfig? config;
  final TimerState state;
  final int currentRound;
  final bool isWorkPeriod;
  final Duration currentPeriodRemaining;
  final Duration elapsedTime;
  final Duration totalRemainingTime;
  final double progress;
  final String? error;

  const TimerBlocState({
    this.config,
    this.state = TimerState.stopped,
    this.currentRound = 1,
    this.isWorkPeriod = true,
    this.currentPeriodRemaining = Duration.zero,
    this.elapsedTime = Duration.zero,
    this.totalRemainingTime = Duration.zero,
    this.progress = 0.0,
    this.error,
  });

  /// Create a copy of this state with updated values
  TimerBlocState copyWith({
    TimerConfig? config,
    TimerState? state,
    int? currentRound,
    bool? isWorkPeriod,
    Duration? currentPeriodRemaining,
    Duration? elapsedTime,
    Duration? totalRemainingTime,
    double? progress,
    String? error,
    bool clearError = false,
  }) {
    return TimerBlocState(
      config: config ?? this.config,
      state: state ?? this.state,
      currentRound: currentRound ?? this.currentRound,
      isWorkPeriod: isWorkPeriod ?? this.isWorkPeriod,
      currentPeriodRemaining:
          currentPeriodRemaining ?? this.currentPeriodRemaining,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      totalRemainingTime: totalRemainingTime ?? this.totalRemainingTime,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    config,
    state,
    currentRound,
    isWorkPeriod,
    currentPeriodRemaining,
    elapsedTime,
    totalRemainingTime,
    progress,
    error,
  ];
}

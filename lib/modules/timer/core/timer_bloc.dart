import 'dart:async';

import 'package:bloc/bloc.dart';

import '../models/timer_config.dart';
import '../models/timer_event.dart';
import '../models/timer_state.dart';
import '../services/event_bus.dart';
import 'timer_bloc_state.dart';
import 'timer_engine.dart';
import 'timer_engine_factory.dart';

/// Events for the TimerBloc
abstract class TimerBlocEvent {}

class InitializeTimer extends TimerBlocEvent {
  final TimerConfig config;
  InitializeTimer(this.config);
}

class StartTimer extends TimerBlocEvent {}

class PauseTimer extends TimerBlocEvent {}

class StopTimer extends TimerBlocEvent {}

class ResetTimer extends TimerBlocEvent {}

class SkipTimer extends TimerBlocEvent {}

/// BLoC for managing timer state
class TimerBloc extends Bloc<TimerBlocEvent, TimerBlocState> {
  TimerEngine? _timerEngine;
  final EventBus _eventBus = EventBus();

  TimerBloc() : super(const TimerBlocState()) {
    on<InitializeTimer>(_onInitializeTimer);
    on<StartTimer>(_onStartTimer);
    on<PauseTimer>(_onPauseTimer);
    on<StopTimer>(_onStopTimer);
    on<ResetTimer>(_onResetTimer);
    on<SkipTimer>(_onSkipTimer);

    // Internal event handlers
    on<_TimerStartedEvent>(_onTimerStarted);
    on<_TimerPausedEvent>(_onTimerPaused);
    on<_TimerResumedEvent>(_onTimerResumed);
    on<_TimerStoppedEvent>(_onTimerStopped);
    on<_TimerCompletedEvent>(_onTimerCompleted);
    on<_TimerTickEvent>(_onTimerTick);
    on<_RoundStartedEvent>(_onRoundStarted);
    on<_RoundEndedEvent>(_onRoundEnded);

    // Subscribe to timer events
    _eventBus.subscribe(_onTimerEvent);
  }

  @override
  Future<void> close() {
    _timerEngine?.dispose();
    _eventBus.unsubscribe(_onTimerEvent);
    return super.close();
  }

  /// Initialize timer with new configuration
  void _onInitializeTimer(InitializeTimer event, Emitter<TimerBlocState> emit) {
    try {
      // Dispose existing timer engine
      _timerEngine?.dispose();

      // Create new timer engine
      _timerEngine = TimerEngineFactory.createTimer(event.config);

      // Subscribe to timer events
      _timerEngine!.addEventListener(_eventBus.emit);

      // Emit initial state
      emit(
        state.copyWith(
          config: event.config,
          state: TimerState.stopped,
          currentRound: 1,
          isWorkPeriod: true,
          currentPeriodRemaining: event.config.workDuration,
          elapsedTime: Duration.zero,
          totalRemainingTime: event.config.totalDuration,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to initialize timer: $e'));
    }
  }

  /// Start the timer
  void _onStartTimer(StartTimer event, Emitter<TimerBlocState> emit) {
    if (_timerEngine == null) {
      emit(state.copyWith(error: 'Timer not initialized'));
      return;
    }

    try {
      _timerEngine!.start();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to start timer: $e'));
    }
  }

  /// Pause the timer
  void _onPauseTimer(PauseTimer event, Emitter<TimerBlocState> emit) {
    if (_timerEngine == null) return;

    try {
      _timerEngine!.pause();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pause timer: $e'));
    }
  }

  /// Stop the timer
  void _onStopTimer(StopTimer event, Emitter<TimerBlocState> emit) {
    if (_timerEngine == null) return;

    try {
      _timerEngine!.stop();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to stop timer: $e'));
    }
  }

  /// Reset the timer
  void _onResetTimer(ResetTimer event, Emitter<TimerBlocState> emit) {
    if (_timerEngine == null) return;

    try {
      _timerEngine!.reset();
      // Emit reset state immediately
      emit(
        state.copyWith(
          state: TimerState.stopped,
          currentRound: 1,
          isWorkPeriod: true,
          currentPeriodRemaining: state.config?.workDuration ?? Duration.zero,
          elapsedTime: Duration.zero,
          totalRemainingTime: state.config?.totalDuration ?? Duration.zero,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to reset timer: $e'));
    }
  }

  /// Skip to next period/round
  void _onSkipTimer(SkipTimer event, Emitter<TimerBlocState> emit) {
    if (_timerEngine == null) return;

    try {
      _timerEngine!.skip();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to skip timer: $e'));
    }
  }

  /// Handle timer events from the engine
  void _onTimerEvent(TimerEvent event) {
    if (_timerEngine == null) return;

    switch (event.runtimeType) {
      case TimerStarted:
        add(_TimerStartedEvent());
        break;
      case TimerPaused:
        add(_TimerPausedEvent());
        break;
      case TimerResumed:
        add(_TimerResumedEvent());
        break;
      case TimerStopped:
        add(_TimerStoppedEvent());
        break;
      case TimerCompleted:
        add(_TimerCompletedEvent());
        break;
      case TimerTick:
        add(_TimerTickEvent(event as TimerTick));
        break;
      case RoundStarted:
        add(_RoundStartedEvent(event as RoundStarted));
        break;
      case RoundEnded:
        add(_RoundEndedEvent(event as RoundEnded));
        break;
    }
  }

  /// Handle timer started event
  void _onTimerStarted(_TimerStartedEvent event, Emitter<TimerBlocState> emit) {
    emit(state.copyWith(state: TimerState.running));
  }

  /// Handle timer paused event
  void _onTimerPaused(_TimerPausedEvent event, Emitter<TimerBlocState> emit) {
    emit(state.copyWith(state: TimerState.paused));
  }

  /// Handle timer resumed event
  void _onTimerResumed(_TimerResumedEvent event, Emitter<TimerBlocState> emit) {
    emit(state.copyWith(state: TimerState.running));
  }

  /// Handle timer stopped event
  void _onTimerStopped(_TimerStoppedEvent event, Emitter<TimerBlocState> emit) {
    emit(state.copyWith(state: TimerState.stopped));
  }

  /// Handle timer completed event
  void _onTimerCompleted(
    _TimerCompletedEvent event,
    Emitter<TimerBlocState> emit,
  ) {
    emit(state.copyWith(state: TimerState.completed));
  }

  /// Handle timer tick event
  void _onTimerTick(_TimerTickEvent event, Emitter<TimerBlocState> emit) {
    emit(
      state.copyWith(
        currentRound: event.tickEvent.currentRound,
        isWorkPeriod: event.tickEvent.isWorkPeriod,
        currentPeriodRemaining: event.tickEvent.remainingTime,
        elapsedTime: event.tickEvent.elapsedTime,
        totalRemainingTime: _timerEngine!.totalRemainingTime,
        progress: event.tickEvent.progress,
      ),
    );
  }

  /// Handle round started event
  void _onRoundStarted(_RoundStartedEvent event, Emitter<TimerBlocState> emit) {
    emit(
      state.copyWith(
        currentRound: event.roundEvent.roundNumber,
        isWorkPeriod: event.roundEvent.isWorkPeriod,
        currentPeriodRemaining: event.roundEvent.periodDuration,
      ),
    );
  }

  /// Handle round ended event
  void _onRoundEnded(_RoundEndedEvent event, Emitter<TimerBlocState> emit) {
    // Round ended events are handled by the next round started event
    // This is just for logging or additional processing if needed
  }
}

// Internal events for handling timer engine events
class _TimerStartedEvent extends TimerBlocEvent {}

class _TimerPausedEvent extends TimerBlocEvent {}

class _TimerResumedEvent extends TimerBlocEvent {}

class _TimerStoppedEvent extends TimerBlocEvent {}

class _TimerCompletedEvent extends TimerBlocEvent {}

class _TimerTickEvent extends TimerBlocEvent {
  final TimerTick tickEvent;
  _TimerTickEvent(this.tickEvent);
}

class _RoundStartedEvent extends TimerBlocEvent {
  final RoundStarted roundEvent;
  _RoundStartedEvent(this.roundEvent);
}

class _RoundEndedEvent extends TimerBlocEvent {
  final RoundEnded roundEvent;
  _RoundEndedEvent(this.roundEvent);
}

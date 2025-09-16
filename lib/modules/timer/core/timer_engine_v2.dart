import 'dart:async';
import 'dart:math' as math;

import '../models/timer_config.dart';
import '../models/timer_event.dart';
import '../models/timer_state.dart';

/// Core timer engine that handles all timer logic
class TimerEngine {
  // Configuration
  final TimerConfig config;

  // State
  TimerState _state = TimerState.stopped;
  int _currentRound = 1;
  bool _isWorkPeriod = true;
  Duration _currentPeriodRemaining = Duration.zero;
  Duration _elapsedTime = Duration.zero;

  // Timers
  Timer? _mainTimer;

  // Timing
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;

  // Event callbacks
  final List<void Function(TimerEvent)> _eventListeners = [];

  TimerEngine({required this.config}) {
    _initializeState();
  }

  /// Current timer state
  TimerState get state => _state;

  /// Current round number
  int get currentRound => _currentRound;

  /// Whether currently in work period
  bool get isWorkPeriod => _isWorkPeriod;

  /// Remaining time in current period
  Duration get currentPeriodRemaining => _currentPeriodRemaining;

  /// Total elapsed time
  Duration get elapsedTime => _elapsedTime;

  /// Total remaining time for entire session
  Duration get totalRemainingTime {
    final totalDuration = config.totalDuration;
    return Duration(
      milliseconds: math.max(
        0,
        totalDuration.inMilliseconds - _elapsedTime.inMilliseconds,
      ),
    );
  }

  /// Progress as a percentage (0.0 to 1.0)
  double get progress {
    final totalDuration = config.totalDuration;
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return math.max(
      0.0,
      math.min(1.0, _elapsedTime.inMilliseconds / totalDuration.inMilliseconds),
    );
  }

  /// Add event listener
  void addEventListener(void Function(TimerEvent) listener) {
    _eventListeners.add(listener);
  }

  /// Remove event listener
  void removeEventListener(void Function(TimerEvent) listener) {
    _eventListeners.remove(listener);
  }

  /// Start the timer
  void start() {
    if (_state == TimerState.running) return;

    _state = TimerState.running;
    _startTime = DateTime.now();
    _pauseTime = null;

    _emitEvent(TimerStarted());
    _startMainTimer();
  }

  /// Pause the timer
  void pause() {
    if (_state != TimerState.running) return;

    _state = TimerState.paused;
    _pauseTime = DateTime.now();

    _mainTimer?.cancel();

    _emitEvent(TimerPaused());
  }

  /// Resume the timer
  void resume() {
    if (_state != TimerState.paused) return;

    _state = TimerState.running;

    // Add paused duration to total paused time
    if (_pauseTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseTime!);
      _pauseTime = null;
    }

    _emitEvent(TimerResumed());
    _startMainTimer();
  }

  /// Stop the timer
  void stop() {
    if (_state == TimerState.stopped) return;

    _state = TimerState.stopped;
    _mainTimer?.cancel();

    _emitEvent(TimerStopped());
  }

  /// Reset the timer to initial state
  void reset() {
    stop();
    _initializeState();
  }

  /// Skip to the next period or round
  void skip() {
    if (_state == TimerState.stopped) return;

    // Complete the current period immediately
    _completeCurrentPeriod();
  }

  /// Dispose of resources
  void dispose() {
    _mainTimer?.cancel();
    _eventListeners.clear();
  }

  /// Initialize timer state
  void _initializeState() {
    _currentRound = 1;
    _isWorkPeriod = true;
    _currentPeriodRemaining = config.workDuration;
    _elapsedTime = Duration.zero;
    _pausedDuration = Duration.zero;
    _startTime = null;
    _pauseTime = null;
  }

  /// Start the main timer
  void _startMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateTimer();
    });
  }

  /// Update timer state
  void _updateTimer() {
    if (_state != TimerState.running) return;

    final now = DateTime.now();
    if (_startTime == null) return;

    // Calculate elapsed time (excluding paused time)
    final rawElapsed = now.difference(_startTime!);
    _elapsedTime = rawElapsed - _pausedDuration;

    // Update current period remaining time
    _updateCurrentPeriodRemaining();

    // Emit tick event
    _emitEvent(
      TimerTick(
        remainingTime: _currentPeriodRemaining,
        elapsedTime: _elapsedTime,
        currentRound: _currentRound,
        isWorkPeriod: _isWorkPeriod,
        progress: progress,
      ),
    );

    // Check for period completion
    if (_currentPeriodRemaining <= Duration.zero) {
      _completeCurrentPeriod();
    }

    // Check for warning
    if (_shouldEmitWarning()) {
      _emitEvent(WarningReached(remainingTime: _currentPeriodRemaining));
    }

    // Check for countdown
    if (_shouldEmitCountdown()) {
      _emitEvent(CountdownStarted(remainingTime: _currentPeriodRemaining));
    }

    // Check for session completion
    if (totalRemainingTime <= Duration.zero) {
      _completeSession();
    }
  }

  /// Update current period remaining time
  void _updateCurrentPeriodRemaining() {
    final periodDuration = _isWorkPeriod
        ? config.workDuration
        : config.restDuration;
    final periodElapsed = _calculatePeriodElapsed();
    _currentPeriodRemaining = Duration(
      milliseconds: math.max(
        0,
        periodDuration.inMilliseconds - periodElapsed.inMilliseconds,
      ),
    );
  }

  /// Calculate elapsed time in current period
  Duration _calculatePeriodElapsed() {
    final totalElapsed = _elapsedTime.inMilliseconds;
    final workDuration = config.workDuration.inMilliseconds;
    final restDuration = config.restDuration.inMilliseconds;

    // Calculate total time for completed rounds
    final completedRounds = _currentRound - 1;
    final completedWorkTime = completedRounds * workDuration;
    final completedRestTime = completedRounds * restDuration;
    final completedTime = completedWorkTime + completedRestTime;

    // Calculate time in current round
    final timeInCurrentRound = totalElapsed - completedTime;

    if (_isWorkPeriod) {
      // We're in work period of current round
      return Duration(milliseconds: timeInCurrentRound);
    } else {
      // We're in rest period of current round
      return Duration(milliseconds: timeInCurrentRound - workDuration);
    }
  }

  /// Complete the current period
  void _completeCurrentPeriod() {
    // Emit round ended event
    _emitEvent(
      RoundEnded(roundNumber: _currentRound, wasWorkPeriod: _isWorkPeriod),
    );

    // Move to next period or round
    if (_isWorkPeriod) {
      // Work period completed, move to rest (if not last round)
      if (_currentRound < config.rounds) {
        _isWorkPeriod = false;
        _currentPeriodRemaining = config.restDuration;
        _emitEvent(
          RoundStarted(
            roundNumber: _currentRound,
            isWorkPeriod: false,
            periodDuration: config.restDuration,
          ),
        );
      } else {
        // Last round completed
        _completeSession();
      }
    } else {
      // Rest period completed, move to next work period
      _currentRound++;
      _isWorkPeriod = true;
      _currentPeriodRemaining = config.workDuration;
      _emitEvent(
        RoundStarted(
          roundNumber: _currentRound,
          isWorkPeriod: true,
          periodDuration: config.workDuration,
        ),
      );
    }
  }

  /// Complete the entire session
  void _completeSession() {
    _state = TimerState.completed;
    _mainTimer?.cancel();
    _currentPeriodRemaining = Duration.zero;

    _emitEvent(TimerCompleted());
  }

  /// Check if warning should be emitted
  bool _shouldEmitWarning() {
    return _currentPeriodRemaining <= config.warningDuration &&
        _currentPeriodRemaining > const Duration(seconds: 9);
  }

  /// Check if countdown should be emitted
  bool _shouldEmitCountdown() {
    return _currentPeriodRemaining <= const Duration(seconds: 3) &&
        _currentPeriodRemaining > const Duration(seconds: 2);
  }

  /// Emit an event to all listeners
  void _emitEvent(TimerEvent event) {
    for (final listener in _eventListeners) {
      try {
        listener(event);
      } catch (e) {
        // Log error but don't crash
        print('Error in timer event listener: $e');
      }
    }
  }
}

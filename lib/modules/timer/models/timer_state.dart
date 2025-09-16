/// States that the timer can be in
enum TimerState {
  stopped,
  running,
  paused,
  completed;

  bool get isActive => this == TimerState.running;
  bool get isPaused => this == TimerState.paused;
  bool get isStopped => this == TimerState.stopped;
  bool get isCompleted => this == TimerState.completed;
}

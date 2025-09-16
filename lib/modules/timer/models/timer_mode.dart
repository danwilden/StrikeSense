/// Timer modes supported by the application
enum TimerMode {
  round,
  interval,
  tabata;

  String get displayName {
    switch (this) {
      case TimerMode.round:
        return 'Round Timer';
      case TimerMode.interval:
        return 'Interval Timer';
      case TimerMode.tabata:
        return 'Tabata Timer';
    }
  }

  String get description {
    switch (this) {
      case TimerMode.round:
        return 'Traditional round-based timer with work and rest periods';
      case TimerMode.interval:
        return 'HIIT-style interval timer with variable periods';
      case TimerMode.tabata:
        return 'High-intensity Tabata protocol (20s work, 10s rest)';
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:strikesense/modules/timer/timer_module.dart';

void main() {
  group('TimerEngine', () {
    late TimerEngine timerEngine;

    setUp(() {
      timerEngine = TimerEngine();
    });

    tearDown(() {
      timerEngine.dispose();
    });

    test('should initialize with round timer config', () {
      final config = TimerConfig.round(
        rounds: 3,
        workDuration: const Duration(seconds: 30),
        restDuration: const Duration(seconds: 10),
      );

      timerEngine.initialize(config);

      expect(timerEngine.config, equals(config));
      expect(timerEngine.state, equals(TimerState.stopped));
      expect(timerEngine.currentRound, equals(1));
      expect(timerEngine.isWorkPeriod, isTrue);
    });

    test('should initialize with interval timer config', () {
      final config = TimerConfig.interval(
        rounds: 5,
        workDuration: const Duration(seconds: 20),
        restDuration: const Duration(seconds: 5),
      );

      timerEngine.initialize(config);

      expect(timerEngine.config, equals(config));
      expect(timerEngine.mode, equals(TimerMode.interval));
    });

    test('should initialize with tabata timer config', () {
      final config = TimerConfig.tabata(
        rounds: 8,
        workDuration: const Duration(seconds: 20),
        restDuration: const Duration(seconds: 10),
      );

      timerEngine.initialize(config);

      expect(timerEngine.config, equals(config));
      expect(timerEngine.mode, equals(TimerMode.tabata));
    });

    test('should throw error when starting without initialization', () {
      expect(() => timerEngine.start(), throwsStateError);
    });

    test('should start timer and emit events', () async {
      final config = TimerConfig.round(
        rounds: 1,
        workDuration: const Duration(milliseconds: 100),
        restDuration: const Duration(milliseconds: 50),
      );

      timerEngine.initialize(config);

      final events = <TimerEvent>[];
      timerEngine.events.listen(events.add);

      timerEngine.start();

      // Wait for timer to start
      await Future.delayed(const Duration(milliseconds: 50));

      expect(timerEngine.state, equals(TimerState.running));
      expect(events.any((e) => e is TimerStarted), isTrue);
      expect(events.any((e) => e is RoundStarted), isTrue);
    });

    test('should pause and resume timer', () async {
      final config = TimerConfig.round(
        rounds: 1,
        workDuration: const Duration(seconds: 1),
        restDuration: const Duration(seconds: 1),
      );

      timerEngine.initialize(config);
      timerEngine.start();

      await Future.delayed(const Duration(milliseconds: 100));

      timerEngine.pause();
      expect(timerEngine.state, equals(TimerState.paused));

      timerEngine.start(); // Resume
      expect(timerEngine.state, equals(TimerState.running));
    });

    test('should stop timer and reset state', () {
      final config = TimerConfig.round(
        rounds: 3,
        workDuration: const Duration(seconds: 30),
        restDuration: const Duration(seconds: 10),
      );

      timerEngine.initialize(config);
      timerEngine.start();

      timerEngine.stop();

      expect(timerEngine.state, equals(TimerState.stopped));
      expect(timerEngine.currentRound, equals(1));
      expect(timerEngine.isWorkPeriod, isTrue);
      expect(timerEngine.elapsedTime, equals(Duration.zero));
    });

    test('should calculate progress correctly', () {
      final config = TimerConfig.round(
        rounds: 2,
        workDuration: const Duration(seconds: 10),
        restDuration: const Duration(seconds: 5),
      );

      timerEngine.initialize(config);
      expect(timerEngine.getProgress(), equals(0.0));

      // Total duration should be 30 seconds (2 rounds * (10s work + 5s rest))
      expect(config.totalDuration, equals(const Duration(seconds: 30)));
    });

    test('should handle skip to next period', () async {
      final config = TimerConfig.round(
        rounds: 2,
        workDuration: const Duration(seconds: 1),
        restDuration: const Duration(seconds: 1),
      );

      timerEngine.initialize(config);
      timerEngine.start();

      await Future.delayed(const Duration(milliseconds: 100));

      timerEngine.skipToNext();

      // Should move to rest period of current round
      expect(timerEngine.isWorkPeriod, isFalse);
    });
  });
}

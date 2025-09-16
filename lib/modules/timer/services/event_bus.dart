import '../models/timer_event.dart';

/// Simple event bus for loose coupling between components
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final List<void Function(TimerEvent)> _listeners = [];

  /// Subscribe to timer events
  void subscribe(void Function(TimerEvent) listener) {
    _listeners.add(listener);
  }

  /// Unsubscribe from timer events
  void unsubscribe(void Function(TimerEvent) listener) {
    _listeners.remove(listener);
  }

  /// Emit an event to all subscribers
  void emit(TimerEvent event) {
    for (final listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        print('Error in event bus listener: $e');
      }
    }
  }

  /// Clear all listeners
  void clear() {
    _listeners.clear();
  }
}

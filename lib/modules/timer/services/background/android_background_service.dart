import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'background_service.dart';

/// Android-specific background service using Foreground Service
class AndroidBackgroundService implements BackgroundService {
  static const String _notificationChannelId = 'timer_foreground_service';
  static const String _notificationChannelName = 'Timer Service';
  static const String _notificationChannelDescription =
      'Keeps timer running in background';
  static const int _notificationId = 1001;
  static const String _workManagerTaskName = 'timer_background_task';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<BackgroundServiceEvent> _eventController =
      StreamController<BackgroundServiceEvent>.broadcast();

  bool _isInitialized = false;
  bool _isRunning = false;
  Timer? _updateTimer;

  @override
  Stream<BackgroundServiceEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notifications
    await _initializeNotifications();

    // Initialize WorkManager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    _isInitialized = true;
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        _notificationChannelId,
        _notificationChannelName,
        description: _notificationChannelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  @override
  Future<void> startBackgroundOperation() async {
    if (!_isInitialized) {
      throw StateError('Background service not initialized');
    }

    if (_isRunning) return;

    // Start foreground service with notification
    await _startForegroundService();

    // Register periodic task with WorkManager
    await Workmanager().registerPeriodicTask(
      _workManagerTaskName,
      _workManagerTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    _isRunning = true;
    _eventController.add(BackgroundServiceStarted());
  }

  Future<void> _startForegroundService() async {
    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      category: AndroidNotificationCategory.service,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      'StrikeSense Timer',
      'Timer is running in background',
      notificationDetails,
    );
  }

  @override
  Future<void> stopBackgroundOperation() async {
    if (!_isRunning) return;

    // Cancel WorkManager task
    await Workmanager().cancelByUniqueName(_workManagerTaskName);

    // Cancel foreground notification
    await _notificationsPlugin.cancel(_notificationId);

    // Stop update timer
    _updateTimer?.cancel();
    _updateTimer = null;

    _isRunning = false;
    _eventController.add(BackgroundServiceStopped());
  }

  @override
  Future<void> updateTimerState({
    required String title,
    required String content,
    required Duration remainingTime,
    required int currentRound,
    required bool isWorkPeriod,
  }) async {
    if (!_isRunning) return;

    final timeString = _formatDuration(remainingTime);
    final periodText = isWorkPeriod ? 'WORK' : 'REST';
    final notificationTitle = '$title - Round $currentRound';
    final notificationContent = '$periodText - $timeString remaining';

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      category: AndroidNotificationCategory.service,
      actions: [
        AndroidNotificationAction(
          'pause_action',
          'Pause',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_pause'),
        ),
        AndroidNotificationAction(
          'stop_action',
          'Stop',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_stop'),
        ),
      ],
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      notificationTitle,
      notificationContent,
      notificationDetails,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Future<void> dispose() async {
    await stopBackgroundOperation();
    await _eventController.close();
  }
}

/// WorkManager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs in a separate isolate
    // We can't directly update the UI here, but we can:
    // 1. Update local storage with timer state
    // 2. Send local notifications
    // 3. Perform other background tasks

    try {
      // For now, just return success
      // In a full implementation, we would:
      // - Read timer state from shared preferences
      // - Update the timer state
      // - Send notifications if needed

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'background_service.dart';

/// iOS-specific background service using AVAudioSession
class IOSBackgroundService implements BackgroundService {
  static const int _notificationId = 1001;

  static const MethodChannel _audioChannel = MethodChannel('strikesense/audio');
  static const MethodChannel _backgroundChannel = MethodChannel(
    'strikesense/background',
  );

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

    // Initialize native audio session
    await _initializeAudioSession();

    // Set up method channel handlers
    _setupMethodChannelHandlers();

    _isInitialized = true;
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Request notification permissions on iOS
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _initializeAudioSession() async {
    try {
      await _audioChannel.invokeMethod('configureAudioSession');
    } on PlatformException catch (e) {
      _eventController.add(
        BackgroundServiceError(
          'Failed to configure audio session: ${e.message}',
        ),
      );
    }
  }

  void _setupMethodChannelHandlers() {
    _backgroundChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onBackgroundTaskExpired':
          _eventController.add(
            BackgroundServiceError('Background task expired'),
          );
          break;
        case 'onAudioSessionInterrupted':
          _eventController.add(
            BackgroundServiceError('Audio session interrupted'),
          );
          break;
        default:
          break;
      }
    });
  }

  @override
  Future<void> startBackgroundOperation() async {
    if (!_isInitialized) {
      throw StateError('Background service not initialized');
    }

    if (_isRunning) return;

    try {
      // Start background task
      await _backgroundChannel.invokeMethod('startBackgroundTask');

      // Configure audio session for background playback
      await _audioChannel.invokeMethod('startBackgroundAudio');

      // Start background app refresh task
      await _startBackgroundAppRefresh();

      _isRunning = true;
      _eventController.add(BackgroundServiceStarted());
    } on PlatformException catch (e) {
      _eventController.add(
        BackgroundServiceError(
          'Failed to start background operation: ${e.message}',
        ),
      );
    }
  }

  Future<void> _startBackgroundAppRefresh() async {
    try {
      await _backgroundChannel.invokeMethod('startBackgroundAppRefresh');
    } on PlatformException {
      // Background app refresh might not be available or enabled
      // This is not critical for timer functionality
    }
  }

  @override
  Future<void> stopBackgroundOperation() async {
    if (!_isRunning) return;

    try {
      // Stop background task
      await _backgroundChannel.invokeMethod('stopBackgroundTask');

      // Stop background audio
      await _audioChannel.invokeMethod('stopBackgroundAudio');

      // Cancel any pending notifications
      await _notificationsPlugin.cancel(_notificationId);

      // Stop update timer
      _updateTimer?.cancel();
      _updateTimer = null;

      _isRunning = false;
      _eventController.add(BackgroundServiceStopped());
    } on PlatformException catch (e) {
      _eventController.add(
        BackgroundServiceError(
          'Failed to stop background operation: ${e.message}',
        ),
      );
    }
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

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      badgeNumber: currentRound,
      categoryIdentifier: 'timer_category',
    );

    final notificationDetails = NotificationDetails(iOS: iosDetails);

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

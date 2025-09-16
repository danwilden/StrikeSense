import Flutter
import UIKit
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundService: BackgroundService?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Initialize background service
    backgroundService = BackgroundService()
    
    // Set up method channels
    setupMethodChannels()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    // Audio channel
    let audioChannel = FlutterMethodChannel(
      name: "strikesense/audio",
      binaryMessenger: controller.binaryMessenger
    )
    
    audioChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleAudioMethodCall(call: call, result: result)
    }
    
    // Background channel
    let backgroundChannel = FlutterMethodChannel(
      name: "strikesense/background",
      binaryMessenger: controller.binaryMessenger
    )
    
    backgroundChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleBackgroundMethodCall(call: call, result: result)
    }
  }
  
  private func handleAudioMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let backgroundService = backgroundService else {
      result(FlutterError(code: "NO_SERVICE", message: "Background service not initialized", details: nil))
      return
    }
    
    switch call.method {
    case "configureAudioSession":
      let success = backgroundService.configureAudioSession()
      result(success)
    case "startBackgroundAudio":
      let success = backgroundService.startBackgroundAudio()
      result(success)
    case "stopBackgroundAudio":
      let success = backgroundService.stopBackgroundAudio()
      result(success)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleBackgroundMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let backgroundService = backgroundService else {
      result(FlutterError(code: "NO_SERVICE", message: "Background service not initialized", details: nil))
      return
    }
    
    switch call.method {
    case "startBackgroundTask":
      let success = backgroundService.startBackgroundTask()
      result(success)
    case "stopBackgroundTask":
      backgroundService.stopBackgroundTask()
      result(true)
    case "startBackgroundAppRefresh":
      let success = backgroundService.startBackgroundAppRefresh()
      result(success)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

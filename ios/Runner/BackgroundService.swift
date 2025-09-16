import Foundation
import AVFoundation
import UIKit
import BackgroundTasks

@objc class BackgroundService: NSObject {
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var audioSession: AVAudioSession?
    private var backgroundTaskTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    @objc func configureAudioSession() -> Bool {
        do {
            try audioSession?.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession?.setActive(true)
            return true
        } catch {
            print("Failed to configure audio session: \(error)")
            return false
        }
    }
    
    @objc func startBackgroundTask() -> Bool {
        guard backgroundTaskId == .invalid else { return true }
        
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "TimerBackgroundTask") { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Start a timer to keep the background task alive
        backgroundTaskTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            // Keep the background task alive by doing minimal work
            print("Background task is running")
        }
        
        return backgroundTaskId != .invalid
    }
    
    @objc func stopBackgroundTask() {
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
        
        backgroundTaskTimer?.invalidate()
        backgroundTaskTimer = nil
    }
    
    @objc func startBackgroundAudio() -> Bool {
        do {
            try audioSession?.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession?.setActive(true)
            return true
        } catch {
            print("Failed to start background audio: \(error)")
            return false
        }
    }
    
    @objc func stopBackgroundAudio() -> Bool {
        do {
            try audioSession?.setActive(false)
            return true
        } catch {
            print("Failed to stop background audio: \(error)")
            return false
        }
    }
    
    @objc func startBackgroundAppRefresh() -> Bool {
        // Register background app refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.strikesense.timer.refresh", using: nil) { task in
            self.handleBackgroundAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Schedule background app refresh
        let request = BGAppRefreshTaskRequest(identifier: "com.strikesense.timer.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            return true
        } catch {
            print("Failed to schedule background app refresh: \(error)")
            return false
        }
    }
    
    private func handleBackgroundAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next background app refresh
        scheduleBackgroundAppRefresh()
        
        // Perform background work here
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Complete the task
        task.setTaskCompleted(success: true)
    }
    
    private func scheduleBackgroundAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.strikesense.timer.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background app refresh: \(error)")
        }
    }
}

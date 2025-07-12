//
//  SessionModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

class SessionViewModel: ObservableObject {
    static let shared = SessionViewModel()
    private let dataManager = DataManager.shared
    private var timer: Timer?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentSession: Session?
    
    init() {
    }
    
    func startSession(name: String, taskDescription: String, themeColor: String = "#00CE4A") {
        // 结束当前会话（如果有）
        endCurrentSession()

        let activityId: UUID
        if !let activity = dataManager.getActivity(by: name) {
            return
        }
        activityId = activity.id
        let newSession = Session(
            activityId: activityId,
            startTime: Date(),
            taskDescription: taskDescription
        )
        
        dataManager.addSessionToToday(newSession)
        currentSession = newSession
        elapsedTime = 0
        startTimer()
    }
    
    func endCurrentSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        dataManager.updateSession(session: session)
        
        currentSession = nil
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopTimer()
    }
}

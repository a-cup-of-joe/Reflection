//
//  SessionModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

struct FocusSession: Identifiable, Codable, Equatable {
    let id = UUID()
    var projectName: String
    var taskDescription: String
    var startTime: Date
    var endTime: Date?
    var themeColor: String = "#00CE4A" // 默认主题色
    
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var themeColorSwiftUI: Color {
        Color(hex: themeColor)
    }
}

class SessionViewModel: ObservableObject {
    @Published var currentSession: FocusSession?
    @Published var sessions: [FocusSession] = []
    @Published var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private let dataManager = DataManager.shared
    
    init() {
        loadSessions()
    }
    
    func startSession(project: String, task: String, themeColor: String = "#00CE4A") {
        // 结束当前会话（如果有）
        endCurrentSession()
        
        let newSession = FocusSession(
            projectName: project,
            taskDescription: task,
            startTime: Date(),
            themeColor: themeColor
        )
        
        currentSession = newSession
        elapsedTime = 0
        startTimer()
    }
    
    func endCurrentSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        sessions.append(session)
        
        // 更新对应计划的实际时间
        let dataManager = DataManager.shared
        var plans = dataManager.loadPlans()
        
        if let planIndex = plans.firstIndex(where: { $0.project == session.projectName }) {
            plans[planIndex].actualTime += session.duration
            dataManager.savePlans(plans)
        }
        
        currentSession = nil
        stopTimer()
        saveSessions()
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
    
    private func loadSessions() {
        sessions = dataManager.loadSessions()
    }
    
    private func saveSessions() {
        dataManager.saveSessions(sessions)
    }
    
    deinit {
        stopTimer()
    }
}

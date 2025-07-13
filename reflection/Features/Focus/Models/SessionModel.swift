//
//  SessionModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

// MARK: - FocusSession Model
struct FocusSession: Identifiable, Codable, Equatable {
    let id: UUID
    var projectName: String
    var taskDescription: String
    var startTime: Date
    var endTime: Date?
    var themeColor: String
    
    init(projectName: String, taskDescription: String, startTime: Date = Date(), themeColor: String = "#00CE4A") {
        self.id = UUID()
        self.projectName = projectName
        self.taskDescription = taskDescription
        self.startTime = startTime
        self.themeColor = themeColor
    }
}

// MARK: - FocusSession Extensions
extension FocusSession {
    /// 会话持续时间
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 是否为活跃会话
    var isActive: Bool {
        endTime == nil
    }
    
    /// SwiftUI 颜色对象
    var themeColorSwiftUI: Color {
        Color(hex: themeColor)
    }
}

// MARK: - SessionViewModel
final class SessionViewModel: ObservableObject {
    @Published var currentSession: FocusSession?
    @Published var sessions: [FocusSession] = []
    @Published var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private let dataManager = DataManager.shared
    
    init() {
        loadSessions()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    func startSession(project: String, task: String, themeColor: String = "#00CE4A") {
        let trimmedProject = project.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedProject.isEmpty else { return }
        
        endCurrentSession()
        
        let newSession = FocusSession(
            projectName: trimmedProject,
            taskDescription: trimmedTask,
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
        
        updatePlanActualTime(for: session)
        
        currentSession = nil
        stopTimer()
        saveSessions()
    }
    
    // MARK: - Private Helper Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePlanActualTime(for session: FocusSession) {
        var plans = dataManager.loadPlans()
        
        if let planIndex = plans.firstIndex(where: { $0.project == session.projectName }) {
            plans[planIndex].actualTime += session.duration
            dataManager.savePlans(plans)
        }
    }
    
    private func loadSessions() {
        sessions = dataManager.loadSessions()
    }
    
    private func saveSessions() {
        dataManager.saveSessions(sessions)
    }
}

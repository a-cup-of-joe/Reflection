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
    
    // 新增字段：保存 TaskSelectionView 中的额外信息
    var goals: [String]
    var expectedTime: TimeInterval
    
    // 新增字段：结束时的反馈信息
    var actualCompletion: String
    var reflection: String
    var followUp: String
    
    init(projectName: String, taskDescription: String, startTime: Date = Date(), themeColor: String = "#00CE4A", goals: [String] = [], expectedTime: TimeInterval = 1800, actualCompletion: String = "", reflection: String = "", followUp: String = "") {
        self.id = UUID()
        self.projectName = projectName
        self.taskDescription = taskDescription
        self.startTime = startTime
        self.themeColor = themeColor
        self.goals = goals
        self.expectedTime = expectedTime
        self.actualCompletion = actualCompletion
        self.reflection = reflection
        self.followUp = followUp
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
    @Published var isPaused: Bool = false
    
    private var timer: Timer?
    private let dataManager = DataManager.shared
    
    init() {
        loadSessions()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    func startSession(project: String, task: String, themeColor: String = "#00CE4A", goals: [String] = [], expectedTime: TimeInterval = 1800, actualCompletion: String = "", reflection: String = "", followUp: String = "") {
        let trimmedProject = project.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedProject.isEmpty else { return }
        
        endCurrentSession()
        
        let newSession = FocusSession(
            projectName: trimmedProject,
            taskDescription: trimmedTask,
            startTime: Date(),
            themeColor: themeColor,
            goals: goals,
            expectedTime: expectedTime,
            actualCompletion: actualCompletion,
            reflection: reflection,
            followUp: followUp
        )
        
        currentSession = newSession
        elapsedTime = 0
        isPaused = false
        startTimer()
    }
    
    func pauseSession() {
        guard currentSession != nil, !isPaused else { return }
        isPaused = true
        stopTimer()
    }
    
    func resumeSession() {
        guard currentSession != nil, isPaused else { return }
        isPaused = false
        startTimer()
    }
    
    func endCurrentSession() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        // 这里不做时长过滤，过滤逻辑在View里实现
        sessions.append(session)
        updatePlanActualTime(for: session)
        currentSession = nil
        isPaused = false
        stopTimer()
        saveSessions()
    }

    /// 丢弃当前会话（不保存）
    func discardCurrentSession() {
        currentSession = nil
        isPaused = false
        stopTimer()
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
    
    // MARK: - Settings Support Methods
    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
    }
    
    func updateSession(_ updatedSession: FocusSession) {
        guard let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) else { return }
        sessions[index] = updatedSession
        saveSessions()
    }
    
    private func updatePlanActualTime(for session: FocusSession) {
        var plans = dataManager.loadPlans()
        
        // 只在当前计划中查找并更新匹配的项目
        guard let currentPlanId = dataManager.loadCurrentPlanId(),
              let currentPlanIndex = plans.firstIndex(where: { $0.id == currentPlanId }),
              let planItemIndex = plans[currentPlanIndex].planItems.firstIndex(where: { $0.project == session.projectName }) else {
            return
        }
        
        plans[currentPlanIndex].planItems[planItemIndex].actualTime += session.duration
        plans[currentPlanIndex].updateLastModified()
        dataManager.savePlans(plans)
    }
    
    private func loadSessions() {
        sessions = dataManager.loadSessions()
    }
    
    private func saveSessions() {
        dataManager.saveSessions(sessions)
    }
}

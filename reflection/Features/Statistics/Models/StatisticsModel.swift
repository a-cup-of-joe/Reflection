//
//  StatisticsModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation

struct StatisticsData {
    let totalPlannedTime: TimeInterval
    let totalActualTime: TimeInterval
    let totalSessions: Int
    let averageSessionDuration: TimeInterval
    let projectStats: [ProjectStatistics]
    
    var efficiency: Double {
        guard totalPlannedTime > 0 else { return 0 }
        return totalActualTime / totalPlannedTime
    }
}

struct ProjectStatistics: Identifiable {
    let id = UUID()
    let projectName: String
    let plannedTime: TimeInterval
    let actualTime: TimeInterval
    let sessionCount: Int
    
    var efficiency: Double {
        guard plannedTime > 0 else { return 0 }
        return actualTime / plannedTime
    }
    
    var timeDifference: TimeInterval {
        actualTime - plannedTime
    }
}

class StatisticsViewModel: ObservableObject {
    @Published var statisticsData: StatisticsData?
    
    private let dataManager = DataManager.shared
    
    init() {
        calculateStatistics()
    }
    
    func calculateStatistics() {
        let plans = dataManager.loadPlans()
        let sessions = dataManager.loadSessions()
        
        let totalPlannedTime = plans.reduce(0) { $0 + $1.plannedTime }
        let totalActualTime = plans.reduce(0) { $0 + $1.actualTime }
        let totalSessions = sessions.count
        let averageSessionDuration = sessions.isEmpty ? 0 : sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
        
        // 按项目分组统计
        var projectStatsDict: [String: ProjectStatistics] = [:]
        
        for plan in plans {
            let projectSessions = sessions.filter { $0.projectName == plan.project }
            let stats = ProjectStatistics(
                projectName: plan.project,
                plannedTime: plan.plannedTime,
                actualTime: plan.actualTime,
                sessionCount: projectSessions.count
            )
            projectStatsDict[plan.project] = stats
        }
        
        statisticsData = StatisticsData(
            totalPlannedTime: totalPlannedTime,
            totalActualTime: totalActualTime,
            totalSessions: totalSessions,
            averageSessionDuration: averageSessionDuration,
            projectStats: Array(projectStatsDict.values)
        )
    }
    
    func refreshStatistics() {
        calculateStatistics()
    }
}

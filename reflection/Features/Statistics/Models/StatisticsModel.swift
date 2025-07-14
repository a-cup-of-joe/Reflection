//
//  StatisticsModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation

// MARK: - StatisticsData Model
struct StatisticsData {
    let totalPlannedTime: TimeInterval
    let totalActualTime: TimeInterval
    let totalSessions: Int
    let averageSessionDuration: TimeInterval
    let projectStats: [ProjectStatistics]
    
    /// 总体效率（实际时间 / 计划时间）
    var efficiency: Double {
        guard totalPlannedTime > 0 else { return 0 }
        return totalActualTime / totalPlannedTime
    }
}

// MARK: - ProjectStatistics Model
struct ProjectStatistics: Identifiable {
    let id = UUID()
    let projectName: String
    let plannedTime: TimeInterval
    let actualTime: TimeInterval
    let sessionCount: Int
    
    /// 项目效率
    var efficiency: Double {
        guard plannedTime > 0 else { return 0 }
        return actualTime / plannedTime
    }
    
    /// 时间差异
    var timeDifference: TimeInterval {
        actualTime - plannedTime
    }
}

// MARK: - StatisticsViewModel
final class StatisticsViewModel: ObservableObject {
    @Published var statisticsData: StatisticsData?
    
    private let dataManager = DataManager.shared
    
    init() {
        calculateStatistics()
    }
    
    // MARK: - Public Methods
    func refreshStatistics() {
        calculateStatistics()
    }
    
    // MARK: - Private Methods
    private func calculateStatistics() {
        let plans = dataManager.loadPlans()
        let sessions = dataManager.loadSessions()
        
        // 获取所有计划项目
        let allPlanItems = plans.flatMap { $0.planItems }
        
        // 计算总体统计
        let totalPlannedTime = allPlanItems.reduce(into: 0) { $0 += $1.plannedTime }
        let totalActualTime = allPlanItems.reduce(into: 0) { $0 += $1.actualTime }
        let totalSessions = sessions.count
        
        let averageSessionDuration = sessions.isEmpty ? 0 : 
            sessions.reduce(into: 0) { $0 += $1.duration } / Double(sessions.count)
        
        // 计算项目统计
        let projectStats = calculateProjectStatistics(plans: allPlanItems, sessions: sessions)
        
        statisticsData = StatisticsData(
            totalPlannedTime: totalPlannedTime,
            totalActualTime: totalActualTime,
            totalSessions: totalSessions,
            averageSessionDuration: averageSessionDuration,
            projectStats: projectStats
        )
    }
    
    private func calculateProjectStatistics(plans: [PlanItem], sessions: [FocusSession]) -> [ProjectStatistics] {
        plans.map { plan in
            let projectSessions = sessions.filter { $0.projectName == plan.project }
            return ProjectStatistics(
                projectName: plan.project,
                plannedTime: plan.plannedTime,
                actualTime: plan.actualTime,
                sessionCount: projectSessions.count
            )
        }
    }
}

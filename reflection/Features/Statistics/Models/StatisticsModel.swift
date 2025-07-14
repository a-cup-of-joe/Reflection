//
//  StatisticsModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

// MARK: - StatisticsItem Model
struct StatisticsItem: Identifiable {
    let id: UUID
    let project: String
    let plannedTime: TimeInterval
    let actualTime: TimeInterval
    let themeColor: String
    
    /// 完成度百分比 (可以超过 100%)
    var completionPercentage: Double {
        guard plannedTime > 0 else { return 0 }
        return actualTime / plannedTime
    }
    
    /// SwiftUI 颜色对象
    var themeColorSwiftUI: Color {
        Color(hex: themeColor)
    }
    
    /// 是否为特殊材质
    var isSpecialMaterial: Bool {
        Color.isSpecialMaterial(themeColor)
    }
    
    /// 特殊材质渐变
    var specialMaterialGradient: LinearGradient? {
        Color.getSpecialMaterialGradient(themeColor)
    }
    
    /// 特殊材质阴影
    var specialMaterialShadow: Color? {
        Color.getSpecialMaterialShadow(themeColor)
    }
}

// MARK: - StatisticsViewModel
final class StatisticsViewModel: ObservableObject {
    @Published var statisticsItems: [StatisticsItem] = []
    @Published var currentPlan: Plan?
    @Published var todaySessions: [FocusSession] = []
    @Published var selectedDate: Date = Date()
    @Published var isHistoryMode: Bool = false
    @Published var availableDates: [Date] = []
    
    private let dataManager = DataManager.shared
    
    init() {
        loadCurrentPlan()
        loadAvailableDates()
        loadSessionsForDate(selectedDate)
        calculateStatistics()
    }
    
    // MARK: - Public Methods
    func refreshStatistics() {
        loadCurrentPlan()
        loadAvailableDates()
        loadSessionsForDate(selectedDate)
        calculateStatistics()
    }
    
    func enterHistoryMode() {
        isHistoryMode = true
        loadAvailableDates()
    }
    
    func exitHistoryMode() {
        isHistoryMode = false
        selectedDate = Date()
        loadSessionsForDate(selectedDate)
        calculateStatistics()
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        loadSessionsForDate(date)
        calculateStatistics()
    }
    
    var isToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }
    
    // MARK: - Private Methods
    private func loadCurrentPlan() {
        let plans = dataManager.loadPlans()
        
        if let currentPlanId = dataManager.loadCurrentPlanId(),
           let plan = plans.first(where: { $0.id == currentPlanId }) {
            currentPlan = plan
        } else if let firstPlan = plans.first {
            currentPlan = firstPlan
        } else {
            currentPlan = nil
        }
    }
    
    private func loadAvailableDates() {
        let allSessions = dataManager.loadSessions()
        let calendar = Calendar.current
        
        let uniqueDates = Set(allSessions.map { session in
            calendar.startOfDay(for: session.startTime)
        })
        
        availableDates = Array(uniqueDates).sorted(by: >)
    }
    
    private func loadSessionsForDate(_ date: Date) {
        let allSessions = dataManager.loadSessions()
        let calendar = Calendar.current
        
        todaySessions = allSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
    
    private func calculateStatistics() {
        guard let currentPlan = currentPlan else {
            statisticsItems = []
            return
        }
        
        var tempStatisticsItems: [StatisticsItem] = []
        
        // 为每个计划项目计算实际时间
        for planItem in currentPlan.planItems {
            let projectSessions = todaySessions.filter { session in
                session.projectName == planItem.project
            }
            
            let totalActualTime = projectSessions.reduce(0) { total, session in
                total + session.duration
            }
            
            let statisticsItem = StatisticsItem(
                id: planItem.id,
                project: planItem.project,
                plannedTime: planItem.plannedTime,
                actualTime: totalActualTime,
                themeColor: planItem.themeColor
            )
            
            tempStatisticsItems.append(statisticsItem)
        }
        
        statisticsItems = tempStatisticsItems
    }
}


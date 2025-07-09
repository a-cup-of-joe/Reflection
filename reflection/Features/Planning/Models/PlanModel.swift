//
//  PlanModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

struct PlanItem: Identifiable, Codable {
    let id = UUID()
    var project: String
    var plannedTime: TimeInterval // 计划时间（秒）
    var actualTime: TimeInterval = 0 // 实际投入时间（秒）
    var createdAt: Date = Date()
    var themeColor: String = "#00CE4A" // 主题色，默认为主绿色
    
    var plannedTimeFormatted: String {
        TimeFormatters.formatDuration(plannedTime)
    }
    
    var actualTimeFormatted: String {
        TimeFormatters.formatDuration(actualTime)
    }
    
    var timeDifference: TimeInterval {
        actualTime - plannedTime
    }
    
    var completionPercentage: Double {
        guard plannedTime > 0 else { return 0 }
        return min(actualTime / plannedTime, 1.0)
    }
    
    var themeColorSwiftUI: Color {
        Color(hex: themeColor)
    }
}

class PlanViewModel: ObservableObject {
    @Published var plans: [PlanItem] = []
    private let dataManager = DataManager.shared
    
    init() {
        loadPlans()
    }
    
    func addPlan(project: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
        let newPlan = PlanItem(project: project, plannedTime: plannedTime, themeColor: themeColor)
        plans.append(newPlan)
        savePlans()
    }
    
    func deletePlan(at indexSet: IndexSet) {
        plans.remove(atOffsets: indexSet)
        savePlans()
    }
    
    func updateActualTime(for planId: UUID, additionalTime: TimeInterval) {
        if let index = plans.firstIndex(where: { $0.id == planId }) {
            plans[index].actualTime += additionalTime
            savePlans()
        }
    }
    
    private func loadPlans() {
        plans = dataManager.loadPlans()
    }
    
    private func savePlans() {
        dataManager.savePlans(plans)
    }
}

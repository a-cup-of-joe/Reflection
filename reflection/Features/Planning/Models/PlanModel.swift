//
//  PlanModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

// MARK: - PlanItem Model
struct PlanItem: Identifiable, Codable {
    let id: UUID
    var project: String
    var plannedTime: TimeInterval
    var actualTime: TimeInterval
    let createdAt: Date
    var themeColor: String
    
    init(project: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
        self.id = UUID()
        self.project = project
        self.plannedTime = plannedTime
        self.actualTime = 0
        self.createdAt = Date()
        self.themeColor = themeColor
    }
}

// MARK: - PlanItem Extensions
extension PlanItem {
    
    /// 实际时间与计划时间的差值
    var timeDifference: TimeInterval {
        actualTime - plannedTime
    }
    
    /// 完成度百分比（0-1）
    var completionPercentage: Double {
        guard plannedTime > 0 else { return 0 }
        return min(actualTime / plannedTime, 1.0)
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

// MARK: - PlanViewModel
final class PlanViewModel: ObservableObject {
    @Published var plans: [PlanItem] = []
    
    private let dataManager = DataManager.shared
    
    init() {
        loadPlans()
    }
    
    // MARK: - Public Methods
    func addPlan(project: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
        let trimmedProject = project.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProject.isEmpty else { return }
        
        let newPlan = PlanItem(project: trimmedProject, plannedTime: plannedTime, themeColor: themeColor)
        plans.append(newPlan)
        savePlans()
    }
    
    func updatePlan(planId: UUID, project: String, plannedTime: TimeInterval, themeColor: String) {
        guard let index = plans.firstIndex(where: { $0.id == planId }) else { return }
        
        let trimmedProject = project.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProject.isEmpty else { return }
        
        plans[index].project = trimmedProject
        plans[index].plannedTime = plannedTime
        plans[index].themeColor = themeColor
        savePlans()
    }
    
    func deletePlan(at indexSet: IndexSet) {
        plans.remove(atOffsets: indexSet)
        savePlans()
    }
    
    func deletePlan(planId: UUID) {
        plans.removeAll { $0.id == planId }
        savePlans()
    }
    
    func updateActualTime(for planId: UUID, additionalTime: TimeInterval) {
        guard let index = plans.firstIndex(where: { $0.id == planId }) else { return }
        
        plans[index].actualTime += additionalTime
        savePlans()
    }
    
    // MARK: - Drag and Drop Support
    func movePlan(from source: IndexSet, to destination: Int) {
        plans.move(fromOffsets: source, toOffset: destination)
        savePlans()
    }
    
    func movePlan(fromIndex: Int, toIndex: Int) {
        guard isValidMove(fromIndex: fromIndex, toIndex: toIndex) else { return }
        
        let plan = plans.remove(at: fromIndex)
        let insertIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        plans.insert(plan, at: insertIndex)
        savePlans()
    }
    
    // MARK: - Private Helper Methods
    private func loadPlans() {
        plans = dataManager.loadPlans()
    }
    
    private func savePlans() {
        dataManager.savePlans(plans)
    }
    
    private func isValidMove(fromIndex: Int, toIndex: Int) -> Bool {
        fromIndex >= 0 && fromIndex < plans.count &&
        toIndex >= 0 && toIndex <= plans.count &&
        fromIndex != toIndex
    }
}

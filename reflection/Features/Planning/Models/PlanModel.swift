//
//  PlanModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

// MARK: - Plan Model
struct Plan: Identifiable, Codable {
    let id: UUID
    var name: String
    var planItems: [PlanItem]
    let createdAt: Date
    var lastModified: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.planItems = []
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    mutating func updateLastModified() {
        self.lastModified = Date()
    }
}

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
    @Published var plans: [Plan] = []
    @Published var currentPlan: Plan?
    @Published var currentPlanItems: [PlanItem] = []
    
    private let dataManager = DataManager.shared
    
    init() {
        loadPlans()
        loadCurrentPlan()
    }
    
    // MARK: - Plan Management
    func createNewPlan(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let newPlan = Plan(name: trimmedName)
        plans.append(newPlan)
        switchToPlan(newPlan)
        savePlans()
    }
    
    func switchToPlan(_ plan: Plan) {
        currentPlan = plan
        currentPlanItems = plan.planItems
        dataManager.saveCurrentPlanId(plan.id)
    }
    
    func updatePlanName(_ planId: UUID, newName: String) {
        guard let index = plans.firstIndex(where: { $0.id == planId }) else { return }
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        plans[index].name = trimmedName
        plans[index].updateLastModified()
        if currentPlan?.id == planId {
            currentPlan = plans[index]
        }
        savePlans()
    }
    
    func deletePlan(_ planId: UUID) {
        guard plans.count > 1 else { return }
        plans.removeAll { $0.id == planId }
        if currentPlan?.id == planId {
            let fallback = plans.first!
            switchToPlan(fallback)
        }
        savePlans()
    }
    
    // MARK: - PlanItem Management (只操作当前计划)
    func addPlanItem(project: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
        guard var plan = currentPlan else { return }
        let trimmedProject = project.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProject.isEmpty else { return }
        let newPlanItem = PlanItem(project: trimmedProject, plannedTime: plannedTime, themeColor: themeColor)
        plan.planItems.append(newPlanItem)
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    func updatePlanItem(planItemId: UUID, project: String, plannedTime: TimeInterval, themeColor: String) {
        guard var plan = currentPlan,
              let index = plan.planItems.firstIndex(where: { $0.id == planItemId }) else { return }
        let trimmedProject = project.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProject.isEmpty else { return }
        plan.planItems[index].project = trimmedProject
        plan.planItems[index].plannedTime = plannedTime
        plan.planItems[index].themeColor = themeColor
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    func deletePlanItem(at indexSet: IndexSet) {
        guard var plan = currentPlan else { return }
        plan.planItems.remove(atOffsets: indexSet)
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    func deletePlanItem(planItemId: UUID) {
        guard var plan = currentPlan else { return }
        plan.planItems.removeAll { $0.id == planItemId }
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    func updateActualTime(for planItemId: UUID, additionalTime: TimeInterval) {
        guard var plan = currentPlan,
              let index = plan.planItems.firstIndex(where: { $0.id == planItemId }) else { return }
        plan.planItems[index].actualTime += additionalTime
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    // MARK: - Drag and Drop Support (只操作当前计划)
    func movePlanItem(from source: IndexSet, to destination: Int) {
        guard var plan = currentPlan else { return }
        plan.planItems.move(fromOffsets: source, toOffset: destination)
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    func movePlanItem(fromIndex: Int, toIndex: Int) {
        guard var plan = currentPlan,
              isValidMove(fromIndex: fromIndex, toIndex: toIndex, count: plan.planItems.count) else { return }
        plan.planItems.move(fromOffsets: IndexSet([fromIndex]), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        plan.updateLastModified()
        updateCurrentPlan(plan)
        currentPlanItems = plan.planItems
        savePlans()
    }
    
    func indexOfPlanItem(withId id: UUID) -> Int? {
        return currentPlanItems.firstIndex(where: { $0.id == id })
    }
    
    // MARK: - Private Helper Methods
    private func loadPlans() {
        plans = dataManager.loadPlans()
    }
    
    private func loadCurrentPlan() {
        let allPlans = dataManager.loadPlans()
        plans = allPlans
        if let currentId = dataManager.loadCurrentPlanId(),
           let plan = allPlans.first(where: { $0.id == currentId }) {
            currentPlan = plan
            currentPlanItems = plan.planItems
        } else if let first = allPlans.first {
            currentPlan = first
            currentPlanItems = first.planItems
            dataManager.saveCurrentPlanId(first.id)
        } else {
            let defaultPlan = Plan(name: "default")
            plans = [defaultPlan]
            currentPlan = defaultPlan
            currentPlanItems = []
            savePlans()
            dataManager.saveCurrentPlanId(defaultPlan.id)
        }
    }
    
    private func updateCurrentPlan(_ updatedPlan: Plan) {
        guard let index = plans.firstIndex(where: { $0.id == updatedPlan.id }) else { return }
        plans[index] = updatedPlan
        currentPlan = updatedPlan
    }
    
    private func savePlans() {
        dataManager.savePlans(plans)
    }
    
    private func isValidMove(fromIndex: Int, toIndex: Int, count: Int) -> Bool {
        fromIndex >= 0 && fromIndex < count &&
        toIndex >= 0 && toIndex <= count &&
        fromIndex != toIndex
    }
}

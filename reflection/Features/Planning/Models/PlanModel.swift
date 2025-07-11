//
//  PlanModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

// struct PlanItem: Identifiable, Codable {
//     var id: UUID = UUID()
//     var project: String
//     var plannedTime: TimeInterval // 计划时间（秒）
//     var actualTime: TimeInterval = 0 // 实际投入时间（秒）
//     var createdAt: Date = Date()
//     var themeColor: String = "#00CE4A" // 主题色，默认为主绿色
    
//     init(project: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
//         self.id = UUID()
//         self.project = project
//         self.plannedTime = plannedTime
//         self.actualTime = 0
//         self.createdAt = Date()
//         self.themeColor = themeColor
//     }
    
//     var plannedTimeFormatted: String {
//         TimeFormatters.formatDuration(plannedTime)
//     }
    
//     var actualTimeFormatted: String {
//         TimeFormatters.formatDuration(actualTime)
//     }
    
//     var timeDifference: TimeInterval {
//         actualTime - plannedTime
//     }
    
//     var completionPercentage: Double {
//         guard plannedTime > 0 else { return 0 }
//         return min(actualTime / plannedTime, 1.0)
//     }
    
//     var themeColorSwiftUI: Color {
//         Color(hex: themeColor)
//     }
    
//     // 检查是否为特殊材质
//     var isSpecialMaterial: Bool {
//         Color.isSpecialMaterial(themeColor)
//     }
    
//     // 获取特殊材质渐变
//     var specialMaterialGradient: LinearGradient? {
//         Color.getSpecialMaterialGradient(themeColor)
//     }
    
//     // 获取特殊材质阴影
//     var specialMaterialShadow: Color? {
//         Color.getSpecialMaterialShadow(themeColor)
//     }
// }

class PlanViewModel: ObservableObject {
    private let dataManager = AppDataManager.shared
    
    init() {
        loadPlans()
    }
    
    func addTimeBar(name: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
        if let activity = dataManager.getActivity(by: name: name) {
            // 如果活动已存在，直接使用现有活动的ID
            let activityId = activity.id
            activity.themeColor = themeColor
        } else {
            // 如果活动不存在，创建一个新的活动
            let newActivity = Activity(name: name, themeColor: themeColor)
            dataManager.addActivity(newActivity)
            let activityId = newActivity.id
        }
        timeBar = TimeBar(id: UUID(), activityId: activityId, plannedTime: plannedTime)
        dataManager.addTimeBar(timeBar)
    }
    
    func deleteTimeBar(at indexSet: IndexSet) {
        dataManager.removeTimeBar(at: indexSet)
    }
    
    // func updateActualTime(for planId: UUID, additionalTime: TimeInterval) {
    //     if let index = plans.firstIndex(where: { $0.id == planId }) {
    //         plans[index].actualTime += additionalTime
    //         dataManager.savePlans(plans)
    //     }
    // }
    
    func updateTimeBar(timeBarId: UUID, name: String, plannedTime: TimeInterval, themeColor: String) {
        // 处理活动
        if let activity = dataManager.getActivity(by: name: name) {
            // 如果活动已存在，直接使用现有活动的ID
            let activityId = activity.id
            activity.themeColor = themeColor
        } else {
            // 如果活动不存在，创建一个新的活动
            let newActivity = Activity(name: name, themeColor: themeColor)
            dataManager.addActivity(newActivity)
            let activityId = newActivity.id
        }

        timeBar = TimeBar(id: timeBarId, activityId: activityId, plannedTime: plannedTime)

        dataManager.updateTimeBar(
            timeBar: timeBar
        )
    }

    func deleteTimeBar(timeBarId: UUID) {
        dataManager.deleteTimeBar(timeBarId: timeBarId)
    }
    
    // MARK: - Drag and Drop Support
    func movePlan(from source: IndexSet, to destination: Int) {
        plans.move(fromOffsets: source, toOffset: destination)
        dataManager.savePlans(plans)
    }
    
    func movePlan(fromIndex: Int, toIndex: Int) {
        dataManager.movePlan(fromIndex: fromIndex, toIndex: toIndex)
    }
}

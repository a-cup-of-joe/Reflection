//
//  PlanModel.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation
import SwiftUI

class PlanViewModel: ObservableObject {
    static let shared = PlanViewModel()
    private let dataManager = DataManager.shared
    
    init() {
    }
    
    func addTimeBar(name: String, plannedTime: TimeInterval, themeColor: String = "#00CE4A") {
        let activityId: UUID
        if let activity = dataManager.getActivity(by: name) {
            // 如果活动已存在，直接使用现有活动的ID
            activityId = activity.id
            // 更新活动的主题色（如果需要）
            if activity.themeColor != themeColor {
                let updatedActivity = Activity(id: activity.id, name: name, themeColor: themeColor)
                dataManager.updateActivity(updatedActivity)
            }
        } else {
            // 如果活动不存在，创建一个新的活动
            let newActivity = Activity(name: name, themeColor: themeColor)
            dataManager.addActivity(newActivity)
            activityId = newActivity.id
        }
        
        let timeBar = TimeBar(id: UUID(), activityId: activityId, plannedTime: plannedTime)
        dataManager.addTimeBar(timeBar: timeBar)
    }
    
    func deleteTimeBar(at indexSet: IndexSet) {
        dataManager.deleteTimeBar(at: indexSet)
    }
    
    func updateTimeBar(timeBarId: UUID, name: String, plannedTime: TimeInterval, themeColor: String) {
        let activityId: UUID
        // 处理活动
        if let activity = dataManager.getActivity(by: name) {
            // 如果活动已存在，直接使用现有活动的ID
            activityId = activity.id
            // 更新活动的主题色（如果需要）
            if activity.themeColor != themeColor {
                let updatedActivity = Activity(id: activity.id, name: name, themeColor: themeColor)
                dataManager.updateActivity(updatedActivity)
            }
        } else {
            // 如果活动不存在，创建一个新的活动
            let newActivity = Activity(name: name, themeColor: themeColor)
            dataManager.addActivity(newActivity)
            activityId = newActivity.id
        }

        let timeBar = TimeBar(id: timeBarId, activityId: activityId, plannedTime: plannedTime)
        dataManager.updatedTimeBar(timeBar: timeBar)
    }

    func deleteTimeBar(timeBarId: UUID) {
        dataManager.deleteTimeBar(timeBarId: timeBarId)
    }
    
    // MARK: - Drag and Drop Support
    func moveTimeBar(from source: IndexSet, to destination: Int) {
        dataManager.moveTimeBar(from: source, to: destination)
    }
    
    func moveTimeBar(fromIndex: Int, toIndex: Int) {
        dataManager.moveTimeBar(fromIndex: fromIndex, toIndex: toIndex)
    }

    func getTimeBar(by id: UUID) -> TimeBar? {
        return dataManager.getTimeBar(by: id)
    }

    func getPlannedTime(for timeBarID: UUID) -> TimeInterval? {
        guard let timeBar = dataManager.getTimeBar(by: timeBarID) else { return nil }
        return timeBar.plannedTime
    }

    func getColor(for timeBarID: UUID) -> Color {
        guard let timeBar = dataManager.getTimeBar(by: timeBarID),
              let activity = dataManager.getActivity(by: timeBar.activityId) else {
            return Color.gray // 默认颜色
        }
        return Color(hex: activity.themeColor)
    }

    func getActivityName(for timeBarID: UUID) -> String? {
        guard let timeBar = dataManager.getTimeBar(by: timeBarID),
              let activity = dataManager.getActivity(by: timeBar.activityId) else {
            return nil
        }
        return activity.name
    }

    func getFormattedPlannedTime(for timeBarID: UUID) -> String? {
        guard let timeBar = dataManager.getTimeBar(by: timeBarID) else { return nil }
        let totalMinutes = Int(timeBar.plannedTime / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
//
//  DataManager.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation

/// 数据管理器，负责应用数据的持久化存储
final class DataManager {
    static let shared = DataManager()
    
    private let plansKey = "saved_plans"
    private let sessionsKey = "saved_sessions"
    private let currentPlanIdKey = "current_plan_id"
    
    private init() {}
    
    // MARK: - Plans Management
    func savePlans(_ plans: [Plan]) {
        if let encoded = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(encoded, forKey: plansKey)
        }
    }
    
    func loadPlans() -> [Plan] {
        guard let data = UserDefaults.standard.data(forKey: plansKey),
              let decoded = try? JSONDecoder().decode([Plan].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Current Plan Management
    func saveCurrentPlanId(_ planId: UUID) {
        UserDefaults.standard.set(planId.uuidString, forKey: currentPlanIdKey)
    }
    
    func loadCurrentPlanId() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: currentPlanIdKey) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    // MARK: - Sessions Management
    func saveSessions(_ sessions: [FocusSession]) {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    func loadSessions() -> [FocusSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Utility Methods
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: plansKey)
        UserDefaults.standard.removeObject(forKey: sessionsKey)
        UserDefaults.standard.removeObject(forKey: currentPlanIdKey)
    }
}

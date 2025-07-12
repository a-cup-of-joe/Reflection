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
    
    private init() {}
    
    // MARK: - Plans Management
    func savePlans(_ plans: [PlanItem]) {
        if let encoded = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(encoded, forKey: plansKey)
        }
    }
    
    func loadPlans() -> [PlanItem] {
        guard let data = UserDefaults.standard.data(forKey: plansKey),
              let decoded = try? JSONDecoder().decode([PlanItem].self, from: data) else {
            return []
        }
        return decoded
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
    }
}

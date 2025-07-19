//
//  TaskDraftModel.swift
//  reflection
//
//  Created by AI Assistant on 2025/7/19.
//

import Foundation

struct TaskDraft: Codable {
    let selectedPlanID: UUID?
    let taskDescription: String
    let expectedTime: String
    let goals: [String]
    let timestamp: Date

    init(selectedPlanID: UUID?, taskDescription: String, expectedTime: String, goals: [String]) {
        self.selectedPlanID = selectedPlanID
        self.taskDescription = taskDescription
        self.expectedTime = expectedTime
        self.goals = goals
        self.timestamp = Date()
    }
}

class TaskDraftManager {
    static let shared = TaskDraftManager()
    private let draftKey = "taskDraft"
    
    private init() {}
    
    func saveDraft(selectedPlanID: UUID?, taskDescription: String, expectedTime: String, goals: [String]) {
        let draft = TaskDraft(
            selectedPlanID: selectedPlanID,
            taskDescription: taskDescription,
            expectedTime: expectedTime,
            goals: goals
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(draft)
            UserDefaults.standard.set(data, forKey: draftKey)
        } catch {
            print("Failed to save task draft: \(error)")
        }
    }
    
    func loadDraft() -> TaskDraft? {
        guard let data = UserDefaults.standard.data(forKey: draftKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let draft = try decoder.decode(TaskDraft.self, from: data)
            return draft
        } catch {
            print("Failed to load task draft: \(error)")
            return nil
        }
    }
    
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
    }
    
    func hasDraft() -> Bool {
        return UserDefaults.standard.data(forKey: draftKey) != nil
    }
}

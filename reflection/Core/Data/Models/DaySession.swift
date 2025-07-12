import Foundation

struct DaySession: Identifiable, Codable {
    let id: UUID
    var sessions: [Session]
    let createdAt: Date

    init(id: UUID = UUID(), sessions: [Session] = [], createdAt: Date = Calendar.current.startOfDay(for: Date())) {
        self.id = id
        self.sessions = sessions
        self.createdAt = createdAt
    }
}

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    let activityId: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    var isActive: Bool {
        endTime == nil
    }

    var taskDescription: String
    
    init(id: UUID = UUID(), activityId: UUID, startTime: Date, endTime: Date? = nil, taskDescription: String) {
        self.id = id
        self.activityId = activityId
        self.startTime = startTime
        self.endTime = endTime
        self.taskDescription = taskDescription
    }
}

struct DaySession: Identifiable, Codable {
    let id: UUID
    let sessions: [Session]
    let createdAt: Date

    func init() {
        id = UUID()
        sessions = []
        createdAt = Calendar.current.startOfDay(for: Date())
    }
}

struct Session: Identifiable, Codable {
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
}
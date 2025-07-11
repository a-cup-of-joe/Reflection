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
    let startTime: Date
    let duration: TimeInterval
}
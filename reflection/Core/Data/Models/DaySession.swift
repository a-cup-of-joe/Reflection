struct DaySession: Identifiable, Codable {
    let id: UUID
    let sessions: [Session]
    let createdAt: Date
}

struct Session: Identifiable, Codable {
    let id: UUID
    let activityId: UUID
    let startTime: Date
    let duration: TimeInterval

    var actualTimeFormatted: String {
        TimeFormatters.formatDuration(duration)
    }
}
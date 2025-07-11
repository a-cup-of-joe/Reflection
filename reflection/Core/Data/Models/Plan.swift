struct Plan: Identifiable, Codable {
    let id: UUID
    let name: String
    let timeBars: [TimeBar]
    let createdAt: Date
    let updatedAt: Date

    init(id: UUID = UUID(), name: String, timeBars: [TimeBar] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.timeBars = timeBars
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func addTimeBar(_ timeBar: TimeBar) {
        var updatedTimeBars = timeBars
        updatedTimeBars.append(timeBar)
        self.timeBars = updatedTimeBars
        self.updatedAt = Date()
    }

    func deleteTimeBar(_ timeBar: TimeBar) {
        var updatedTimeBars = timeBars
        updatedTimeBars.removeAll { $0.id == timeBar.id }
        self.timeBars = updatedTimeBars
        self.updatedAt = Date()
    }
}

struct TimeBar: Identifiable, Codable {
    let id: UUID
    let activityId: UUID
    var plannedTime: TimeInterval

    init(id: UUID, activityId: UUID, plannedTime: TimeInterval) {
        self.id = id
        self.activityId = activityId
        self.plannedTime = plannedTime
    }

    var plannedTimeFormatted: String {
        TimeFormatters.formatDuration(plannedTime)
    }
}
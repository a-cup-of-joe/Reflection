import Foundation

struct Plan: Identifiable, Codable {
    let id: UUID
    var name: String
    var timeBars: [TimeBar]
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, timeBars: [TimeBar] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.timeBars = timeBars
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct TimeBar: Identifiable, Codable {
    let id: UUID
    let activityId: UUID
    var plannedTime: TimeInterval

    init(id: UUID = UUID(), activityId: UUID, plannedTime: TimeInterval) {
        self.id = id
        self.activityId = activityId
        self.plannedTime = plannedTime
    }
}
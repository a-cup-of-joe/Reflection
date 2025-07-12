import SwiftUI

struct Activity: Identifiable, Codable {
    let id: UUID
    var name: String        // 唯一名称
    var themeColor: String  // 主题色
    
    init(id: UUID = UUID(), name: String, themeColor: String) {
        self.id = id
        self.name = name
        self.themeColor = themeColor
    }
}
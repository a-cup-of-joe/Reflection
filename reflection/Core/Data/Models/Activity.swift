import SwiftUI

struct Activity: Identifiable, Codable {
    let id: UUID
    let name: String        // 唯一名称
    let themeColor: String  // 主题色
    
    init(id: UUID = UUID(), name: String, themeColor: String) {
        self.id = id
        self.name = name
        self.themeColor = themeColor
    }
}
// 现在我想重构最基础的数据组成和模型，暂时不改变APP前端。
// 目前的数据以时间段为基础结构。我想新加层封装：活动-计划
// 下面是几个struct（用于存数据）
// 活动：属性包括UUID，唯一名称，主题色。UUID和名称不可重复。
// 计划：包含多个时间段（timebar)，每个时间段由活动与计划时间组成。
// 实际工作（相对计划）：一个用于统计的struct，属性是活动与实际完成时间，可以通过match这个和计划来统计完成情况。
// 本质上这个改造是为了后续的“多计划视图“，所以这些属性的解耦很关键。需要看下当前的代码里是怎么存数据、前端是怎么呈现的，做到数据与前端一定程度解耦。
// 目前不需要兼容旧格式，这是个Alpha应用，可以完全删除旧格式，用简洁、可读的代码进入新格式，尽量减少冗余。
import SwiftUI

struct Activity: Identifiable, Codable {
    let id: UUID
    let name: String        // 唯一名称
    let themeColor: String  // 主题色
    
    init(name: String, themeColor: String) {
        self.id = UUID()
        self.name = name
        self.themeColor = themeColor
    }

    var themeColorSwiftUI: Color {
        Color(hex: themeColor)
    }
    
    // 检查是否为特殊材质
    var isSpecialMaterial: Bool {
        Color.isSpecialMaterial(themeColor)
    }
    
    // 获取特殊材质渐变
    var specialMaterialGradient: LinearGradient? {
        Color.getSpecialMaterialGradient(themeColor)
    }
    
    // 获取特殊材质阴影
    var specialMaterialShadow: Color? {
        Color.getSpecialMaterialShadow(themeColor)
    }
}
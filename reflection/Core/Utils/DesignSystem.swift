//
//  DesignSystem.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

// MARK: - Colors
extension Color {
    // 主色：深绿色 - 用于按钮、活跃状态和强调元素
    static let primaryGreen = Color(hex: "#00CE4A")
    // 辅助色：浅绿色 - 用于进度指示、次要元素
    static let secondaryGreen = Color(hex: "#81DA94")
    // 背景色：更浅的绿色 - 用于卡片背景或次要区域
    static let lightGreen = Color(hex: "#DBF2DC")
    // 基础色：白色 - 用于主背景和文字对比
    static let cardBackground = Color.white
    static let appBackground = Color.white
    static var textFieldBackground = Color.white
    
    // 保留一些必要的灰色用于边框等
    static let borderGray = Color(hex: "#E5E7EB")
    static let secondaryGray = Color(hex: "#6B7280")
    
    // 预设主题色 - 从红色到紫色的9种代表性颜色 + 特殊金属色
    static let themeColors: [String] = [
        "#FF4757", // 红色
        "#FF6B35", // 红橙色
        "#FF9500", // 橙色
        "#FFD700", // 金黄色
        "#32CD32", // 绿色
        "#00CED1", // 青色
        "#4169E1", // 蓝色
        "#8A2BE2", // 蓝紫色
        "#DA70D6", // 紫色
        "#GOLD_SPECIAL", // 特殊金色
        "#SILVER_SPECIAL" // 特殊银色
    ]
    
    // MARK: - 红色主题色组合
    static let primaryRed = Color(hex: "#FF4757")
    static let secondaryRed = Color(hex: "#FF6B7A")
    static let lightRed = Color(hex: "#FFE4E6")
    
    // MARK: - 红橙色主题色组合
    static let primaryRedOrange = Color(hex: "#FF6B35")
    static let secondaryRedOrange = Color(hex: "#FF8A5E")
    static let lightRedOrange = Color(hex: "#FFE8E0")
    
    // MARK: - 橙色主题色组合
    static let primaryOrange = Color(hex: "#FF9500")
    static let secondaryOrange = Color(hex: "#FFB233")
    static let lightOrange = Color(hex: "#FFF0D6")
    
    // MARK: - 金黄色主题色组合
    static let primaryGold = Color(hex: "#FFD700")
    static let secondaryGold = Color(hex: "#FFE333")
    static let lightGold = Color(hex: "#FFF8CC")
    
    // MARK: - 绿色主题色组合（保持原有设计）
    // static let primaryGreen = Color(hex: "#32CD32")
    // static let secondaryGreen = Color(hex: "#5FD65F")
    // static let lightGreen = Color(hex: "#E8F5E8")
    
    // MARK: - 青色主题色组合
    static let primaryCyan = Color(hex: "#00CED1")
    static let secondaryCyan = Color(hex: "#33D9DB")
    static let lightCyan = Color(hex: "#CCF5F6")
    
    // MARK: - 蓝色主题色组合
    static let primaryBlue = Color(hex: "#4169E1")
    static let secondaryBlue = Color(hex: "#6A87E7")
    static let lightBlue = Color(hex: "#E6EBFA")
    
    // MARK: - 蓝紫色主题色组合
    static let primaryBlueViolet = Color(hex: "#8A2BE2")
    static let secondaryBlueViolet = Color(hex: "#A055E8")
    static let lightBlueViolet = Color(hex: "#F0E6FA")
    
    // MARK: - 紫色主题色组合
    static let primaryPurple = Color(hex: "#DA70D6")
    static let secondaryPurple = Color(hex: "#E393DE")
    static let lightPurple = Color(hex: "#F8ECF7")
    
    // 特殊金属材质渐变色
    static let goldGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#FFD700"), // 金黄色
            Color(hex: "#FFA500"), // 橙金色
            Color(hex: "#FFE135"), // 亮金色
            Color(hex: "#B8860B")  // 暗金色
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let silverGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#C0C0C0"), // 银色
            Color(hex: "#A8A8A8"), // 暗银色
            Color(hex: "#E6E6E6"), // 亮银色
            Color(hex: "#808080")  // 深银色
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // 金属材质阴影效果
    static let goldShadow = Color(hex: "#FFD700").opacity(0.5)
    static let silverShadow = Color(hex: "#C0C0C0").opacity(0.5)
    
    // 特殊材质判断
    static func isSpecialMaterial(_ colorHex: String) -> Bool {
        return colorHex == "#GOLD_SPECIAL" || colorHex == "#SILVER_SPECIAL"
    }
    
    static func getSpecialMaterialGradient(_ colorHex: String) -> LinearGradient? {
        switch colorHex {
        case "#GOLD_SPECIAL":
            return goldGradient
        case "#SILVER_SPECIAL":
            return silverGradient
        default:
            return nil
        }
    }
    
    static func getSpecialMaterialShadow(_ colorHex: String) -> Color? {
        switch colorHex {
        case "#GOLD_SPECIAL":
            return goldShadow
        case "#SILVER_SPECIAL":
            return silverShadow
        default:
            return nil
        }
    }
    
    // MARK: - 主题色组合获取方法
    
    /// 根据主题色获取对应的三种色调组合
    /// - Parameter themeColor: 主题色的十六进制字符串
    /// - Returns: 包含主色、次色、浅色的元组
    static func getThemeColorSet(for themeColor: String) -> (primary: Color, secondary: Color, light: Color) {
        switch themeColor {
        case "#FF4757": // 红色
            return (primaryRed, secondaryRed, lightRed)
        case "#FF6B35": // 红橙色
            return (primaryRedOrange, secondaryRedOrange, lightRedOrange)
        case "#FF9500": // 橙色
            return (primaryOrange, secondaryOrange, lightOrange)
        case "#FFD700": // 金黄色
            return (primaryGold, secondaryGold, lightGold)
        case "#32CD32": // 绿色
            return (primaryGreen, secondaryGreen, lightGreen)
        case "#00CED1": // 青色
            return (primaryCyan, secondaryCyan, lightCyan)
        case "#4169E1": // 蓝色
            return (primaryBlue, secondaryBlue, lightBlue)
        case "#8A2BE2": // 蓝紫色
            return (primaryBlueViolet, secondaryBlueViolet, lightBlueViolet)
        case "#DA70D6": // 紫色
            return (primaryPurple, secondaryPurple, lightPurple)
        case "#GOLD_SPECIAL": // 特殊金色
            return (Color(hex: "#FFD700"), Color(hex: "#FFE333"), Color(hex: "#FFF8CC"))
        case "#SILVER_SPECIAL": // 特殊银色
            return (Color(hex: "#C0C0C0"), Color(hex: "#D3D3D3"), Color(hex: "#F0F0F0"))
        default:
            return (primaryGreen, secondaryGreen, lightGreen) // 默认绿色主题
        }
    }
    
    /// 获取主题色的主色调
    static func getPrimaryColor(for themeColor: String) -> Color {
        return getThemeColorSet(for: themeColor).primary
    }
    
    /// 获取主题色的次色调
    static func getSecondaryColor(for themeColor: String) -> Color {
        return getThemeColorSet(for: themeColor).secondary
    }
    
    /// 获取主题色的浅色调
    static func getLightColor(for themeColor: String) -> Color {
        return getThemeColorSet(for: themeColor).light
    }
    
    /// 获取主题色的温柔背景色（用于ActiveSessionView）
    static func getGentleBackgroundColor(for themeColor: String) -> Color {
        switch themeColor {
        case "#FF4757": // 红色
            return gentleRedBackground
        case "#FF6B35": // 红橙色
            return gentleRedOrangeBackground
        case "#FF9500": // 橙色
            return gentleOrangeBackground
        case "#FFD700": // 金黄色
            return gentleGoldBackground
        case "#32CD32": // 绿色
            return gentleGreenBackground
        case "#00CED1": // 青色
            return gentleCyanBackground
        case "#4169E1": // 蓝色
            return gentleBlueBackground
        case "#8A2BE2": // 蓝紫色
            return gentleBlueVioletBackground
        case "#DA70D6": // 紫色
            return gentlePurpleBackground
        case "#GOLD_SPECIAL": // 特殊金色
            return gentleGoldSpecialBackground
        case "#SILVER_SPECIAL": // 特殊银色
            return gentleSilverSpecialBackground
        default:
            return gentleGreenBackground // 默认绿色主题
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        // 处理特殊金属色
        if hex == "#GOLD_SPECIAL" {
            self = Color(hex: "#FFD700") // 默认金色
            return
        }
        if hex == "#SILVER_SPECIAL" {
            self = Color(hex: "#C0C0C0") // 默认银色
            return
        }
        
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    static let largeTitle = Font.system(size: 32, weight: .bold, design: .default)
    static let title = Font.system(size: 24, weight: .semibold, design: .default)
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)
    static let subheadline = Font.system(size: 16, weight: .medium, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let small = Font.system(size: 10, weight: .regular, design: .default)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let circle: CGFloat = 50
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.primaryGreen)
            .cornerRadius(CornerRadius.circle)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.primaryGreen)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.circle)
                    .stroke(Color.primaryGreen, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Small Button Style
struct SmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.primaryGreen)
            .cornerRadius(CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Small Secondary Button Style
struct SmallSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.primaryGreen)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.primaryGreen, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SmallRedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.red)
            .cornerRadius(CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Circle Button Style
struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(Color.primaryGreen)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Progress Circle Style
struct ProgressCircle: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    init(progress: Double, size: CGFloat = 120, lineWidth: CGFloat = 8, color: Color = .secondaryGreen) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Container Style
struct ContainerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
    }
}

extension View {
    func containerStyle() -> some View {
        self.modifier(ContainerStyle())
    }
}

// MARK: - App Font Configuration
extension View {
    func appFont() -> some View {
        self.font(.system(.body, design: .default))
    }
}

// MARK: - Global App Style
struct AppStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .default))
            .accentColor(.primaryGreen)
    }
}

extension View {
    func appStyle() -> some View {
        self.modifier(AppStyle())
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.borderGray, lineWidth: 1)
            )
    }
}

// MARK: - 温柔的莫兰迪色系背景色（用于ActiveSessionView）
extension Color {
    // 红色主题的温柔背景
    static let gentleRedBackground = Color(hex: "#D4A5A5")
    
    // 红橙色主题的温柔背景
    static let gentleRedOrangeBackground = Color(hex: "#D4B5A5")
    
    // 橙色主题的温柔背景
    static let gentleOrangeBackground = Color(hex: "#D4C5A5")
    
    // 金黄色主题的温柔背景
    static let gentleGoldBackground = Color(hex: "#D4D2A5")
    
    // 绿色主题的温柔背景
    static let gentleGreenBackground = Color(hex: "#A5D4A5")
    
    // 青色主题的温柔背景
    static let gentleCyanBackground = Color(hex: "#A5D4D2")
    
    // 蓝色主题的温柔背景
    static let gentleBlueBackground = Color(hex: "#A5B5D4")
    
    // 蓝紫色主题的温柔背景
    static let gentleBlueVioletBackground = Color(hex: "#B5A5D4")
    
    // 紫色主题的温柔背景
    static let gentlePurpleBackground = Color(hex: "#C5A5D4")
    
    // 特殊金属色的温柔背景
    static let gentleGoldSpecialBackground = Color(hex: "#D4D2A5")
    static let gentleSilverSpecialBackground = Color(hex: "#C0C0C0")
}

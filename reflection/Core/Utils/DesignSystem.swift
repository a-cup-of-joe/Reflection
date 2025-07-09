//
//  DesignSystem.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let primaryGreen = Color(hex: "#00C58E")
    static let secondaryGray = Color(hex: "#6B7280")
    static let lightGray = Color(hex: "#F3F4F6")
    static let borderGray = Color(hex: "#E5E7EB")
    static let cardBackground = Color.white
    static let appBackground = Color.white
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
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
    
    init(progress: Double, size: CGFloat = 120, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lightGray, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.primaryGreen, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
            .frame(maxWidth: 800)
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

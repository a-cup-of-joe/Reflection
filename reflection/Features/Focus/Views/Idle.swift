import SwiftUI

struct BigCircleStartButton: View {
    let onTap: () -> Void
    
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @State private var isPressed = false
    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0
    @State private var innerGlowOpacity = 0.3
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity = 0.0
    
    // 行星轨道动画
    @State private var planet1Angle: Double = 0
    @State private var planet2Angle: Double = 120
    @State private var planet3Angle: Double = 240
    @State private var orbitLineAngle: Double = 0
    
    private let buttonSize: CGFloat = 240  // 增大按钮尺寸
    private let orbitRadius1: CGFloat = 140  // 第一个轨道半径
    private let orbitRadius2: CGFloat = 160  // 第二个轨道半径
    private let orbitRadius3: CGFloat = 180  // 第三个轨道半径
    
    // 获取今天的任务颜色
    private var todayTaskColors: [Color] {
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessionViewModel.sessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: today)
        }
        
        let colors = todaySessions.prefix(3).map { $0.themeColorSwiftUI }
        
        // 如果没有任务，使用默认的渐变色
        if colors.isEmpty {
            return [Color.primaryGreen, Color.blue, Color.purple]
        }
        
        // 确保至少有3个颜色（重复使用已有颜色）
        var resultColors = Array(colors)
        while resultColors.count < 3 {
            resultColors.append(contentsOf: colors)
        }
        return Array(resultColors.prefix(3))
    }
    
    var body: some View {
        ZStack {
            // 外层脉冲光环
            Circle()
                .stroke(Color.primaryGreen.opacity(0.2), lineWidth: 2)
                .frame(width: buttonSize + 60, height: buttonSize + 60)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .opacity(isPulsing ? 0.3 : 0.7)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)
            
            // 轨道线条（彩色虚线）
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        todayTaskColors[index].opacity(0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                    )
                    .frame(width: [orbitRadius1, orbitRadius2, orbitRadius3][index] * 2, 
                           height: [orbitRadius1, orbitRadius2, orbitRadius3][index] * 2)
                    .rotationEffect(.degrees(orbitLineAngle + Double(index * 30)))
                    .animation(.linear(duration: 20 + Double(index * 5)).repeatForever(autoreverses: false), value: orbitLineAngle)
            }
            
            // 行星小球
            PlanetView(
                color: todayTaskColors[0],
                angle: planet1Angle,
                radius: orbitRadius1,
                size: 12
            )
            
            PlanetView(
                color: todayTaskColors[1],
                angle: planet2Angle,
                radius: orbitRadius2,
                size: 10
            )
            
            PlanetView(
                color: todayTaskColors[2],
                angle: planet3Angle,
                radius: orbitRadius3,
                size: 8
            )
            
            // 点击涟漪效果
            Circle()
                .stroke(Color.primaryGreen.opacity(0.4), lineWidth: 3)
                .frame(width: buttonSize, height: buttonSize)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)
            
            // 主按钮
            Button(action: {
                // 触觉反馈
                NSHapticFeedbackManager.performHapticFeedback()
                
                // 涟漪效果
                withAnimation(.easeOut(duration: 0.6)) {
                    rippleScale = 1.5
                    rippleOpacity = 0.0
                }
                
                // 重置涟漪
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    rippleScale = 1.0
                    rippleOpacity = 1.0
                }
                
                onTap()
            }) {
                ZStack {
                    // 主圆形背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primaryGreen.opacity(0.9),
                                    Color.primaryGreen,
                                    Color.primaryGreen.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    
                    // 内层光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(innerGlowOpacity),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: buttonSize/2
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: innerGlowOpacity)
                    
                    // 旋转的装饰圆环
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: buttonSize - 30, height: buttonSize - 30)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                .rotationEffect(.degrees(rotationAngle))
                        )
                    
                    // 播放图标和文字
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                            .rotationEffect(.degrees(isPressed ? -5 : 0))
                            .animation(.easeInOut(duration: 0.1), value: isPressed)
                        
                        VStack(spacing: Spacing.xs) {
                            Text("开始专注")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Focus Session")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            // 按下时的触觉反馈
                            NSHapticFeedbackManager.performHapticFeedback()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .shadow(
                color: Color.primaryGreen.opacity(isPressed ? 0.4 : 0.6),
                radius: isPressed ? 12 : 20,
                x: 0,
                y: isPressed ? 6 : 10
            )
        }
        .onAppear {
            // 启动各种动画
            isPulsing = true
            
            // 内层光晕闪烁
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                innerGlowOpacity = 0.6
            }
            
            // 装饰圆环旋转
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // 行星公转动画
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                planet1Angle = 360
            }
            
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                planet2Angle = 360 + 120
            }
            
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                planet3Angle = 360 + 240
            }
            
            // 轨道线条旋转
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                orbitLineAngle = 360
            }
        }
    }
}

// MARK: - 行星小球视图
struct PlanetView: View {
    let color: Color
    let angle: Double
    let radius: CGFloat
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0.9),
                        color,
                        color.opacity(0.7)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size/2
                )
            )
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.6), radius: 4, x: 0, y: 2)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size * 0.4, height: size * 0.4)
                    .offset(x: -size * 0.15, y: -size * 0.15)
            )
            .offset(
                x: cos(angle * .pi / 180) * radius,
                y: sin(angle * .pi / 180) * radius
            )
    }
}

// 扩展触觉反馈
extension NSHapticFeedbackManager {
    static func performHapticFeedback() {
        let impactFeedback = NSHapticFeedbackManager.defaultPerformer
        impactFeedback.perform(.alignment, performanceTime: .now)
    }
}

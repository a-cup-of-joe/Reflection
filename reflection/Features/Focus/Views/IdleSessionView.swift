//
//  IdleSessionView.swift
//  reflection
//
//  Created by linan on 2025/7/13.
//

import SwiftUI

struct IdleSessionView: View {
    let onStartSession: () -> Void
    
    @EnvironmentObject var sessionViewModel: SessionViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                // 背景星空效果
                StarFieldBackground()
                
                // 行星轨道系统
                PlanetarySystem()
                
                // 专注按钮
                BigCircleStartButton {
                    onStartSession()
                }
                .padding(.horizontal, Spacing.xl)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.95),
                    Color.black
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
        )
        .transition(.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        ))
    }
}

// MARK: - 行星系统组件
struct PlanetarySystem: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    private let dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            ForEach(Array(groupedSessions.enumerated()), id: \.offset) { orbitIndex, group in
                OrbitView(
                    sessions: group.sessions,
                    orbitRadius: getOrbitRadius(for: orbitIndex),
                    orbitIndex: orbitIndex
                )
            }
        }
    }
    
    // 获取当前的TimePlan项目名称
    private var currentPlanProjects: Set<String> {
        let currentPlans = dataManager.loadPlans()
        return Set(currentPlans.map { $0.project })
    }
    
    // 按项目名称分组sessions（过滤掉少于10秒的session，且仅显示与当前TimePlan相关的）
    private var groupedSessions: [(projectName: String, sessions: [FocusSession])] {
        let filteredSessions = sessionViewModel.sessions.filter { session in
            session.duration >= 10 && currentPlanProjects.contains(session.projectName)
        }
        let grouped = Dictionary(grouping: filteredSessions) { $0.projectName }
        return grouped.map { (projectName: $0.key, sessions: $0.value) }
            .sorted { $0.projectName < $1.projectName }
    }
    
    // 根据轨道索引计算轨道半径
    private func getOrbitRadius(for index: Int) -> CGFloat {
        let baseRadius: CGFloat = 140 // 基础半径，更接近按钮
        let radiusIncrement: CGFloat = 25 // 每条轨道的半径增量，更紧凑
        return baseRadius + CGFloat(index) * radiusIncrement
    }
}

// MARK: - 单个轨道视图
struct OrbitView: View {
    let sessions: [FocusSession]
    let orbitRadius: CGFloat
    let orbitIndex: Int
    
    @State private var rotationAngle: Double = 0
    @State private var initialOffset: Double = 0
    @State private var orbitOpacity: Double = 0.0
    private let dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            // 轨道线（微妙的虚线效果）
            Circle()
                .stroke(
                    Color.white.opacity(0.05),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 10])
                )
                .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                .opacity(orbitOpacity)
                .animation(.easeInOut(duration: 1.0).delay(Double(orbitIndex) * 0.2), value: orbitOpacity)
            
            // 行星
            ForEach(Array(sessions.enumerated()), id: \.element.id) { sessionIndex, session in
                PlanetView(session: session, orbitRadius: orbitRadius, planThemeColor: orbitThemeColor)
                    .rotationEffect(.degrees(rotationAngle + initialOffset + getSessionOffset(for: sessionIndex)))
                    .opacity(orbitOpacity)
                    .animation(.easeInOut(duration: 0.8).delay(Double(sessionIndex) * 0.1), value: orbitOpacity)
            }
        }
        .onAppear {
            // 为每个轨道设置随机的初始偏移
            initialOffset = Double.random(in: 0...360)
            
            // 延迟显示，创建出现动画
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(orbitIndex) * 0.1) {
                orbitOpacity = 1.0
                startOrbiting()
            }
        }
    }
    
    // 获取当前轨道项目对应的计划主题颜色
    private var orbitThemeColor: String {
        guard let firstSession = sessions.first else { return "#00CE4A" }
        let plans = dataManager.loadPlans()
        if let plan = plans.first(where: { $0.project == firstSession.projectName }) {
            return plan.themeColor
        }
        return firstSession.themeColor
    }
    
    private func startOrbiting() {
        // 为每个轨道设置不同的公转周期（8-25秒，速度更快）
        let period = Double.random(in: 8...25)
        
        withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    // 计算同一轨道上不同session的初始位置偏移（紧凑排列）
    private func getSessionOffset(for index: Int) -> Double {
        // 计算每个小球的角度间隔，基于小球大小
        let planetSize: CGFloat = 15 // 平均小球大小
        let angularSpacing = Double((planetSize + 4) / orbitRadius * 180 / .pi) // 转换为角度，4是间隙
        return Double(index) * angularSpacing
    }
}

// MARK: - 行星视图
struct PlanetView: View {
    let session: FocusSession
    let orbitRadius: CGFloat
    let planThemeColor: String
    
    @State private var isGlowing = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // 外层光晕（模拟大气层）
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: planThemeColor).opacity(0.3),
                            Color(hex: planThemeColor).opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: planetSize/2,
                        endRadius: planetSize/2 + 6
                    )
                )
                .frame(width: planetSize + 12, height: planetSize + 12)
                .opacity(isGlowing ? 0.8 : 0.4)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isGlowing)
            
            // 行星主体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: planThemeColor).opacity(0.9),
                            Color(hex: planThemeColor),
                            Color(hex: planThemeColor).opacity(0.7)
                        ]),
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: planetSize/2
                    )
                )
                .frame(width: planetSize, height: planetSize)
                .overlay(
                    // 表面纹理
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                center: UnitPoint(x: 0.25, y: 0.25),
                                startRadius: 0,
                                endRadius: planetSize/3
                            )
                        )
                )
                .overlay(
                    // 添加微妙的纹理线条
                    Circle()
                        .stroke(
                            Color.white.opacity(0.1),
                            lineWidth: 0.5
                        )
                        .rotationEffect(.degrees(rotationAngle))
                )
                .shadow(
                    color: Color(hex: planThemeColor).opacity(0.4),
                    radius: planetSize/4,
                    x: 2,
                    y: 2
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        }
        .offset(x: orbitRadius, y: 0)
        .onAppear {
            isGlowing = true
            
            // 缓慢旋转
            withAnimation(.linear(duration: Double.random(in: 15...30)).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
    
    // 根据session持续时间计算行星大小
    private var planetSize: CGFloat {
        let minSize: CGFloat = 10
        let mediumSize: CGFloat = 20
        let maxSize: CGFloat = 30
        let duration = session.duration
        
        // 分段计算行星大小
        if duration <= 300 { // 5分钟以内，最小尺寸
            return minSize
        } else if duration <= 2700 { // 5-45分钟，匀速增长
            let progress = (duration - 300) / (2700 - 300) // 0-1之间
            return minSize + (mediumSize - minSize) * CGFloat(progress)
        } else { // 45分钟-3小时，增速下降
            let progress = (duration - 2700) / (6300 - 2700) // 0-1之间
            let normalizedProgress = min(progress, 1.0)
            // 使用平方根函数让增长速度下降
            let slowedProgress = sqrt(normalizedProgress)
            return mediumSize + (maxSize - mediumSize) * CGFloat(slowedProgress)
        }
    }
}

struct BigCircleStartButton: View {
    let onTap: () -> Void
    
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @State private var isPressed = false
    @State private var breathingScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.6
    
    private let buttonSize: CGFloat = 240  // 回到您喜欢的尺寸
    
    var body: some View {
        Button(action: {
            NSHapticFeedbackManager.performHapticFeedback()
            onTap()
        }) {
            ZStack {
                // 呼吸涟漪效果
                Circle()
                    .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 2)
                    .frame(width: buttonSize + 60, height: buttonSize + 60)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: rippleScale)
                
                // 淡淡的外层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.primaryGreen.opacity(0.0),
                                Color.primaryGreen.opacity(0.1),
                                Color.primaryGreen.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: buttonSize/2,
                            endRadius: buttonSize/2 + 40
                        )
                    )
                    .frame(width: buttonSize + 80, height: buttonSize + 80)
                    .scaleEffect(breathingScale)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingScale)
                
                // 微妙的旋转装饰环
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.primaryGreen.opacity(0.4), lineWidth: 1.5)
                    .frame(width: buttonSize + 20, height: buttonSize + 20)
                    .rotationEffect(.degrees(rotationAngle))
                
                // 主按钮
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.primaryGreen.opacity(0.9),
                                Color.primaryGreen,
                                Color.primaryGreen.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                
                // 内容区域
                VStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.white)
                        .offset(x: 3, y: 0)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                    
                    VStack(spacing: 6) {
                        Text("开始专注")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Focus Session")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        NSHapticFeedbackManager.performHapticFeedback()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .shadow(
            color: Color.primaryGreen.opacity(0.4),
            radius: isPressed ? 15 : 20,
            x: 0,
            y: isPressed ? 8 : 12
        )
        .onAppear {
            // 呼吸效果
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.05
            }
            
            // 装饰环旋转
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // 涟漪效果
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                rippleScale = 1.1
                rippleOpacity = 0.2
            }
        }
    }
}

// MARK: - 星空背景效果
struct StarFieldBackground: View {
    @State private var starOpacities: [Double] = []
    @State private var starScales: [CGFloat] = []
    @State private var timer: Timer?
    
    private let starCount = 30 // 减少星星数量
    private let starPositions: [CGPoint] = {
        (0..<30).map { _ in
            CGPoint(
                x: CGFloat.random(in: 0...800),
                y: CGFloat.random(in: 0...600)
            )
        }
    }()
    
    var body: some View {
        ZStack {
            ForEach(0..<starCount, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 2, height: 2)
                    .position(starPositions[index])
                    .opacity(starOpacities.count > index ? starOpacities[index] : 0.5)
                    .scaleEffect(starScales.count > index ? starScales[index] : 1.0)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 0)
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...8))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...5)),
                        value: starOpacities.count > index ? starOpacities[index] : 0.5
                    )
            }
        }
        .onAppear {
            setupStars()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func setupStars() {
        starOpacities = (0..<starCount).map { _ in Double.random(in: 0.3...0.9) }
        starScales = (0..<starCount).map { _ in CGFloat.random(in: 0.5...1.5) }
        
        // 使用更优化的Timer
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: Double.random(in: 2...5))) {
                for i in 0..<starCount {
                    if Double.random(in: 0...1) < 0.3 { // 只有30%概率更新
                        starOpacities[i] = Double.random(in: 0.3...0.9)
                        starScales[i] = CGFloat.random(in: 0.5...1.5)
                    }
                }
            }
        }
    }
}

// 扩展触觉反馈
extension NSHapticFeedbackManager {
    static func performHapticFeedback() {
        let impactFeedback = NSHapticFeedbackManager.defaultPerformer
        impactFeedback.perform(.alignment, performanceTime: .now)
    }
}

#Preview {
    IdleSessionView(onStartSession: {})
        .environmentObject(SessionViewModel())
}

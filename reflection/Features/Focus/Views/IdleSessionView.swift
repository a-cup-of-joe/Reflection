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
        .background(Color.appBackground)
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
    private let dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { sessionIndex, session in
                PlanetView(session: session, orbitRadius: orbitRadius, planThemeColor: orbitThemeColor)
                    .rotationEffect(.degrees(rotationAngle + initialOffset + getSessionOffset(for: sessionIndex)))
            }
        }
        .onAppear {
            // 为每个轨道设置随机的初始偏移
            initialOffset = Double.random(in: 0...360)
            startOrbiting()
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
    
    var body: some View {
        Circle()
            .fill(Color(hex: planThemeColor))
            .frame(width: planetSize, height: planetSize)
            .shadow(color: Color(hex: planThemeColor).opacity(0.6), radius: 4, x: 0, y: 2)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: planetSize/2
                        )
                    )
            )
            .offset(x: orbitRadius, y: 0)
    }
    
    // 根据session持续时间计算行星大小
    private var planetSize: CGFloat {
        let minSize: CGFloat = 4
        let mediumSize: CGFloat = 16
        let maxSize: CGFloat = 24
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
    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0
    @State private var innerGlowOpacity = 0.3
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity = 0.0
    
    private let buttonSize: CGFloat = 240  // 增大按钮尺寸
    
    var body: some View {
        ZStack {
            
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

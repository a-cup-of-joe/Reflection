//
//  IdleSessionView.swift
//  reflection
//
//  Created by linan on 2025/7/13.
//

import SwiftUI

// MARK: - 行星吸入动画系统
struct PlanetAbsorptionSystem {
    struct AbsorbedPlanet: Identifiable {
        let id = UUID()
        let session: FocusSession
        let originalPosition: CGPoint
        let originalOrbitRadius: CGFloat
        let originalAngle: Double
        let planThemeColor: String
        var currentPosition: CGPoint
        var currentScale: CGFloat = 1.0
        var currentOpacity: Double = 1.0
        var isAbsorbed: Bool = false
    }
    
    static func getAllPlanetsFromSystem(
        groupedSessions: [(projectName: String, sessions: [FocusSession])],
        getOrbitRadius: (Int) -> CGFloat,
        getOrbitThemeColor: (FocusSession?) -> String,
        getAngularSpacing: (CGFloat) -> Double,
        getCurrentOrbitRotation: (Int) -> Double
    ) -> [AbsorbedPlanet] {
        var planets: [AbsorbedPlanet] = []
        
        for (orbitIndex, group) in groupedSessions.enumerated() {
            let orbitRadius = getOrbitRadius(orbitIndex)
            let planThemeColor = getOrbitThemeColor(group.sessions.first)
            let currentRotation = getCurrentOrbitRotation(orbitIndex)
            
            for (sessionIndex, session) in group.sessions.enumerated() {
                let sessionOffset = Double(sessionIndex) * getAngularSpacing(orbitRadius)
                let totalAngle = currentRotation + sessionOffset
                
                // 计算当前实际位置（考虑轨道旋转）
                let currentPosition = CGPoint(
                    x: cos(totalAngle * .pi / 180) * orbitRadius,
                    y: sin(totalAngle * .pi / 180) * orbitRadius
                )
                
                // 原始位置（不考虑旋转）
                let originalPosition = CGPoint(
                    x: cos(sessionOffset * .pi / 180) * orbitRadius,
                    y: sin(sessionOffset * .pi / 180) * orbitRadius
                )
                
                let planet = AbsorbedPlanet(
                    session: session,
                    originalPosition: originalPosition,
                    originalOrbitRadius: orbitRadius,
                    originalAngle: sessionOffset,
                    planThemeColor: planThemeColor,
                    currentPosition: currentPosition
                )
                planets.append(planet)
            }
        }
        
        return planets
    }
}

// MARK: - 数据结构
struct RippleWave: Identifiable {
    let id = UUID()
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var rotation: Double = 0.0
    var irregularFactor: CGFloat = 1.0
}

struct IrregularPulse: Identifiable {
    let id = UUID()
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var angle: Double = 0.0
    var speed: Double = 1.0
}

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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.gray.opacity(0.05),
                    Color.white.opacity(0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
    
    // 行星吸入状态
    @State private var isAbsorbing: Bool = false
    @State private var absorbedPlanets: [PlanetAbsorptionSystem.AbsorbedPlanet] = []
    @State private var absorptionProgress: CGFloat = 0.0
    
    // 存储每个轨道的当前旋转角度
    @State private var orbitRotations: [Int: Double] = [:]
    
    // 存储吸入动画开始时的轨道旋转状态（固定不变）
    @State private var frozenOrbitRotations: [Int: Double] = [:]
    
    var body: some View {
        ZStack {
            if !isAbsorbing {
                // 正常状态下的行星轨道
                ForEach(Array(groupedSessions.enumerated()), id: \.offset) { orbitIndex, group in
                    OrbitView(
                        sessions: group.sessions,
                        orbitRadius: getOrbitRadius(for: orbitIndex),
                        orbitIndex: orbitIndex,
                        onRotationUpdate: { angle in
                            updateOrbitRotation(for: orbitIndex, angle: angle)
                        }
                    )
                }
            } else {
                // 吸入状态下的行星动画
                ForEach(absorbedPlanets) { planet in
                    AbsorbedPlanetView(planet: planet)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("StartPlanetAbsorption"))) { _ in
            startPlanetAbsorption()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("EndPlanetAbsorption"))) { _ in
            endPlanetAbsorption()
        }
    }
    
    // 获取当前的TimePlan项目名称
    private var currentPlanProjects: Set<String> {
        guard let currentPlanId = dataManager.loadCurrentPlanId(),
              let currentPlan = dataManager.loadPlans().first(where: { $0.id == currentPlanId }) else {
            return Set()
        }
        return Set(currentPlan.planItems.map { $0.project })
    }
    
    // 按项目名称分组sessions（过滤掉少于10秒的session，且仅显示与当前TimePlan相关的当日sessions）
    private var groupedSessions: [(projectName: String, sessions: [FocusSession])] {
        let calendar = Calendar.current
        let today = Date()
        
        let filteredSessions = sessionViewModel.sessions.filter { session in
            let isToday = calendar.isDate(session.startTime, inSameDayAs: today)
            return session.duration >= 10 && 
                   currentPlanProjects.contains(session.projectName) && 
                   isToday
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
    
    // 获取当前轨道的主题颜色
    func getOrbitThemeColor(for session: FocusSession?) -> String {
        guard let session = session,
              let currentPlanId = dataManager.loadCurrentPlanId(),
              let currentPlan = dataManager.loadPlans().first(where: { $0.id == currentPlanId }),
              let planItem = currentPlan.planItems.first(where: { $0.project == session.projectName }) else {
            return session?.themeColor ?? "#00CE4A"
        }
        return planItem.themeColor
    }
    
    // 计算角度间隔
    func getAngularSpacing(for orbitRadius: CGFloat) -> Double {
        let planetSize: CGFloat = 15
        return Double((planetSize + 4) / orbitRadius * 180 / .pi)
    }
    
    // 获取当前轨道旋转角度
    func getCurrentOrbitRotation(for orbitIndex: Int) -> Double {
        return orbitRotations[orbitIndex] ?? 0.0
    }
    
    // 更新轨道旋转角度
    func updateOrbitRotation(for orbitIndex: Int, angle: Double) {
        orbitRotations[orbitIndex] = angle
    }
    
    // 根据行星找到对应的轨道索引
    private func getOrbitIndexForPlanet(_ planet: PlanetAbsorptionSystem.AbsorbedPlanet) -> Int {
        // 通过项目名称找到轨道索引
        for (index, group) in groupedSessions.enumerated() {
            if group.sessions.contains(where: { $0.id == planet.session.id }) {
                return index
            }
        }
        return 0 // 默认返回第一个轨道
    }
    
    // 开始行星吸入动画
    private func startPlanetAbsorption() {
        isAbsorbing = true
        
        // 保存当前的轨道旋转状态，在整个动画过程中使用固定的旋转状态
        frozenOrbitRotations = orbitRotations
        
        // 收集所有行星
        absorbedPlanets = PlanetAbsorptionSystem.getAllPlanetsFromSystem(
            groupedSessions: groupedSessions,
            getOrbitRadius: getOrbitRadius,
            getOrbitThemeColor: getOrbitThemeColor,
            getAngularSpacing: getAngularSpacing,
            getCurrentOrbitRotation: { orbitIndex in
                return frozenOrbitRotations[orbitIndex] ?? 0.0
            }
        )
        
        // 开始吸入动画
        withAnimation(.easeInOut(duration: 0.8)) {
            absorptionProgress = 1.0
            
            for i in 0..<absorbedPlanets.count {
                // 使用当前真实位置（考虑轨道旋转）作为吸入起点
                let currentPos = absorbedPlanets[i].currentPosition
                let planet = absorbedPlanets[i]
                
                // 计算当前真实角度（使用固定的轨道旋转）
                let frozenRotation = frozenOrbitRotations[getOrbitIndexForPlanet(planet)] ?? 0.0
                let currentAngle = frozenRotation + planet.originalAngle
                
                // 创建螺旋吸入轨迹
                let spiralProgress = CGFloat(i) / CGFloat(absorbedPlanets.count) * 0.3
                let spiralRadius = sqrt(currentPos.x * currentPos.x + currentPos.y * currentPos.y) * (1.0 - absorptionProgress + spiralProgress)
                let spiralAngle = currentAngle + Double(absorptionProgress * 720) // 转两圈
                
                absorbedPlanets[i].currentPosition = CGPoint(
                    x: cos(spiralAngle * .pi / 180) * spiralRadius * 0.2,
                    y: sin(spiralAngle * .pi / 180) * spiralRadius * 0.2
                )
                absorbedPlanets[i].currentScale = 0.3 + 0.7 * (1.0 - absorptionProgress)
                absorbedPlanets[i].currentOpacity = 0.4 + 0.6 * (1.0 - absorptionProgress)
                absorbedPlanets[i].isAbsorbed = true
            }
        }
    }
    
    // 结束行星吸入动画
    private func endPlanetAbsorption() {
        // 行星爆发弹出动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            absorptionProgress = 0.0
            
            for i in 0..<absorbedPlanets.count {
                // 使用固定的轨道旋转状态计算位置
                let planet = absorbedPlanets[i]
                let frozenRotation = frozenOrbitRotations[getOrbitIndexForPlanet(planet)] ?? 0.0
                let totalAngle = frozenRotation + planet.originalAngle
                let currentRealPosition = CGPoint(
                    x: cos(totalAngle * .pi / 180) * planet.originalOrbitRadius,
                    y: sin(totalAngle * .pi / 180) * planet.originalOrbitRadius
                )
                
                // 先弹出到比当前真实位置稍远的地方（沿着相同方向）
                let overshootFactor: CGFloat = 1.2
                absorbedPlanets[i].currentPosition = CGPoint(
                    x: currentRealPosition.x * overshootFactor,
                    y: currentRealPosition.y * overshootFactor
                )
                absorbedPlanets[i].currentScale = 1.3
                absorbedPlanets[i].currentOpacity = 1.0
            }
        }
        
        // 延迟回到正常状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                for i in 0..<absorbedPlanets.count {
                    // 使用固定的轨道旋转状态回到精确位置
                    let planet = absorbedPlanets[i]
                    let frozenRotation = frozenOrbitRotations[getOrbitIndexForPlanet(planet)] ?? 0.0
                    let totalAngle = frozenRotation + planet.originalAngle
                    let currentRealPosition = CGPoint(
                        x: cos(totalAngle * .pi / 180) * planet.originalOrbitRadius,
                        y: sin(totalAngle * .pi / 180) * planet.originalOrbitRadius
                    )
                    
                    absorbedPlanets[i].currentPosition = currentRealPosition
                    absorbedPlanets[i].currentScale = 1.0
                    absorbedPlanets[i].currentOpacity = 1.0
                }
            }
        }
        
        // 最后回到正常轨道显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 在切换回正常状态前，确保轨道旋转状态与弹出动画结束时的状态同步
            // 将冻结的轨道旋转状态重新设置为当前的轨道旋转状态
            for (orbitIndex, frozenRotation) in frozenOrbitRotations {
                orbitRotations[orbitIndex] = frozenRotation
            }
            
            // 带动画切换回正常状态，使过渡更自然
            withAnimation(.easeInOut(duration: 0.3)) {
                isAbsorbing = false
                absorbedPlanets.removeAll()
            }
            
            // 动画完成后清理固定的旋转状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                frozenOrbitRotations.removeAll()
            }
        }
    }
}

// MARK: - 单个轨道视图
struct OrbitView: View {
    let sessions: [FocusSession]
    let orbitRadius: CGFloat
    let orbitIndex: Int
    let onRotationUpdate: (Double) -> Void
    
    @State private var rotationAngle: Double = 0
    @State private var initialOffset: Double = 0
    @State private var orbitOpacity: Double = 0.0
    private let dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
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
        .onChange(of: rotationAngle) {
            // 报告当前总旋转角度
            let totalRotation = rotationAngle + initialOffset
            onRotationUpdate(totalRotation)
        }
    }
    
    // 获取当前轨道项目对应的计划主题颜色
    private var orbitThemeColor: String {
        guard let firstSession = sessions.first,
              let currentPlanId = dataManager.loadCurrentPlanId(),
              let currentPlan = dataManager.loadPlans().first(where: { $0.id == currentPlanId }),
              let planItem = currentPlan.planItems.first(where: { $0.project == firstSession.projectName }) else {
            return sessions.first?.themeColor ?? "#00CE4A"
        }
        return planItem.themeColor
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
                            Color.black.opacity(0.05),
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

// MARK: - 被吸入的行星视图
struct AbsorbedPlanetView: View {
    let planet: PlanetAbsorptionSystem.AbsorbedPlanet
    
    @State private var isGlowing = false
    @State private var rotationAngle: Double = 0
    @State private var trailOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // 行星轨迹尾迹
            if planet.isAbsorbed {
                planetTrail
            }
            
            // 外层光晕（增强的大气层效果）
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: planet.planThemeColor).opacity(0.4),
                            Color(hex: planet.planThemeColor).opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: planetSize/2,
                        endRadius: planetSize/2 + CGFloat(8)
                    )
                )
                .frame(width: planetSize + CGFloat(16), height: planetSize + CGFloat(16))
                .scaleEffect(planet.currentScale * 1.2)
                .opacity(planet.currentOpacity * (isGlowing ? 1.0 : 0.6))
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
            
            // 行星主体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: planet.planThemeColor).opacity(0.95),
                            Color(hex: planet.planThemeColor),
                            Color(hex: planet.planThemeColor).opacity(0.8)
                        ]),
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: planetSize/2
                    )
                )
                .frame(width: planetSize, height: planetSize)
                .scaleEffect(planet.currentScale)
                .opacity(planet.currentOpacity)
                .overlay(
                    // 表面纹理
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                center: UnitPoint(x: 0.25, y: 0.25),
                                startRadius: 0,
                                endRadius: planetSize/3
                            )
                        )
                        .scaleEffect(planet.currentScale)
                )
                .shadow(
                    color: Color(hex: planet.planThemeColor).opacity(0.6),
                    radius: planetSize/3 * planet.currentScale,
                    x: 2,
                    y: 2
                )
                .rotationEffect(.degrees(rotationAngle))
        }
        .offset(x: planet.currentPosition.x, y: planet.currentPosition.y)
        .onAppear {
            isGlowing = true
            
            // 快速旋转效果
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
    
    // 行星轨迹尾迹
    private var planetTrail: some View {
        ZStack {
            // 主尾迹
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(hex: planet.planThemeColor).opacity(0.3),
                                Color(hex: planet.planThemeColor).opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 6
                        )
                    )
                    .frame(width: 12, height: 12)
                    .scaleEffect(0.5 + 0.3 * CGFloat(index))
                    .opacity(trailOpacity * (0.8 - 0.2 * Double(index)))
                    .offset(
                        x: -planet.currentPosition.x * 0.1 * CGFloat(index + 1),
                        y: -planet.currentPosition.y * 0.1 * CGFloat(index + 1)
                    )
            }
        }
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: trailOpacity)
    }
    
    // 根据session持续时间计算行星大小
    private var planetSize: CGFloat {
        let minSize: CGFloat = 10
        let mediumSize: CGFloat = 20
        let maxSize: CGFloat = 30
        let duration = planet.session.duration
        
        if duration <= 300 {
            return minSize
        } else if duration <= 2700 {
            let progress = (duration - 300) / (2700 - 300)
            return minSize + (mediumSize - minSize) * CGFloat(progress)
        } else {
            let progress = (duration - 2700) / (6300 - 2700)
            let normalizedProgress = min(progress, 1.0)
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
    
    // 简化的动画状态
    @State private var pulseScale: CGFloat = 1.0
    @State private var orbitRotation: Double = 0
    
    // 脉冲效果状态
    @State private var pulseWave1: CGFloat = 0
    @State private var pulseWave2: CGFloat = 0
    @State private var pulseOpacity: Double = 0
    
    // Timer管理
    @State private var heartbeatTimer: Timer?
    
    // 粒子特效状态
    @State private var particlePositions: [CGPoint] = []
    @State private var particleOpacities: [Double] = []
    @State private var particleScales: [CGFloat] = []
    
    // Timer管理
    @State private var particleTimer: Timer?
    
    // 中心能量聚集状态
    @State private var coreEnergyScale: CGFloat = 1.0
    @State private var coreEnergyOpacity: Double = 0.3
    
    // 点击反馈效果状态
    @State private var clickEnergyGathering: Bool = false
    @State private var clickPulseRipples: [CGFloat] = []
    @State private var clickHaloAbsorption: Bool = false
    @State private var mechanicalResistance: CGFloat = 1.0
    @State private var energyBurst: Bool = false
    
    // 高级反馈效果状态
    @State private var energyGatheringScale: CGFloat = 1.0
    @State private var energyGatheringOpacity: Double = 0.3
    @State private var rippleWaves: [RippleWave] = []
    @State private var haloAbsorptionScale: CGFloat = 1.0
    @State private var haloAbsorptionOpacity: Double = 0.6
    @State private var mechanicalPressure: CGFloat = 0.0
    @State private var energyBurstScale: CGFloat = 0.0
    @State private var energyBurstOpacity: Double = 0.0
    @State private var irregularPulses: [IrregularPulse] = []
    
    private let buttonSize: CGFloat = 240
    
    var body: some View {
        Button(action: {
            performHapticFeedback()
            onTap()
        }) {
            ZStack {
                // 基础装饰层
                baseDecorations
                
                // 点击反馈效果层
                clickFeedbackEffects
                
                // 主按钮层
                mainButtonLayer
                
                // 内容层
                contentLayer
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        startClickFeedback()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        endClickFeedback()
                    }
                }
        )
        .shadow(
            color: Color.primaryGreen.opacity(0.4),
            radius: isPressed ? 15 : 20,
            x: 0,
            y: isPressed ? 8 : 12
        )
        .onAppear {
            setupAnimations()
        }
        .onDisappear {
            // 清理Timer避免内存泄漏
            heartbeatTimer?.invalidate()
            particleTimer?.invalidate()
        }
    }
    

    // 基础装饰
    private var baseDecorations: some View {
        ZStack {
            // 呼吸涟漪效果
            breathingRipple
            
            // 能量脉冲环
            energyPulseRing
            
            // 轨道元素
            orbitElements
            
            // 外层光晕
            outerHalo
        }
    }
    
    // 呼吸涟漪
    private var breathingRipple: some View {
        Circle()
            .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 2)
            .frame(width: buttonSize + 60, height: buttonSize + 60)
            .scaleEffect(rippleScale)
            .opacity(rippleOpacity)
    }
    
    // 能量脉冲环
    private var energyPulseRing: some View {
        Circle()
            .stroke(Color.primaryGreen.opacity(0.4), lineWidth: 2)
            .frame(width: buttonSize + 40, height: buttonSize + 40)
            .scaleEffect(pulseScale)
            .opacity(0.6)
    }
    
    // 轨道元素
    private var orbitElements: some View {
        ForEach(0..<4, id: \.self) { index in
            Circle()
                .fill(Color.primaryGreen.opacity(0.6))
                .frame(width: 3, height: 3)
                .offset(x: buttonSize/2 + 25, y: 0)
                .rotationEffect(.degrees(orbitRotation + Double(index * 90)))
                .opacity(0.7)
        }
    }
    
    // 外层光晕
    private var outerHalo: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.primaryGreen.opacity(0.0),
                        Color.primaryGreen.opacity(0.1),
                        Color.primaryGreen.opacity(clickHaloAbsorption ? 0.3 : 0.2),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: buttonSize/2,
                    endRadius: buttonSize/2 + 40
                )
            )
            .frame(width: buttonSize + 80, height: buttonSize + 80)
            .scaleEffect(clickHaloAbsorption ? haloAbsorptionScale : breathingScale)
            .opacity(clickHaloAbsorption ? haloAbsorptionOpacity : 1.0)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingScale)
    }
    
    // 点击反馈效果
    private var clickFeedbackEffects: some View {
        ZStack {
            // 点击涟漪波效果
            rippleWaveEffects
            
            // 不规则脉冲效果
            irregularPulseEffects
            
            // 能量爆发效果
            energyBurstEffect
        }
    }
    
    // 涟漪波效果组件
    private var rippleWaveEffects: some View {
        ForEach(rippleWaves) { wave in
            rippleWaveView(wave: wave)
        }
    }
    
    // 单个涟漪波视图
    private func rippleWaveView(wave: RippleWave) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primaryGreen.opacity(0.8),
                        Color.primaryGreen.opacity(0.4),
                        Color.primaryGreen.opacity(0.2),
                        Color.clear
                    ]),
                    startPoint: .center,
                    endPoint: .trailing
                ),
                lineWidth: 3
            )
            .frame(width: buttonSize + 20, height: buttonSize + 20)
            .scaleEffect(wave.scale * wave.irregularFactor)
            .opacity(wave.opacity)
            .rotationEffect(.degrees(wave.rotation))
    }
    
    // 不规则脉冲效果组件
    private var irregularPulseEffects: some View {
        ForEach(irregularPulses) { pulse in
            irregularPulseView(pulse: pulse)
        }
    }
    
    // 单个不规则脉冲视图
    private func irregularPulseView(pulse: IrregularPulse) -> some View {
        let centerX: CGFloat = buttonSize / 2.0
        let centerY: CGFloat = buttonSize / 2.0
        let radius: CGFloat = buttonSize / 2.0 + 30.0
        let angleInRadians: Double = pulse.angle * .pi / 180.0
        let xPos: CGFloat = centerX + CGFloat(cos(angleInRadians)) * radius
        let yPos: CGFloat = centerY + CGFloat(sin(angleInRadians)) * radius
        
        return Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.primaryGreen.opacity(0.6),
                        Color.primaryGreen.opacity(0.3),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: CGFloat(0),
                    endRadius: CGFloat(15)
                )
            )
            .frame(width: 30, height: 30)
            .scaleEffect(pulse.scale)
            .opacity(pulse.opacity)
            .position(x: xPos, y: yPos)
    }
    
    // 能量爆发效果组件
    private var energyBurstEffect: some View {
        Group {
            if energyBurstScale > 0 {
                energyBurstCircle
            }
        }
    }
    
    // 能量爆发圆形
    private var energyBurstCircle: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.8),
                        Color.primaryGreen.opacity(0.6),
                        Color.primaryGreen.opacity(0.3),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: buttonSize/2 + 40
                )
            )
            .frame(width: buttonSize + 80, height: buttonSize + 80)
            .scaleEffect(energyBurstScale)
            .opacity(energyBurstOpacity)
    }
    
    // 分离主按钮层
    private var mainButtonLayer: some View {
        ZStack {
            // 基础按钮
            mainButton
            
            // 脉冲波纹效果
            pulseWaveEffect
        }
    }
    
    // 主按钮
    private var mainButton: some View {
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
            .scaleEffect(mechanicalResistance)
            .scaleEffect(clickEnergyGathering ? energyGatheringScale : 1.0)
            .scaleEffect(breathingScale)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathingScale)
    }
    
    // 分离内容层
    private var contentLayer: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.fill")
                .font(.system(size: 42, weight: .medium))
                .foregroundColor(.white)
                .offset(x: 3, y: 0)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .scaleEffect(mechanicalResistance)
            
            VStack(spacing: 6) {
                Text("开始专注")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Focus Session")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(mechanicalResistance)
        }
    }
    // 脉冲波纹效果
    private var pulseWaveEffect: some View {
        ZStack {
            // 中心能量聚集
            coreEnergyView
            
            // 心电图式脉冲波
            heartbeatWaves
            
            // 随机粒子特效
            particleEffects
            
            // 能量流线条
            energyLines
        }
        .frame(width: buttonSize, height: buttonSize)
        .clipped()
    }
    
    // 中心能量
    private var coreEnergyView: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(clickEnergyGathering ? 0.8 : 0.4),
                        Color.white.opacity(clickEnergyGathering ? 0.6 : 0.2),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: buttonSize * 0.15
                )
            )
            .frame(width: buttonSize * 0.3, height: buttonSize * 0.3)
            .scaleEffect(clickEnergyGathering ? energyGatheringScale * coreEnergyScale : coreEnergyScale)
            .opacity(clickEnergyGathering ? energyGatheringOpacity : coreEnergyOpacity)
    }
    
    // 心电图波
    private var heartbeatWaves: some View {
        ZStack {
            // 第一层波
            firstHeartbeatWave
            
            // 第二层波
            secondHeartbeatWave
        }
    }
    
    // 第一层心电图波
    private var firstHeartbeatWave: some View {
        Circle()
            .trim(from: 0, to: 0.6)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.8),
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.2),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: buttonSize * 0.75, height: buttonSize * 0.75)
            .rotationEffect(.degrees(pulseWave1 * 360))
            .opacity(pulseOpacity)
    }
    
    // 第二层心电图波
    private var secondHeartbeatWave: some View {
        Circle()
            .trim(from: 0.3, to: 0.9)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.5),
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: buttonSize * 0.55, height: buttonSize * 0.55)
            .rotationEffect(.degrees(pulseWave2 * -360))
            .opacity(pulseOpacity * 0.8)
    }
    
    // 粒子效果
    private var particleEffects: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                particleView(at: index)
            }
        }
    }
    
    // 单个粒子视图
    private func particleView(at index: Int) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 2
                )
            )
            .frame(width: 4, height: 4)
            .position(
                particlePositions.count > index ? particlePositions[index] : CGPoint(x: buttonSize/2, y: buttonSize/2)
            )
            .opacity(particleOpacities.count > index ? particleOpacities[index] : 0)
            .scaleEffect(particleScales.count > index ? particleScales[index] : 1.0)
    }
    
    // 能量线条
    private var energyLines: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                energyLine(at: index)
            }
        }
    }
    
    // 单个能量线条
    private func energyLine(at index: Int) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: buttonSize * 0.35, height: 1.5)
            .offset(x: -buttonSize * 0.175, y: 0)
            .rotationEffect(.degrees(Double(index * 60) + pulseWave1 * 180))
            .opacity(pulseOpacity * 0.7)
    }
    
    private func setupAnimations() {
        // 呼吸效果 - 更明显的缩放范围
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathingScale = 1.08
        }
        
        // // 装饰环旋转
        // withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
        //     rotationAngle = 360
        // }
        
        // 涟漪效果
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            rippleScale = 1.1
            rippleOpacity = 0.2
        }
        
        // 脉冲效果
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        
        // 轨道旋转
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
        
        // 心电图脉冲效果
        startHeartbeatPulse()
        
        // 粒子特效
        startParticleEffect()
        
        // 中心能量聚集
        startCoreEnergyEffect()
    }
    
    private func startHeartbeatPulse() {
        // 清理之前的Timer
        heartbeatTimer?.invalidate()
        
        // 心电图式脉冲 - 更快更明显
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseWave1 = 1.0
        }
        
        // 第二层波纹 - 延迟启动
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false).delay(0.2)) {
            pulseWave2 = 1.0
        }
        
        // 心电图节奏 - 模拟真实心跳
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // 只在非按压状态下执行心跳动画
            guard !isPressed else { return }
            
            // 主脉冲
            withAnimation(.easeOut(duration: 0.3)) {
                pulseOpacity = 1.0
            }
            
            // 快速衰减
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard !isPressed else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    pulseOpacity = 0.2
                }
            }
            
            // 小回波
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard !isPressed else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    pulseOpacity = 0.6
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard !isPressed else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pulseOpacity = 0.1
                    }
                }
            }
        }
    }
    
    private func startParticleEffect() {
        // 清理之前的Timer
        particleTimer?.invalidate()
        
        // 初始化粒子位置
        particlePositions = (0..<8).map { _ in
            CGPoint(
                x: buttonSize/2 + CGFloat.random(in: -50...50),
                y: buttonSize/2 + CGFloat.random(in: -50...50)
            )
        }
        particleOpacities = (0..<8).map { _ in Double.random(in: 0.3...0.8) }
        particleScales = (0..<8).map { _ in CGFloat.random(in: 0.5...1.2) }
        
        // 粒子动画
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            // 只在非按压状态下执行粒子动画
            guard !isPressed else { return }
            
            withAnimation(.easeInOut(duration: 1.5)) {
                for i in 0..<particlePositions.count {
                    let angle = Double.random(in: 0...2 * .pi)
                    let radius = Double.random(in: 20...60)
                    particlePositions[i] = CGPoint(
                        x: buttonSize/2 + CGFloat(cos(angle) * radius),
                        y: buttonSize/2 + CGFloat(sin(angle) * radius)
                    )
                    particleOpacities[i] = Double.random(in: 0.2...0.8)
                    particleScales[i] = CGFloat.random(in: 0.3...1.5)
                }
            }
        }
    }
    
    private func startCoreEnergyEffect() {
        // 中心能量脉动
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            coreEnergyScale = 1.3
        }
        
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) {
            coreEnergyOpacity = 0.7
        }
    }
    
    private func startPressedPulseAnimation() {
        // 按压状态下的持续脉冲动画
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.6
        }
        
        // 增强脉冲波的旋转
        withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
            pulseWave1 += 0.3
            pulseWave2 += 0.2
        }
    }
    
    private func stopPressedPulseAnimation() {
        // 重新启动正常的心跳动画
        startHeartbeatPulse()
        startParticleEffect()
    }
    
    private func startClickFeedback() {
        // 触发行星吸入动画
        NotificationCenter.default.post(name: .init("StartPlanetAbsorption"), object: nil)
        
        // 暂停心跳动画，进入按压状态
        heartbeatTimer?.invalidate()
        particleTimer?.invalidate()
        
        // 1. 能量聚集效果 - 按钮和核心收缩变亮
        withAnimation(.easeOut(duration: 0.2)) {
            energyGatheringScale = 0.88
            energyGatheringOpacity = 0.9
            coreEnergyScale = 0.6
            coreEnergyOpacity = 1.0
        }
        
        // 2. 光晕吸收效果 - 外层光晕向内收缩并增强
        withAnimation(.easeInOut(duration: 0.25)) {
            haloAbsorptionScale = 0.8
            haloAbsorptionOpacity = 1.0
        }
        
        // 3. 机械阻力效果 - 模拟按钮被按下的阻力
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            mechanicalResistance = 0.95
        }
        
        // 4. 粒子吸入效果 - 粒子向中心聚集
        withAnimation(.easeOut(duration: 0.4)) {
            let centerX = buttonSize / 2
            let centerY = buttonSize / 2
            
            for i in 0..<particlePositions.count {
                let currentPos = particlePositions[i]
                let directionX = (centerX - currentPos.x) * 0.7
                let directionY = (centerY - currentPos.y) * 0.7
                particlePositions[i] = CGPoint(
                    x: currentPos.x + directionX,
                    y: currentPos.y + directionY
                )
                particleOpacities[i] = min(particleOpacities[i] * 1.5, 1.0)
                particleScales[i] = particleScales[i] * 1.2
            }
        }
        
        // 5. 设置按压状态下的持续脉冲效果
        withAnimation(.easeInOut(duration: 0.2)) {
            pulseOpacity = 0.9
        }
        
        // 6. 启动按压状态下的持续脉冲动画
        startPressedPulseAnimation()
        
        clickEnergyGathering = true
        clickHaloAbsorption = true
    }
    
    private func endClickFeedback() {
        // 触发行星弹出动画
        NotificationCenter.default.post(name: .init("EndPlanetAbsorption"), object: nil)
        
        // 1. 能量释放 - 按钮恢复并产生爆发效果
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            energyGatheringScale = 1.05
            energyGatheringOpacity = 0.2
            coreEnergyScale = 1.2
            coreEnergyOpacity = 0.2
            mechanicalResistance = 1.0
        }
        
        // 2. 光晕恢复并产生扩散
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            haloAbsorptionScale = 1.1
            haloAbsorptionOpacity = 0.4
        }
        
        // 3. 粒子爆发散开
        withAnimation(.easeOut(duration: 0.6)) {
            for i in 0..<particlePositions.count {
                let angle = Double.random(in: 0...2 * .pi)
                let radius = Double.random(in: 60...100)
                particlePositions[i] = CGPoint(
                    x: buttonSize/2 + CGFloat(cos(angle) * radius),
                    y: buttonSize/2 + CGFloat(sin(angle) * radius)
                )
                particleOpacities[i] = particleOpacities[i] * 0.7
                particleScales[i] = particleScales[i] * 1.3
            }
        }
        
        // 4. 能量爆发效果
        triggerEnergyBurst()
        
        // 5. 不规则脉冲涟漪
        triggerIrregularRipples()
        
        // 6. 恢复正常状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                energyGatheringScale = 1.0
                coreEnergyScale = 1.0
                haloAbsorptionScale = 1.0
                pulseOpacity = 0.6
            }
            
            // 重新启动正常的心跳和粒子动画
            stopPressedPulseAnimation()
        }
        
        clickEnergyGathering = false
        clickHaloAbsorption = false
    }
    
    private func triggerEnergyBurst() {
        // 1. 瞬间能量爆发 - 更强烈的效果
        withAnimation(.easeOut(duration: 0.1)) {
            energyBurstScale = 1.5
            energyBurstOpacity = 1.0
        }
        
        // 2. 第一阶段衰减
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                energyBurstScale = 0.8
                energyBurstOpacity = 0.6
            }
        }
        
        // 3. 最终消散
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.5)) {
                energyBurstScale = 0.0
                energyBurstOpacity = 0.0
            }
        }
        
        // 4. 同时触发额外的视觉效果
        withAnimation(.easeOut(duration: 0.2)) {
            pulseOpacity = 1.0
        }
        
        // 5. 强化心电图脉冲
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                pulseWave1 += 0.5
                pulseWave2 += 0.3
            }
        }
    }
    
    private func triggerIrregularRipples() {
        // 清除现有涟漪
        rippleWaves.removeAll()
        irregularPulses.removeAll()
        
        // 创建更多不规则涟漪 (4-7个)
        for i in 0..<Int.random(in: 4...7) {
            let wave = RippleWave(
                scale: CGFloat.random(in: 0.6...0.9),
                opacity: Double.random(in: 0.7...1.0),
                rotation: Double.random(in: 0...360),
                irregularFactor: CGFloat.random(in: 0.7...1.4)
            )
            rippleWaves.append(wave)
            
            // 延迟启动每个涟漪
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                animateRipple(wave)
            }
        }
        
        // 创建更多不规则脉冲 (10-12个)
        for i in 0..<Int.random(in: 10...12) {
            let pulse = IrregularPulse(
                scale: CGFloat.random(in: 0.3...0.7),
                opacity: Double.random(in: 0.6...0.9),
                angle: Double(i * 30) + Double.random(in: -45...45),
                speed: Double.random(in: 0.6...1.8)
            )
            irregularPulses.append(pulse)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                animateIrregularPulse(pulse)
            }
        }
    }
    
    private func animateRipple(_ wave: RippleWave) {
        if let index = rippleWaves.firstIndex(where: { $0.id == wave.id }) {
            // 更复杂的涟漪动画
            withAnimation(.easeOut(duration: 1.5)) {
                rippleWaves[index].scale = CGFloat.random(in: 2.8...3.5) * wave.irregularFactor
                rippleWaves[index].opacity = 0.0
                rippleWaves[index].rotation += Double.random(in: 120...240)
                rippleWaves[index].irregularFactor *= CGFloat.random(in: 0.9...1.1)
            }
            
            // 中途变化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let currentIndex = rippleWaves.firstIndex(where: { $0.id == wave.id }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rippleWaves[currentIndex].irregularFactor *= 1.2
                    }
                }
            }
            
            // 清理涟漪
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                rippleWaves.removeAll { $0.id == wave.id }
            }
        }
    }
    
    private func animateIrregularPulse(_ pulse: IrregularPulse) {
        if let index = irregularPulses.firstIndex(where: { $0.id == pulse.id }) {
            // 更动态的脉冲动画
            withAnimation(.easeOut(duration: 1.0 * pulse.speed)) {
                irregularPulses[index].scale = CGFloat.random(in: 3.5...5.0)
                irregularPulses[index].opacity = 0.0
            }
            
            // 添加旋转动画
            withAnimation(.linear(duration: 0.8 * pulse.speed)) {
                irregularPulses[index].angle += Double.random(in: 60...120)
            }
            
            // 清理脉冲
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 * pulse.speed) {
                irregularPulses.removeAll { $0.id == pulse.id }
            }
        }
    }
    
    private func performHapticFeedback() {
        NSSound.beep()
    }
}

#Preview {
    IdleSessionView(onStartSession: {})
        .environmentObject(SessionViewModel())
}

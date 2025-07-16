import SwiftUI

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
//
//  SessionView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var sessionViewModel = SessionViewModel.shared
    
    // 面板状态管理
    @State private var currentPanel: SessionPanel = .idle
    @State private var isAnimating = false
    
    // Panel 2 的状态管理
    @State private var selectedPlan: TimeBar?
    @State private var customProject = ""
    @State private var taskDescription = ""
    @State private var expectedTime = ""
    @State private var goals: [String] = [""]
    
    enum SessionPanel {
        case idle           // Panel 1: 空闲状态
        case taskSelection  // Panel 2: 任务选择
        case activeSession  // Panel 3: 任务进行中
    }
    
    var body: some View {
        ZStack {
            switch currentPanel {                case .idle:
                VStack {
                    Spacer()
                    
                    // 大圆形开始按钮
                    BigCircleStartButton {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPanel = .taskSelection
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                ))
            case .taskSelection:
                HStack(spacing: 0) {
                    TimeBlocksList(
                        plans: DataManager.currentPlan,
                        selectedPlan: $selectedPlan
                    )
                    .frame(width: 280)
                    TaskCustomizationArea(
                        selectedPlan: selectedPlan,
                        customProject: $customProject,
                        taskDescription: $taskDescription,
                        expectedTime: $expectedTime,
                        goals: $goals,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPanel = .idle
                                // 重置状态
                                selectedPlan = nil
                                customProject = ""
                                taskDescription = ""
                                expectedTime = ""
                                goals = [""]
                            }
                        },
                        onStart: {
                            // 开始会话的逻辑
                            let project = selectedPlan?.project ?? customProject
                            let themeColor = selectedPlan?.themeColor ?? "#00CE4A"
                            
                            sessionViewModel.startSession(
                                project: project,
                                task: taskDescription,
                                themeColor: themeColor
                            )
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPanel = .activeSession
                            }
                        }
                    )
                }
                .background(Color.appBackground)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            case .activeSession:
                if let currentSession = sessionViewModel.currentSession {
                    ZStack {
                        currentSession.themeColorSwiftUI.opacity(0.05).ignoresSafeArea()
                        VStack(spacing: Spacing.xxl * 2) {
                            Spacer()
                            Text(formatElapsedTime(sessionViewModel.elapsedTime))
                                .font(.system(size: 72, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            VStack(spacing: Spacing.sm) {
                                Text(currentSession.projectName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                if !currentSession.taskDescription.isEmpty {
                                    Text(currentSession.taskDescription)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                }
                            }
                            Spacer()
                            HStack(spacing: Spacing.xl) {
                                // 暂停按钮
                                Button(action: { /* TODO: 暂停逻辑 */ }) {
                                    ZStack {
                                        Circle()
                                            .fill(currentSession.themeColorSwiftUI.opacity(0.8))
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("暂停")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 结束按钮
                                Button(action: {
                                    sessionViewModel.endCurrentSession()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPanel = .idle
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(currentSession.themeColorSwiftUI.opacity(0.8))
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "stop.fill")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("结束")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.bottom, Spacing.xxl)
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                currentSession.themeColorSwiftUI.opacity(0.8),
                                currentSession.themeColorSwiftUI.opacity(0.6),
                                currentSession.themeColorSwiftUI.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .top)
                    ))
                }
            }
        }
        .onAppear {
            if sessionViewModel.currentSession != nil {
                currentPanel = .activeSession
            }
        }
        .onChange(of: sessionViewModel.currentSession) { oldValue, newValue in
            if newValue == nil && currentPanel == .activeSession {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPanel = .idle
                }
            }
        }
        .onKeyPress(.escape) {
            if currentPanel == .taskSelection {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPanel = .idle
                    // 重置状态
                    selectedPlan = nil
                    customProject = ""
                    taskDescription = ""
                    expectedTime = ""
                    goals = [""]
                }
                return .handled
            }
            return .ignored
        }
    }

    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct ActiveSessionCard: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    let session: FocusSession
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 状态指示
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: true)
                
                Text("专注中")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
            }
            
            // 项目和任务信息
            VStack(spacing: Spacing.md) {
                Text(session.projectName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(session.taskDescription)
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
            }
            
            // 计时器
            TimerView(elapsedTime: sessionViewModel.elapsedTime)
            
            // 结束按钮
            Button(action: {
                sessionViewModel.endCurrentSession()
            }) {
                Text("结束会话")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(Spacing.xl)
        .cardStyle()
    }
}

struct IdleSessionCard: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundColor(.secondaryGray)
            
            VStack(spacing: Spacing.md) {
                Text("开始专注会话")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("点击右上角的播放按钮开始一个新的专注会话")
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .cardStyle()
    }
}

// MARK: - 按压反馈修饰符
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}

// 左侧时间块列表
struct TimeBlocksList: View {
    let plans: [TimeBar]
    @Binding var selectedPlan: TimeBar?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("选择时间块")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
            
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(plans, id: \.id) { plan in
                        TimeBlockCard(
                            plan: plan,
                            isSelected: selectedPlan?.id == plan.id,
                            onTap: {
                                selectedPlan = plan
                            }
                        )
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.bottom, Spacing.lg)
            }
        }
        .background(Color.cardBackground)
        .overlay(
            Rectangle()
                .fill(Color.borderGray)
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// 时间块卡片
struct TimeBlockCard: View {
    let plan: PlanItem
    let isSelected: Bool
    let onTap: () -> Void
    
    private var completionProgress: Double {
        guard plan.plannedTime > 0 else { return 0 }
        return min(plan.actualTime / plan.plannedTime, 1.0)
    }
    
    private var isCompleted: Bool {
        plan.actualTime >= plan.plannedTime
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // 左侧彩色圆球 - 类似 Panel 1 的行星小球
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    plan.themeColorSwiftUI.opacity(0.9),
                                    plan.themeColorSwiftUI,
                                    plan.themeColorSwiftUI.opacity(0.7)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 16
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: plan.themeColorSwiftUI.opacity(0.6), radius: 4, x: 0, y: 2)
                    
                    // 高光效果
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(x: -4, y: -4)
                    
                    // 完成状态的进度环
                    Circle()
                        .trim(from: 0, to: completionProgress)
                        .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: completionProgress)
                    
                    // 完成状态图标
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // 项目信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.project)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 时间信息
                    HStack(spacing: Spacing.xs) {
                        Text(plan.actualTimeFormatted)
                            .font(.caption)
                            .foregroundColor(isCompleted ? .primaryGreen : .secondaryGray)
                        
                        Text("/")
                            .font(.caption)
                            .foregroundColor(.secondaryGray)
                        
                        Text(plan.plannedTimeFormatted)
                            .font(.caption)
                            .foregroundColor(.secondaryGray)
                        
                        Spacer()
                        
                        // 完成百分比
                        Text("\(Int(completionProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(plan.themeColorSwiftUI)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(
                        // 根据完成状态和选中状态调整背景
                        isSelected 
                            ? plan.themeColorSwiftUI.opacity(0.15)
                            : (isCompleted 
                                ? plan.themeColorSwiftUI.opacity(0.05)
                                : Color.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(
                                isSelected 
                                    ? plan.themeColorSwiftUI 
                                    : (isCompleted 
                                        ? plan.themeColorSwiftUI.opacity(0.3)
                                        : Color.borderGray), 
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 右侧任务自定义区域
struct TaskCustomizationArea: View {
    let selectedPlan: PlanItem?
    @Binding var customProject: String
    @Binding var taskDescription: String
    @Binding var expectedTime: String
    @Binding var goals: [String]
    let onBack: () -> Void
    let onStart: () -> Void
    
    @State private var expectedMinutes: Int = 30
    
    var canStart: Bool {
        let hasProject = selectedPlan != nil || !customProject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasProject
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("任务设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 占位，保持标题居中
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 项目信息
                    if selectedPlan == nil {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("项目名称")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("输入项目名称", text: $customProject)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("选中项目")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: Spacing.md) {
                                // 使用与 TimeBlockCard 一致的圆球设计
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    selectedPlan!.themeColorSwiftUI.opacity(0.9),
                                                    selectedPlan!.themeColorSwiftUI,
                                                    selectedPlan!.themeColorSwiftUI.opacity(0.7)
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 12
                                            )
                                        )
                                        .frame(width: 24, height: 24)
                                        .shadow(color: selectedPlan!.themeColorSwiftUI.opacity(0.6), radius: 2, x: 0, y: 1)
                                    
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .offset(x: -3, y: -3)
                                }
                                
                                Text(selectedPlan?.project ?? "")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(selectedPlan?.themeColorSwiftUI.opacity(0.08) ?? Color.lightGreen)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .stroke(selectedPlan?.themeColorSwiftUI.opacity(0.3) ?? Color.borderGray, lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // 任务描述 - 改为多行输入
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("任务主题")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(Color.borderGray, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                                        .fill(Color.cardBackground)
                                )
                                .frame(minHeight: 80)
                            
                            TextEditor(text: $taskDescription)
                                .padding(Spacing.sm)
                                .background(Color.clear)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                            
                            if taskDescription.isEmpty {
                                Text("描述你要做什么...")
                                    .foregroundColor(.secondaryGray)
                                    .padding(.horizontal, Spacing.sm + 4)
                                    .padding(.vertical, Spacing.sm + 8)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // 预期时间 - 使用 PlanView 样式的时间选择器
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("预期时间")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: Spacing.lg) {
                            HStack(spacing: Spacing.sm) {
                                Button(action: {
                                    adjustTime(-15)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.secondaryGray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(formatTimeDisplay())
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(width: 80)
                                
                                Button(action: {
                                    adjustTime(15)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.secondaryGray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .stroke(Color.borderGray, lineWidth: 1)
                                    )
                            )
                            
                            Spacer()
                        }
                    }
                    
                    // 预期小目标 - 改为更大的输入框
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("预期小目标")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(goals.indices, id: \.self) { index in
                            HStack(spacing: Spacing.md) {
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                                        .stroke(Color.borderGray, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                                .fill(Color.cardBackground)
                                        )
                                        .frame(minHeight: 60)
                                    
                                    TextEditor(text: $goals[index])
                                        .padding(Spacing.sm)
                                        .background(Color.clear)
                                        .font(.body)
                                        .scrollContentBackground(.hidden)
                                    
                                    if goals[index].isEmpty {
                                        Text("目标 \(index + 1)")
                                            .foregroundColor(.secondaryGray)
                                            .padding(.horizontal, Spacing.sm + 4)
                                            .padding(.vertical, Spacing.sm + 8)
                                            .allowsHitTesting(false)
                                    }
                                }
                                
                                if goals.count > 1 {
                                    Button(action: {
                                        goals.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        if goals.count < 5 {
                            Button(action: {
                                goals.append("")
                            }) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.primaryGreen)
                                    Text("添加目标")
                                        .foregroundColor(.primaryGreen)
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            
            // 开始按钮
            VStack {
                Button(action: onStart) {
                    Text("开始专注")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(canStart ? Color.primaryGreen : Color.secondaryGray)
                        )
                }
                .disabled(!canStart)
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.appBackground)
        }
        .onAppear {
            // 初始化时间显示
            updateExpectedTimeString()
        }
    }
    
    // 时间调整函数
    private func adjustTime(_ minutes: Int) {
        expectedMinutes = max(15, expectedMinutes + minutes)
        updateExpectedTimeString()
    }
    
    // 格式化时间显示
    private func formatTimeDisplay() -> String {
        let hours = expectedMinutes / 60
        let mins = expectedMinutes % 60
        
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    // 更新预期时间字符串
    private func updateExpectedTimeString() {
        expectedTime = formatTimeDisplay()
    }
}

// MARK: - 大圆形开始按钮
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

#Preview {
    SessionView()
        .environmentObject(SessionViewModel())
        .environmentObject(PlanViewModel())
}

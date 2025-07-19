//
//  StatisticsView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI
import AppKit

struct StatisticsView: View {
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    @State private var animationProgress: Double = 0.0
    @State private var showingHistoryView = false
    
    var body: some View {
        ZStack {
            if showingHistoryView {
                HistoryStatisticsView(isPresented: $showingHistoryView)
                    .environmentObject(statisticsViewModel)
            } else {
                mainStatisticsView
            }
        }
        .onAppear {
            statisticsViewModel.refreshStatistics()
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
    
    @State private var expandedProjectId: UUID? = nil
    @State private var selectedSessionId: UUID? = nil

    private var mainStatisticsView: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 标题
                    HStack {
                        Spacer()
                        Text("Statistics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.top, Spacing.xl)

                    // 统计面板
                    StatisticsPanelView(
                        statisticsItems: statisticsViewModel.statisticsItems,
                        sessions: statisticsViewModel.todaySessions,
                        animationProgress: animationProgress,
                        expandedProjectId: $expandedProjectId,
                        selectedSessionId: $selectedSessionId
                    )

                    if statisticsViewModel.statisticsItems.isEmpty {
                        StatisticsEmptyStateView()
                    }

                    Spacer(minLength: Spacing.xl)
                }
            }
            .containerStyle()

            // 历史数据回溯按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingHistoryView = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
    }
}

// MARK: - HistoryStatisticsView
struct HistoryStatisticsView: View {
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    @Binding var isPresented: Bool
    @State private var animationProgress: Double = 0.0
    @State private var selectedDateIndex: Int = 0
    @State private var expandedProjectId: UUID? = nil
    @State private var selectedSessionId: UUID? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 标题和退出按钮
                    HStack {
                        Button(action: {
                            statisticsViewModel.exitHistoryMode()
                            isPresented = false
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Text("历史数据")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 占位符保持标题居中
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    
                    // 日期选择器
                    if !statisticsViewModel.availableDates.isEmpty {
                        VStack(spacing: Spacing.md) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(Array(statisticsViewModel.availableDates.enumerated()), id: \.offset) { index, date in
                                        DateSelectionButton(
                                            date: date,
                                            isSelected: index == selectedDateIndex,
                                            action: {
                                                selectedDateIndex = index
                                                statisticsViewModel.selectDate(date)
                                                withAnimation(.easeInOut(duration: 1.0)) {
                                                    animationProgress = 0.0
                                                    animationProgress = 1.0
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    
                    // 统计面板
                    StatisticsPanelView(
                        statisticsItems: statisticsViewModel.statisticsItems,
                        sessions: statisticsViewModel.todaySessions,
                        animationProgress: animationProgress,
                        expandedProjectId: $expandedProjectId,
                        selectedSessionId: $selectedSessionId
                    )
                    
                    if statisticsViewModel.statisticsItems.isEmpty {
                        HistoryEmptyStateView()
                    }
                    
                    Spacer(minLength: Spacing.xl)
                }
            }
            .containerStyle()
            
            KeyboardHandlerView { key in
                if case .escape = key {
                    statisticsViewModel.exitHistoryMode()
                    isPresented = false
                    return true
                }
                return false
            }.allowsHitTesting(false)
        }
        .onAppear {
            statisticsViewModel.enterHistoryMode()
            if !statisticsViewModel.availableDates.isEmpty {
                selectedDateIndex = 0
                statisticsViewModel.selectDate(statisticsViewModel.availableDates[0])
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - DateSelectionButton
struct DateSelectionButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(formatWeekday(date))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondaryGray)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(isSelected ? Color.accentColor : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - HistoryEmptyStateView
struct HistoryEmptyStateView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.secondaryGray)
            
            Text("该日期暂无数据")
                .font(.headline)
                .foregroundColor(.secondaryGray)
            
            Text("请选择其他有数据的日期")
                .font(.body)
                .foregroundColor(.secondaryGray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - StatisticsTimeBar
struct StatisticsTimeBar: View {
    let item: StatisticsItem
    let animationProgress: Double
    
    @State private var isHovered = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左侧间距
                Spacer()
                    .frame(width: Spacing.md)
                
                // 主要时间条区域
                ZStack(alignment: .leading) {
                    // 背景条 (计划时间)
                    createBackgroundBar(containerWidth: geometry.size.width)
                    
                    // 进度条 (实际时间) - 带动画
                    createProgressBar(containerWidth: geometry.size.width)
                    
                    // 文字层 - 始终在最上层
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(item.project)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white) // 白色文字在有色玻璃上更清晰
                                .lineLimit(1)
                            
                            Text(TimeFormatters.formatDuration(item.plannedTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9)) // 半透明白色的次要文字
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        
                        Spacer()
                    }
                    .frame(width: calculateBarWidth(containerWidth: geometry.size.width, time: item.plannedTime), height: 44)
                    .allowsHitTesting(false) // 防止文字层阻挡点击
                }
                .frame(height: 44)
                
                // 右侧统计信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TimeFormatters.formatDuration(item.actualTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(item.completionPercentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(item.completionPercentage > 1.0 ? .red : .secondaryGray)
                }
                .frame(width: 60, alignment: .leading)
                .padding(.leading, Spacing.sm)
                
                Spacer()
            }
        }
        .frame(height: 44)
        .onHover { isHovered = $0 }
    }
    
    @ViewBuilder
    private func createBackgroundBar(containerWidth: CGFloat) -> some View {
        let barWidth = calculateBarWidth(containerWidth: containerWidth, time: item.plannedTime)
        
        ZStack {
            // 背景形状和阴影
            createBackgroundWithShadow()
        }
        .frame(width: barWidth, height: 44)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    @ViewBuilder
    private func createProgressBar(containerWidth: CGFloat) -> some View {
        let progressWidth = calculateProgressWidth(containerWidth: containerWidth)
        
        RoundedRectangle(cornerRadius: CornerRadius.small)
            .fill(createProgressStyle())
            .frame(width: progressWidth * animationProgress, height: 44)
            .offset(x: item.completionPercentage > 1.0 ? shakeOffset : 0) // 超过100%时添加抖动
            .animation(.easeInOut(duration: 1.5), value: animationProgress)
            .allowsHitTesting(false) // 确保进度条不阻挡交互
            .onAppear {
                // 如果超过100%，开始抖动动画
                if item.completionPercentage > 1.0 {
                    startShakeAnimation()
                }
            }
    }
    
    private func createBackgroundStyle() -> LinearGradient {
        if item.isSpecialMaterial {
            return item.specialMaterialGradient ?? LinearGradient(
                colors: [item.themeColorSwiftUI],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [item.themeColorSwiftUI],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    @ViewBuilder
    private func createBackgroundWithShadow() -> some View {
        if item.isSpecialMaterial {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(
                    LinearGradient(
                        colors: [
                            item.themeColorSwiftUI.opacity(0.45),
                            item.themeColorSwiftUI.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // 内部光泽效果
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                )
                .overlay(
                    // 边框高光
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    item.themeColorSwiftUI.opacity(0.8),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: item.specialMaterialShadow!.opacity(0.3), radius: isHovered ? 8 : 4, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.1), radius: isHovered ? 12 : 6, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(
                    LinearGradient(
                        colors: [
                            item.themeColorSwiftUI.opacity(0.45),
                            item.themeColorSwiftUI.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // 内部光泽效果
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                )
                .overlay(
                    // 边框高光
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    item.themeColorSwiftUI.opacity(0.8),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: item.themeColorSwiftUI.opacity(0.25), radius: isHovered ? 6 : 3, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.08), radius: isHovered ? 10 : 5, x: 0, y: 3)
        }
    }
    
    private func createProgressStyle() -> LinearGradient {
        // 始终使用项目主题色，不管是否超过100%
        if item.isSpecialMaterial {
            // 特殊材质使用预定义的渐变
            return item.specialMaterialGradient ?? LinearGradient(
                colors: [item.themeColorSwiftUI, item.themeColorSwiftUI],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // 普通颜色使用原色的渐变
            return LinearGradient(
                colors: [item.themeColorSwiftUI, item.themeColorSwiftUI],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func calculateBarWidth(containerWidth: CGFloat, time: TimeInterval) -> CGFloat {
        let safeWidth = max(containerWidth - 60 - Spacing.md * 2 - Spacing.sm, 200) // 减去右侧文本区域
        let baseWidth = safeWidth * 0.2
        let maxWidth = safeWidth * 0.7
        let totalHours = time / 3600
        let logScale = log(1 + totalHours) / log(1 + 3) // 3 hours reference
        let proportionalWidth = baseWidth + (maxWidth - baseWidth) * logScale
        return max(baseWidth, min(proportionalWidth, maxWidth))
    }
    
    private func calculateProgressWidth(containerWidth: CGFloat) -> CGFloat {
        let plannedBarWidth = calculateBarWidth(containerWidth: containerWidth, time: item.plannedTime)
        
        // 如果完成度超过100%，进度条会超出计划条的宽度
        if item.completionPercentage > 1.0 {
            let safeWidth = max(containerWidth - 60 - Spacing.md * 2 - Spacing.sm, 200)
            let maxOverflowWidth = safeWidth * 0.85 // 最大可以到容器的85%
            let overflowRatio = min(item.completionPercentage - 1.0, 0.5) // 最多超出50%
            let overflowWidth = (maxOverflowWidth - plannedBarWidth) * overflowRatio
            return plannedBarWidth + overflowWidth
        } else {
            return plannedBarWidth * item.completionPercentage
        }
    }
    
    // 抖动动画方法
    private func startShakeAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            shakeOffset = 2.0
        }
    }
}

// MARK: - StatisticsEmptyStateView
struct StatisticsEmptyStateView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondaryGray)
            
            Text("暂无统计数据")
                .font(.headline)
                .foregroundColor(.secondaryGray)
            
            Text("开始专注工作后，这里会显示今日的时间统计")
                .font(.body)
                .foregroundColor(.secondaryGray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Session Detail Compact View
struct SessionDetailCompactView: View {
    let session: FocusSession
    
    private let primaryGreen = Color(red: 0.0, green: 0.81, blue: 0.29)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 任务标题和时间
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.taskDescription)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(session.startTime, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 时间对比
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDuration(session.duration))
                        .font(.title3.bold())
                        .foregroundColor(primaryGreen)
                    
                    Text(formatDuration(session.expectedTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
            
            // 目标列表
            if !session.goals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("目标")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    ForEach(session.goals.filter { !$0.isEmpty }, id: \.self) { goal in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(primaryGreen)
                            Text(goal)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            // 完成情况
            if !session.actualCompletion.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("实际完成")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    Text(session.actualCompletion)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }
            
            // 感想
            if !session.reflection.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("感想")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    Text(session.reflection)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }
            
            // 后续行动
            if !session.followUp.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("后续行动")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    Text(session.followUp)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}


// MARK: - Statistics Panel View (可复用)
struct StatisticsPanelView: View {
    let statisticsItems: [StatisticsItem]
    let sessions: [FocusSession]
    let animationProgress: Double
    
    @Binding var expandedProjectId: UUID?
    @Binding var selectedSessionId: UUID?
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(statisticsItems) { item in
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring()) {
                            expandedProjectId = expandedProjectId == item.id ? nil : item.id
                            // 默认选中第一个session
                            if expandedProjectId == item.id {
                                let filtered = sessions.filter { $0.projectName == item.project }
                                selectedSessionId = filtered.first?.id
                            }
                        }
                    }) {
                        StatisticsTimeBar(
                            item: item,
                            animationProgress: animationProgress
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 展开区：横向Session选择
                    if expandedProjectId == item.id {
                        let filtered = sessions.filter { $0.projectName == item.project }
                        if !filtered.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(filtered, id: \ .id) { session in
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                selectedSessionId = session.id
                                            }
                                        }) {
                                            Text(session.taskDescription.isEmpty ? "noName" : session.taskDescription)
                                                .font(.body)
                                                .foregroundColor(selectedSessionId == session.id ? .white : .primary)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedSessionId == session.id ? Color.accentColor : Color.cardBackground)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.accentColor.opacity(0.3), lineWidth: selectedSessionId == session.id ? 0 : 1)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                            }
                            .padding(.vertical, Spacing.md)
                        }
                    }
                    // Session详情展示面板
                    if let selectedSessionId = selectedSessionId,
                       let session = sessions.first(where: { $0.id == selectedSessionId }),
                       expandedProjectId == item.id {
                        SessionDetailCompactView(session: session)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.bottom, Spacing.md)
                            .transition(.opacity.combined(with: .slide))
                    }
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(StatisticsViewModel())
}

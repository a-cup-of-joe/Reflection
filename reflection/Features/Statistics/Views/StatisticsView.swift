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
    
    private var mainStatisticsView: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 标题
                    HStack {
                        Spacer()
                        Text("今日统计")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.top, Spacing.xl)
                    
                    // 统计面板
                    VStack(spacing: Spacing.md) {
                        ForEach(statisticsViewModel.statisticsItems) { item in
                            StatisticsTimeBar(
                                item: item,
                                animationProgress: animationProgress
                            )
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.large)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, Spacing.lg)
                    
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
                            Text("选择日期")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                    VStack(spacing: Spacing.md) {
                        ForEach(statisticsViewModel.statisticsItems) { item in
                            StatisticsTimeBar(
                                item: item,
                                animationProgress: animationProgress
                            )
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.large)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, Spacing.lg)
                    
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
            }
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


#Preview {
    StatisticsView()
        .environmentObject(StatisticsViewModel())
}

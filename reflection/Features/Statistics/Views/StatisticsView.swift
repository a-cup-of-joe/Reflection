//
//  StatisticsView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
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
            
            // 刷新按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        statisticsViewModel.refreshStatistics()
                        withAnimation(.easeInOut(duration: 1.5)) {
                            animationProgress = 0.0
                            animationProgress = 1.0
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
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
        .onAppear {
            statisticsViewModel.refreshStatistics()
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - StatisticsTimeBar
struct StatisticsTimeBar: View {
    let item: StatisticsItem
    let animationProgress: Double
    
    @State private var isHovered = false
    
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
            
            // 内容
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
            .animation(.easeInOut(duration: 1.5), value: animationProgress)
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
        if item.completionPercentage > 1.0 {
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if item.isSpecialMaterial {
            return item.specialMaterialGradient ?? LinearGradient(
                colors: [item.themeColorSwiftUI, item.themeColorSwiftUI.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [item.themeColorSwiftUI, item.themeColorSwiftUI.opacity(0.8)],
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

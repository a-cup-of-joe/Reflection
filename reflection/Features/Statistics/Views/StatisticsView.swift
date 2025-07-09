//
//  StatisticsView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // 标题和刷新按钮
                HStack {
                    Text("统计分析")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("刷新") {
                        statisticsViewModel.refreshStatistics()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xl)
                
                // 统计内容
                if let stats = statisticsViewModel.statisticsData {
                    // 总体统计
                    OverallStatsCard(stats: stats)
                    
                    // 项目统计
                    ProjectStatsCard(projectStats: stats.projectStats)
                    
                    // 效率分析
                    EfficiencyAnalysisCard(stats: stats)
                } else {
                    // 空状态
                    EmptyStatsCard()
                }
                
                Spacer(minLength: Spacing.xl)
            }
        }
        .containerStyle()
        .onAppear {
            statisticsViewModel.refreshStatistics()
        }
    }
}

struct OverallStatsCard: View {
    let stats: StatisticsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("总体统计")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 2), spacing: Spacing.md) {
                StatItemCard(
                    title: "总计划时间",
                    value: TimeFormatters.formatDuration(stats.totalPlannedTime),
                    color: .primaryGreen
                )
                
                StatItemCard(
                    title: "总实际时间",
                    value: TimeFormatters.formatDuration(stats.totalActualTime),
                    color: .primaryGreen
                )
                
                StatItemCard(
                    title: "会话总数",
                    value: "\(stats.totalSessions)",
                    color: .primaryGreen
                )
                
                StatItemCard(
                    title: "平均会话时长",
                    value: TimeFormatters.formatDuration(stats.averageSessionDuration),
                    color: .primaryGreen
                )
            }
        }
        .padding(Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Spacing.xl)
    }
}

struct StatItemCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryGray)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(Spacing.lg)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.small)
    }
}

struct ProjectStatsCard: View {
    let projectStats: [ProjectStatistics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("项目统计")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if projectStats.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondaryGray)
                    
                    Text("暂无项目数据")
                        .font(.body)
                        .foregroundColor(.secondaryGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(projectStats) { project in
                        ProjectStatCard(project: project)
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Spacing.xl)
    }
}

struct ProjectStatCard: View {
    let project: ProjectStatistics
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // 项目信息
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(project.projectName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: Spacing.lg) {
                    Text("计划: \(TimeFormatters.formatDuration(project.plannedTime))")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                    
                    Text("实际: \(TimeFormatters.formatDuration(project.actualTime))")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                    
                    Text("会话: \(project.sessionCount)")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                }
            }
            
            Spacer()
            
            // 效率指标
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("\(Int(project.efficiency * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
                
                if abs(project.timeDifference) > 60 {
                    Text(project.timeDifference > 0 ? "超时" : "提前")
                        .font(.caption)
                        .foregroundColor(project.timeDifference > 0 ? .orange : .primaryGreen)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.lightGray.opacity(0.5))
        .cornerRadius(CornerRadius.small)
    }
}

struct EfficiencyAnalysisCard: View {
    let stats: StatisticsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("效率分析")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: Spacing.lg) {
                HStack {
                    Text("整体完成率")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(stats.efficiency * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)
                }
                
                // 进度条
                ProgressView(value: min(stats.efficiency, 1.0))
                    .tint(.primaryGreen)
                    .scaleEffect(y: 3.0)
                
                Text(efficiencyMessage)
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Spacing.xl)
    }
    
    private var efficiencyMessage: String {
        if stats.efficiency >= 1.0 {
            return "太棒了！你已经完成了所有计划目标。"
        } else if stats.efficiency >= 0.8 {
            return "很好！你已经完成了大部分计划目标。"
        } else if stats.efficiency >= 0.5 {
            return "还不错，继续加油完成剩余目标。"
        } else {
            return "需要更多专注时间来完成计划目标。"
        }
    }
}

struct EmptyStatsCard: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundColor(.secondaryGray)
            
            VStack(spacing: Spacing.md) {
                Text("暂无统计数据")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("创建一些计划并开始专注会话后，这里将显示详细的统计信息。")
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Spacing.xl)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(StatisticsViewModel())
}

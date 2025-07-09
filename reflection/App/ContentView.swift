//
//  ContentView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var planViewModel = PlanViewModel()
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var statisticsViewModel = StatisticsViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧 Sidebar（固定宽度 90）
            VStack(spacing: Spacing.xl) {
                // Logo 或应用标识
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryGreen)
                    
                    Text("R")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primaryGreen)
                }
                .padding(.top, 50) // 为窗口控制按钮留出空间
                
                // 导航图标按钮
                VStack(spacing: Spacing.lg) {
                    SidebarIconButton(
                        icon: "calendar",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    SidebarIconButton(
                        icon: "timer",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                    
                    SidebarIconButton(
                        icon: "chart.bar",
                        isSelected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }
                }
                
                Spacer()
            }
            .frame(width: 90)
            .background(Color.lightGreen.opacity(0.3))
            
            // 右侧主内容区域
            Group {
                switch selectedTab {
                case 0:
                    PlanView()
                        .environmentObject(planViewModel)
                case 1:
                    SessionView()
                        .environmentObject(sessionViewModel)
                        .environmentObject(planViewModel)
                case 2:
                    StatisticsView()
                        .environmentObject(statisticsViewModel)
                default:
                    PlanView()
                        .environmentObject(planViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
        .edgesIgnoringSafeArea(.top)
        .onWindowAccess { window in
            guard let window = window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
        }
        .appStyle()
        .onChange(of: sessionViewModel.sessions) {
            // 当会话更新时，刷新统计数据
            statisticsViewModel.refreshStatistics()
        }
    }
}

// MARK: - SidebarIconButton
struct SidebarIconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondaryGray)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(isSelected ? Color.primaryGreen : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isSelected ? Color.primaryGreen.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}

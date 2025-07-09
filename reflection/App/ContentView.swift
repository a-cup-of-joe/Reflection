//
//  ContentView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//
//  This is a MacOS app, not IOS!

import SwiftUI

struct ContentView: View {
    @StateObject private var planViewModel = PlanViewModel()
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var statisticsViewModel = StatisticsViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景
            Color.appBackground
                .ignoresSafeArea()
            
            // 主内容区域
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
            .padding(.leading, 64 + 12) // sidebar宽度(64) + sidebar左边距(12) + 内容左边距(12)
            .padding(.trailing, Spacing.sm) // 右侧边距
            
            // 悬浮的侧边栏面板
            VStack(spacing: Spacing.xl) {
                // Logo 或应用标识
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primaryGreen)
                    
                    Text("R")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGreen)
                }
                .padding(.top, Spacing.md)
                
                // 导航图标按钮
                VStack(spacing: Spacing.md) {
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
            .frame(width: 64)
            .background(Color.white)
            .cornerRadius(CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.top, 32) // 为窗口控制按钮留出空间
            .padding(.leading, 12) // 左侧间距
            .padding(.bottom, 12) // 底部间距
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
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .fill(isSelected ? Color.primaryGreen : Color.clear)
                    .frame(width: 3, height: 3)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var iconColor: Color {
        if isSelected {
            return .white
        } else if isHovered {
            return .primaryGreen
        } else {
            return .secondaryGray
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .primaryGreen
        } else if isHovered {
            return .borderGray.opacity(0.3)
        } else {
            return .clear
        }
    }
}

#Preview {
    ContentView()
}

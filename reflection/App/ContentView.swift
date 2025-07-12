//
//  ContentView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//
//  This is a MacOS app, not IOS!

import SwiftUI

struct ContentView: View {
    // 改为使用 EnvironmentObject
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var planViewModel: PlanViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel

    
    @State private var selectedTab = 0
    @State private var windowSize: CGSize = .zero
    @State private var shouldHideSidebar = false
    
    // 侧边栏隐藏的阈值宽度
    private let sidebarHideThreshold: CGFloat = 600
    
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
                case 1:
                    SessionView()
                case 2:
                    StatisticsView()
                default:
                    PlanView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .padding(.leading, shouldHideSidebar ? 0 : (64 + 12)) // 动态调整padding
            .animation(.easeInOut(duration: 0.3), value: shouldHideSidebar)
            
            // 悬浮的侧边栏面板
            if !shouldHideSidebar {
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
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        windowSize = geometry.size
                        updateSidebarVisibility()
                    }
                    .onChange(of: geometry.size) { oldSize, newSize in
                        windowSize = newSize
                        updateSidebarVisibility()
                    }
            }
        )
        .onWindowAccess { window in
            guard let window = window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        }
        .appStyle()
        .onChange(of: sessionViewModel.currentSession) { oldValue, newValue in
            updateSidebarVisibility()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            updateSidebarVisibility()
        }
    }
    
    // MARK: - Private Methods
    private func updateSidebarVisibility() {
        let isWindowTooNarrow = windowSize.width < sidebarHideThreshold
        let isInFocusMode = selectedTab == 1 && sessionViewModel.currentSession != nil
        
        let newShouldHide = isWindowTooNarrow || isInFocusMode
        
        if newShouldHide != shouldHideSidebar {
            shouldHideSidebar = newShouldHide
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

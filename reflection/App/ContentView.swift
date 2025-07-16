//
//  ContentView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//
//  This is a MacOS app, not IOS!

import SwiftUI

struct ContentView: View {
    // MARK: - Constants
    private enum Constants {
        static let sidebarWidth: CGFloat = 64
        static let sidebarPadding: CGFloat = 12
        static let sidebarHideThreshold: CGFloat = 450
        static let windowControlButtonHeight: CGFloat = 32
    }
    
    private enum TabIndex {
        static let planning = 0
        static let session = 1
        static let statistics = 2
        static let note = 3
    }
    
    // MARK: - State Properties
    @StateObject private var planViewModel = PlanViewModel()
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var statisticsViewModel = StatisticsViewModel()
    @StateObject private var noteViewModel = NoteViewModel()
    
    @State private var selectedTab = TabIndex.planning
    @State private var windowSize: CGSize = .zero
    @State private var shouldHideSidebar = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景
            Color.appBackground
                .ignoresSafeArea()
            
            // 主内容区域
            mainContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                .padding(.leading, shouldHideSidebar ? 0 : (Constants.sidebarWidth + Constants.sidebarPadding))
                .animation(.easeInOut(duration: 0.3), value: shouldHideSidebar)
            
            // 侧边栏
            if !shouldHideSidebar {
                sidebarView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(geometryReader)
        .appStyle()
        .onChange(of: sessionViewModel.sessions) {
            statisticsViewModel.refreshStatistics()
        }
        .onChange(of: sessionViewModel.currentSession) { _, _ in
            updateSidebarVisibility()
        }
        .onChange(of: selectedTab) { _, _ in
            updateSidebarVisibility()
        }
    }
    
    // MARK: - Computed Properties
    private var mainContentView: some View {
        Group {
            switch selectedTab {
            case TabIndex.planning:
                PlanView()
                    .environmentObject(planViewModel)
            case TabIndex.session:
                SessionView()
                    .environmentObject(sessionViewModel)
                    .environmentObject(planViewModel)
            case TabIndex.statistics:
                StatisticsView()
                    .environmentObject(statisticsViewModel)
            case TabIndex.note:
                NoteView()
                    .environmentObject(noteViewModel)
            default:
                PlanView()
                    .environmentObject(planViewModel)
            }
        }
    }
    
    private var sidebarView: some View {
        VStack(spacing: Spacing.xl) {
            // Logo 或应用标识
            appLogo
            
            // 导航图标按钮
            navigationButtons
            
            Spacer()
            
            // 设置按钮
            settingsButton
                .padding(.bottom, Spacing.md)
        }
        .frame(width: Constants.sidebarWidth)
        .background(Color.white)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.top, Constants.windowControlButtonHeight)
        .padding(.leading, Constants.sidebarPadding)
        .padding(.bottom, Constants.sidebarPadding)
    }
    
    private var appLogo: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.primaryGreen)
            
            Text("R")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primaryGreen)
        }
        .padding(.top, Spacing.md)
    }
    
    private var navigationButtons: some View {
        VStack(spacing: Spacing.md) {
            SidebarIconButton(
                icon: "calendar",
                isSelected: selectedTab == TabIndex.planning
            ) {
                selectedTab = TabIndex.planning
            }

            SidebarIconButton(
                icon: "timer",
                isSelected: selectedTab == TabIndex.session
            ) {
                selectedTab = TabIndex.session
            }

            SidebarIconButton(
                icon: "chart.bar",
                isSelected: selectedTab == TabIndex.statistics
            ) {
                selectedTab = TabIndex.statistics
            }

            SidebarIconButton(
                icon: "doc.plaintext",
                isSelected: selectedTab == TabIndex.note
            ) {
                selectedTab = TabIndex.note
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettings = true
        }) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondaryGray)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .fill(Color.clear)
                    .frame(width: 3, height: 3)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            // 可以添加悬停效果
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(sessionViewModel: sessionViewModel)
        }
    }
    
    private var geometryReader: some View {
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
    }
    
    // MARK: - Private Methods
    private func updateSidebarVisibility() {
        let isWindowTooNarrow = windowSize.width < Constants.sidebarHideThreshold
        let isInFocusMode = selectedTab == TabIndex.session && sessionViewModel.currentSession != nil
        
        let newShouldHide = isWindowTooNarrow || isInFocusMode
        
        if newShouldHide != shouldHideSidebar {
            shouldHideSidebar = newShouldHide
        }
    }
}

// MARK: - SidebarIconButton
struct SidebarIconButton: View {
    // MARK: - Properties
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Private Views
    private var buttonContent: some View {
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
    
    // MARK: - Computed Properties
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

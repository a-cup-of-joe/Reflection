//
//  SessionView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    
    // 面板状态管理
    @State private var currentPanel: SessionPanel = .idle
    @State private var isAnimating = false
    
    // Panel 2 的状态管理
    @State private var selectedPlan: PlanItem?
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
            // 确保整个视图有背景色覆盖
            Color.appBackground
                .ignoresSafeArea(.all)
            
            switch currentPanel {
            case .idle:
                IdleSessionView {
                    //这里暂停1秒等动画播完
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPanel = .taskSelection
                        }
                    }
                }
                
            case .taskSelection:
                TaskSelectionView(
                    selectedPlan: $selectedPlan,
                    customProject: $customProject,
                    taskDescription: $taskDescription,
                    expectedTime: $expectedTime,
                    goals: $goals,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPanel = .idle
                            resetTaskSelectionState()
                        }
                    },
                    onStart: {
                        startSessionFromTaskSelection()
                    }
                )
                
            case .activeSession:
                if let currentSession = sessionViewModel.currentSession {
                    ActiveSessionView(
                        currentSession: currentSession,
                        onEnd: {
                            sessionViewModel.endCurrentSession()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPanel = .idle
                            }
                        }
                    )
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
                    resetTaskSelectionState()
                }
                return .handled
            }
            return .ignored
        }
    }
    
    // MARK: - Helper Methods
    
    /// 重置任务选择状态
    private func resetTaskSelectionState() {
        selectedPlan = nil
        customProject = ""
        taskDescription = ""
        expectedTime = ""
        goals = [""]
    }
    
    /// 从任务选择界面开始会话
    private func startSessionFromTaskSelection() {
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


}

#Preview {
    SessionView()
        .environmentObject(SessionViewModel())
        .environmentObject(PlanViewModel())
}

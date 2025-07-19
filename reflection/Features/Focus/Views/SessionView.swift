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
        case completion     // Panel 4: 会话完成
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
                            let elapsed = sessionViewModel.elapsedTime
                            if elapsed < 10 {
                                // 丢弃本次会话，不保存
                                sessionViewModel.discardCurrentSession()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPanel = .idle
                                    resetTaskSelectionState()
                                }
                            } else {
                                sessionViewModel.endCurrentSession()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPanel = .completion
                                }
                            }
                        }
                    )
                }
                
            case .completion:
                if let lastSession = sessionViewModel.sessions.last {
                    SessionCompletionView(
                        completedSession: lastSession,
                        actualDuration: sessionViewModel.elapsedTime,
                        onEnd: {
                            sessionViewModel.endCurrentSession()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPanel = .idle
                                resetTaskSelectionState()
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
        // .onChange(of: sessionViewModel.currentSession) { oldValue, newValue in
        //     if newValue == nil && currentPanel == .activeSession {
        //         withAnimation(.easeInOut(duration: 0.3)) {
        //             currentPanel = .completion
        //         }
        //     }
        // }
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
        
        // 解析预期时间（处理 "30m" 或 "1h30m" 格式）
        let expectedTimeInterval = parseExpectedTime(expectedTime)
        
        // 过滤空的目标
        let validGoals = goals.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        sessionViewModel.startSession(
            project: project,
            task: taskDescription,
            themeColor: themeColor,
            goals: validGoals,
            expectedTime: expectedTimeInterval
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPanel = .activeSession
        }
    }
    
    /// 解析预期时间字符串（支持 "30m", "1h30m" 格式）
    private func parseExpectedTime(_ timeString: String) -> TimeInterval {
        var totalMinutes = 0
        
        // 处理 "30m" 格式
        if timeString.hasSuffix("m") {
            let minutesString = timeString.replacingOccurrences(of: "m", with: "")
            if let minutes = Int(minutesString) {
                totalMinutes = minutes
            }
        }
        
        // 处理 "1h30m" 格式
        else if timeString.contains("h") {
            let components = timeString.components(separatedBy: CharacterSet(charactersIn: "hm"))
            if components.count >= 1 {
                if let hours = Int(components[0]) {
                    totalMinutes += hours * 60
                }
            }
            if components.count >= 2 {
                if let minutes = Int(components[1]) {
                    totalMinutes += minutes
                }
            }
        }
        
        // 默认30分钟
        if totalMinutes == 0 {
            totalMinutes = 30
        }
        
        return TimeInterval(totalMinutes * 60)
    }


}

#Preview {
    SessionView()
        .environmentObject(SessionViewModel())
        .environmentObject(PlanViewModel())
}

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
            switch currentPanel {
                case .idle:
                VStack {
                    Spacer()
                    BigCircleStartButton {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPanel = .taskSelection
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                ))
            case .taskSelection:
                HStack(spacing: 0) {
                    TimeBlocksList(
                        plans: planViewModel.plans.sorted { plan1, plan2 in
                            let isCompleted1 = plan1.actualTime >= plan1.plannedTime
                            let isCompleted2 = plan2.actualTime >= plan2.plannedTime
                            if isCompleted1 != isCompleted2 {
                                return !isCompleted1
                            }
                            return plan1.createdAt < plan2.createdAt
                        },
                        selectedPlan: $selectedPlan
                    )
                    .frame(width: 280)
                    TaskCustomizationArea(
                        selectedPlan: selectedPlan,
                        customProject: $customProject,
                        taskDescription: $taskDescription,
                        expectedTime: $expectedTime,
                        goals: $goals,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPanel = .idle
                                // 重置状态
                                selectedPlan = nil
                                customProject = ""
                                taskDescription = ""
                                expectedTime = ""
                                goals = [""]
                            }
                        },
                        onStart: {
                            // 开始会话的逻辑
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
                    )
                }
                .background(Color.appBackground)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            case .activeSession:
                if let currentSession = sessionViewModel.currentSession {
                    ZStack {
                        currentSession.themeColorSwiftUI.opacity(0.05).ignoresSafeArea()
                        VStack(spacing: Spacing.xxl * 2) {
                            Spacer()
                            Text(sessionViewModel.elapsedTime.formatted())
                                .font(.system(size: 72, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            VStack(spacing: Spacing.sm) {
                                Text(currentSession.projectName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                if !currentSession.taskDescription.isEmpty {
                                    Text(currentSession.taskDescription)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                }
                            }
                            Spacer()
                            HStack(spacing: Spacing.xl) {
                                // 暂停按钮
                                Button(action: { /* TODO: 暂停逻辑 */ }) {
                                    ZStack {
                                        Circle()
                                            .fill(currentSession.themeColorSwiftUI.opacity(0.8))
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("暂停")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 结束按钮
                                Button(action: {
                                    sessionViewModel.endCurrentSession()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPanel = .idle
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(currentSession.themeColorSwiftUI.opacity(0.8))
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "stop.fill")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("结束")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.bottom, Spacing.xxl)
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                currentSession.themeColorSwiftUI.opacity(0.8),
                                currentSession.themeColorSwiftUI.opacity(0.6),
                                currentSession.themeColorSwiftUI.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .top)
                    ))
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
                    // 重置状态
                    selectedPlan = nil
                    customProject = ""
                    taskDescription = ""
                    expectedTime = ""
                    goals = [""]
                }
                return .handled
            }
            return .ignored
        }
    }


}

#Preview {
    SessionView()
        .environmentObject(SessionViewModel())
        .environmentObject(PlanViewModel())
}

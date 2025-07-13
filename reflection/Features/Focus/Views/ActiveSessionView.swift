//
//  ActiveSessionView.swift
//  reflection
//
//  Created by linan on 2025/7/13.
//

import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    let currentSession: FocusSession
    let onEnd: () -> Void
    
    var body: some View {
        ZStack {
            // 使用温柔的莫兰迪色系背景色
            Color.getGentleBackgroundColor(for: currentSession.themeColor)
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: Spacing.xxl * 2) {
                Spacer()
                
                // 计时器显示
                Text(sessionViewModel.elapsedTime.formatted())
                    .font(.system(size: 72, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
                
                // 项目和任务信息
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
                    
                    // 暂停状态指示
                    if sessionViewModel.isPaused {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.white.opacity(0.8))
                            Text("已暂停")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
                
                Spacer()
                
                // 控制按钮
                HStack(spacing: Spacing.xl) {
                    // 暂停/恢复按钮
                    Button(action: {
                        if sessionViewModel.isPaused {
                            sessionViewModel.resumeSession()
                        } else {
                            sessionViewModel.pauseSession()
                        }
                    }) {
                        SessionControlButton(
                            iconName: sessionViewModel.isPaused ? "play.fill" : "pause.fill",
                            buttonText: sessionViewModel.isPaused ? "继续" : "暂停",
                            color: Color.getSecondaryColor(for: currentSession.themeColor),
                            themeColor: currentSession.themeColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 结束按钮
                    Button(action: onEnd) {
                        SessionControlButton(
                            iconName: "stop.fill",
                            buttonText: "结束",
                            color: Color.getSecondaryColor(for: currentSession.themeColor),
                            themeColor: currentSession.themeColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, Spacing.xxl)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .top)
        ))
    }
}

// MARK: - 会话控制按钮组件
struct SessionControlButton: View {
    let iconName: String
    let buttonText: String
    let color: Color
    let themeColor: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.getGentleBackgroundColor(for: themeColor))
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
                .frame(width: 80, height: 80)
            
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text(buttonText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ActiveSessionView(
        currentSession: FocusSession(
            projectName: "Test Project",
            taskDescription: "Test Task",
            themeColor: "#00CE4A"
        ),
        onEnd: {}
    )
    .environmentObject(SessionViewModel())
}

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

            // 呼吸球背景
            BreathingCircle(themeColor: currentSession.themeColor)

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
            }

            // 控制按钮区单独固定在底部
            VStack {
                Spacer()
                HStack(spacing: Spacing.lg) {
                    // 暂停/恢复按钮（描线风格）
                    Button(action: {
                        if sessionViewModel.isPaused {
                            sessionViewModel.resumeSession()
                        } else {
                            sessionViewModel.pauseSession()
                        }
                    }) {
                        SessionControlButton(
                            iconName: sessionViewModel.isPaused ? "play" : "pause",
                            color: Color.getSecondaryColor(for: currentSession.themeColor),
                            themeColor: currentSession.themeColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 结束按钮（描线风格）
                    Button(action: onEnd) {
                        SessionControlButton(
                            iconName: "stop",
                            color: Color.getSecondaryColor(for: currentSession.themeColor),
                            themeColor: currentSession.themeColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 新增笔记按钮（描线风格，无功能）
                    Button(action: {}) {
                        VStack(spacing: 2) {
                            Image(systemName: "note.text")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 50)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .top)
        ))
    }
}

// MARK: - 呼吸球组件
struct BreathingCircle: View {
    let themeColor: String
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: 300, height: 300)
            .scaleEffect(scale)
            .onAppear {
                startBreathingAnimation()
            }
    }
    
    private func startBreathingAnimation() {
        performBreathingCycle()
    }
    
    private func performBreathingCycle() {
        // 阶段1: 4秒膨胀到最大
        withAnimation(.easeInOut(duration: 4)) {
            scale = 1.0
            opacity = 0.15
        }
        
        // 阶段2: 6秒静止期间的轻微波动
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            startSubtleFluctuation()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            // 阶段3: 8秒匀速缩回到小圆形
            withAnimation(.linear(duration: 8)) {
                scale = 0.3
                opacity = 0.3
            }
        }
        
        // 18秒后开始下一个周期
        DispatchQueue.main.asyncAfter(deadline: .now() + 18) {
            performBreathingCycle()
        }
    }
    
    private func startSubtleFluctuation() {
        // 在6秒内进行轻微的呼吸循环：1秒缩小 + 1秒放大 = 2秒一个周期
        // 6秒内刚好可以完成3个周期 (3 * 2 = 6秒)
        let cycleCount = 3
        let cycleDuration = 2.0
        
        for i in 0..<cycleCount {
            let startTime = Double(i) * cycleDuration
            
            // 每个周期：1秒缩小，1秒放大
            DispatchQueue.main.asyncAfter(deadline: .now() + startTime) {
                // 1秒缩小到0.95
                withAnimation(.easeInOut(duration: 1.0)) {
                    scale = 0.95
                    opacity = 0.17
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + startTime + 1.0) {
                // 1秒放大回到1.0
                withAnimation(.easeInOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 0.15
                }
            }
        }
    }
}

// MARK: - 会话控制按钮组件
struct SessionControlButton: View {
    let iconName: String
    let color: Color
    let themeColor: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Color.white.opacity(0.65))
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

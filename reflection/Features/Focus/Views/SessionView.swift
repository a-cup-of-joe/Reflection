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
    @State private var showingStartSession = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // 标题和开始按钮
                HStack {
                    Text("专注会话")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingStartSession = true
                    }) {
                        Image(systemName: "play.circle")
                            .font(.title2)
                    }
                    .buttonStyle(CircleButtonStyle())
                    .disabled(sessionViewModel.currentSession != nil)
                }
                .padding(.top, Spacing.xl)
                
                // 当前会话或空闲状态
                if let currentSession = sessionViewModel.currentSession {
                    ActiveSessionCard(session: currentSession)
                        .environmentObject(sessionViewModel)
                } else {
                    IdleSessionCard()
                }
                
                // 会话历史
                if !sessionViewModel.sessions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        HStack {
                            Text("最近会话")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(sessionViewModel.sessions.suffix(5).reversed(), id: \.id) { session in
                                SessionHistoryCard(session: session)
                            }
                        }
                    }
                }
                
                Spacer(minLength: Spacing.xl)
            }
        }
        .containerStyle()
        .sheet(isPresented: $showingStartSession) {
            StartSessionView()
                .environmentObject(sessionViewModel)
                .environmentObject(planViewModel)
        }
    }
}

struct ActiveSessionCard: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    let session: FocusSession
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 状态指示
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: true)
                
                Text("专注中")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
            }
            
            // 项目和任务信息
            VStack(spacing: Spacing.md) {
                Text(session.projectName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(session.taskDescription)
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
            }
            
            // 计时器
            TimerView(elapsedTime: sessionViewModel.elapsedTime)
            
            // 结束按钮
            Button(action: {
                sessionViewModel.endCurrentSession()
            }) {
                Text("结束会话")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(Spacing.xl)
        .cardStyle()
    }
}

struct IdleSessionCard: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundColor(.secondaryGray)
            
            VStack(spacing: Spacing.md) {
                Text("开始专注会话")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("点击右上角的播放按钮开始一个新的专注会话")
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .cardStyle()
    }
}

struct SessionHistoryCard: View {
    let session: FocusSession
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // 项目信息
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(session.projectName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(session.taskDescription)
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 时间信息
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(TimeFormatters.formatDuration(session.duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
                
                Text(TimeFormatters.formatTime(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondaryGray)
            }
        }
        .padding(Spacing.lg)
        .cardStyle()
    }
}

#Preview {
    SessionView()
        .environmentObject(SessionViewModel())
        .environmentObject(PlanViewModel())
}

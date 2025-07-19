//
//  SessionCompletionView.swift
//  reflection
//
//  Created by AI Assistant on 2025/7/19.
//

import SwiftUI

struct SessionCompletionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    
    let completedSession: FocusSession
    let actualDuration: TimeInterval
    let onEnd: () -> Void
    
    @State private var actualCompletion: String = ""
    @State private var reflection: String = ""
    @State private var followUp: String = ""
    
    // 响应式布局
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // 固定绿色主题色
    private let primaryGreen = Color(red: 0.0, green: 0.81, blue: 0.29)
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // 标题
                        VStack(spacing: 8) {
                            Text("Session Complete")
                                .font(.largeTitle.bold())
                        }
                        .padding(.top, 24)

                        HStack(alignment: .top, spacing: 32) {
                            projectInfoCard
                            feedbackSection
                        }
                    }
                    saveButton
                        .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    }
    
    private var projectInfoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 项目名
            VStack(alignment: .leading, spacing: 6) {
                Text("项目")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text(completedSession.projectName)
                    .font(.title.bold())
                    .lineLimit(2)
            }
            
            // 任务描述
            VStack(alignment: .leading, spacing: 6) {
                Text("任务")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text(completedSession.taskDescription)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(4)
            }
            
            // 时间对比 - 水平排列
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("预计时间")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text(formatDuration(completedSession.expectedTime))
                        .font(.title2.bold())
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("实际用时")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text(formatDuration(actualDuration))
                        .font(.title2.bold())
                        .foregroundColor(primaryGreen)
                }
            }
            
            // 目标列表
            if !completedSession.goals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Targets")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    ForEach(completedSession.goals.filter { !$0.isEmpty }, id: \.self) { goal in
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(primaryGreen)
                            Text(goal)
                                .font(.body)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 实际完成情况
            VStack(alignment: .leading, spacing: 8) {
                Text("Actual Completion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                TextEditor(text: $actualCompletion)
                    .font(.body)
                    .padding(12)
                    .background(Color.textFieldBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 80, maxHeight: 120)
            }
            
            // 感想
            VStack(alignment: .leading, spacing: 8) {
                Text("Thoughts")
                    .font(.title3)
                    .foregroundColor(.secondary)
                TextEditor(text: $reflection)
                    .font(.body)
                    .padding(12)
                    .background(Color.textFieldBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 80, maxHeight: 120)
            }
            
            // 后续行动
            VStack(alignment: .leading, spacing: 8) {
                Text("Follow-ups")
                    .font(.title3)
                    .foregroundColor(.secondary)
                TextEditor(text: $followUp)
                    .font(.body)
                    .padding(12)
                    .background(Color.textFieldBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 80, maxHeight: 120)
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .frame(maxWidth: .infinity)
    }
    
    private var saveButton: some View {
        Button(action: saveSession) {
            Text("完成")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: 400)
                .frame(height: 52)
                .background(primaryGreen)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func saveSession() {
        // 更新会话信息
        var updatedSession = completedSession
        updatedSession.actualCompletion = actualCompletion
        updatedSession.reflection = reflection
        updatedSession.followUp = followUp

        // 更新会话
        sessionViewModel.updateSession(updatedSession)

        // 通知父视图
        onEnd()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

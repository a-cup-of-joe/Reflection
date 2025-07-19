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
    
    @State private var actualCompletion: String = ""
    @State private var reflection: String = ""
    @State private var followUp: String = ""
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("会话完成")
                            .font(.largeTitle.bold())
                        Text("回顾你的专注时光")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // 会话信息卡片
                    sessionInfoCard
                    
                    // 反馈表单
                    feedbackForm
                    
                    // 保存按钮
                    saveButton
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var sessionInfoCard: some View {
        VStack(spacing: 16) {
            // 项目信息
            VStack(spacing: 4) {
                Text(completedSession.projectName)
                    .font(.title2.bold())
                Text(completedSession.taskDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // 时间信息
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("预计时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(completedSession.expectedTime))
                        .font(.headline)
                }
                
                VStack(spacing: 4) {
                    Text("实际时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(actualDuration))
                        .font(.headline)
                        .foregroundColor(completedSession.themeColorSwiftUI)
                }
            }
            
            // 时间差异
            let timeDiff = actualDuration - completedSession.expectedTime
            if abs(timeDiff) > 60 { // 差异超过1分钟才显示
                Text(timeDiff > 0 ? "超出 \(formatDuration(timeDiff))" : "节省 \(formatDuration(-timeDiff))")
                    .font(.caption)
                    .foregroundColor(timeDiff > 0 ? .orange : .green)
            }
            
            // 目标列表
            if !completedSession.goals.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("预期目标")
                        .font(.headline)
                    ForEach(completedSession.goals.filter { !$0.isEmpty }, id: \.self) { goal in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(completedSession.themeColorSwiftUI)
                            Text(goal)
                                .font(.body)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var feedbackForm: some View {
        VStack(spacing: 20) {
            // 实际完成情况
            VStack(alignment: .leading, spacing: 8) {
                Text("实际完成情况")
                    .font(.headline)
                TextEditor(text: $actualCompletion)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.textFieldBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // 感想
            VStack(alignment: .leading, spacing: 8) {
                Text("感想与反思")
                    .font(.headline)
                TextEditor(text: $reflection)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.textFieldBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Follow-up
            VStack(alignment: .leading, spacing: 8) {
                Text("后续行动")
                    .font(.headline)
                TextEditor(text: $followUp)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.textFieldBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveSession) {
            if isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            } else {
                Text("保存并返回")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(actualCompletion.isEmpty && reflection.isEmpty && followUp.isEmpty ? Color.gray : completedSession.themeColorSwiftUI)
                    .cornerRadius(12)
            }
        }
        .disabled(isSaving || (actualCompletion.isEmpty && reflection.isEmpty && followUp.isEmpty))
    }
    
    private func saveSession() {
        isSaving = true
        
        // 更新会话信息
        var updatedSession = completedSession
        updatedSession.actualCompletion = actualCompletion
        updatedSession.reflection = reflection
        updatedSession.followUp = followUp
        
        // 更新会话
        sessionViewModel.updateSession(updatedSession)
        
        // 延迟一下给用户反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
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

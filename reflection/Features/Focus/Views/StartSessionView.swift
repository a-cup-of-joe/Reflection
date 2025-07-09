//
//  StartSessionView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct StartSessionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProject = ""
    @State private var taskDescription = ""
    @State private var customProject = ""
    @State private var showingCustomProject = false
    
    var availableProjects: [String] {
        planViewModel.plans.map { $0.project }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Text("开始专注会话")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("开始") {
                    startSession()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canStartSession)
            }
            .padding(Spacing.xl)
            .background(Color.appBackground)
            
            // 表单内容
            VStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 项目选择
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("项目选择")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !availableProjects.isEmpty {
                            Picker("项目", selection: $selectedProject) {
                                Text("选择项目").tag("")
                                ForEach(availableProjects, id: \.self) { project in
                                    Text(project).tag(project)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .disabled(showingCustomProject)
                        }
                        
                        Toggle("自定义项目", isOn: $showingCustomProject)
                            .toggleStyle(SwitchToggleStyle(tint: .primaryGreen))
                        
                        if showingCustomProject {
                            TextField("自定义项目名称", text: $customProject)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                    }
                    
                    // 任务描述
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("任务描述")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("具体要做什么...", text: $taskDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .font(.body)
                    }
                }
                
                Spacer()
            }
            .padding(Spacing.xl)
            .background(Color.appBackground)
        }
        .frame(width: 500, height: 450)
        .background(Color.appBackground)
    }
    
    private var canStartSession: Bool {
        let project = showingCustomProject ? customProject : selectedProject
        return !project.isEmpty && !taskDescription.isEmpty
    }
    
    private func startSession() {
        let project = showingCustomProject ? customProject : selectedProject
        
        // 查找对应计划的主题色
        let themeColor = planViewModel.plans.first { $0.project == project }?.themeColor ?? "#00CE4A"
        
        sessionViewModel.startSession(project: project, task: taskDescription, themeColor: themeColor)
        dismiss()
    }
}

#Preview {
    StartSessionView()
        .environmentObject(SessionViewModel())
        .environmentObject(PlanViewModel())
}

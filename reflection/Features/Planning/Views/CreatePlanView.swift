//
//  CreatePlanView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct CreatePlanView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var timeInput = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Text("新建计划")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("创建") {
                    createPlan()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(projectName.isEmpty || timeInput.isEmpty)
            }
            .padding(Spacing.xl)
            .background(Color.appBackground)
            
            // 表单内容
            VStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 项目信息
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("项目名称")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入项目名称", text: $projectName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // 计划时间
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("计划时间")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("例如: 2:30 表示2小时30分钟", text: $timeInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                        
                        Text("格式说明：30 (30分钟) | 1:30 (1小时30分钟) | 2:30:45 (2小时30分45秒)")
                            .font(.caption)
                            .foregroundColor(.secondaryGray)
                            .padding(.horizontal, Spacing.sm)
                    }
                }
                
                Spacer()
            }
            .padding(Spacing.xl)
            .background(Color.appBackground)
        }
        .frame(width: 500, height: 400)
        .background(Color.appBackground)
        .alert("错误", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createPlan() {
        guard !projectName.isEmpty else {
            showError("请输入项目名称")
            return
        }
        
        guard let plannedTime = TimeFormatters.parseTimeInput(timeInput) else {
            showError("时间格式不正确，请参考格式说明")
            return
        }
        
        guard plannedTime > 0 else {
            showError("计划时间必须大于0")
            return
        }
        
        planViewModel.addPlan(project: projectName, plannedTime: plannedTime)
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    CreatePlanView()
        .environmentObject(PlanViewModel())
}

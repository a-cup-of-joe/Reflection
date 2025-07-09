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
    @State private var totalMinutes = 30 // 总分钟数
    @State private var selectedThemeColor = "#00CE4A"
    @State private var showingError = false
    @State private var errorMessage = ""
    

    
    var body: some View {
        ZStack {
            // 主内容
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("新建时间段")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(Spacing.md)  // 减少标题栏padding
                .background(Color.appBackground)
                
                // 表单内容
                VStack(spacing: Spacing.md) {  // 减少整体间距
                    VStack(alignment: .leading, spacing: Spacing.md) {  // 减少表单项间距
                        // 时间段名称
                        HStack(spacing: Spacing.lg) {
                            Text("名称")
                                .font(.subheadline)
                                .foregroundColor(.secondaryGray)
                                .frame(width: 60, alignment: .leading)
                            
                            TextField("时间段名称", text: $projectName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.white)
                                .cornerRadius(CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .stroke(Color.borderGray, lineWidth: 1)
                                )
                        }
                        
                        // 主题色选择
                        HStack(spacing: Spacing.lg) {
                            Text("颜色")
                                .font(.subheadline)
                                .foregroundColor(.secondaryGray)
                                .frame(width: 60, alignment: .leading)
                            
                            HStack(spacing: Spacing.sm) {
                                ForEach(Color.themeColors, id: \.self) { colorHex in
                                    Button(action: {
                                        selectedThemeColor = colorHex
                                    }) {
                                        Group {
                                            if Color.isSpecialMaterial(colorHex) {
                                                // 特殊材质显示
                                                Circle()
                                                    .fill(Color.getSpecialMaterialGradient(colorHex)!)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.white.opacity(0.6),
                                                                        Color.black.opacity(0.2)
                                                                    ]),
                                                                    startPoint: .top,
                                                                    endPoint: .bottom
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                                    .frame(width: 16, height: 16)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                selectedThemeColor == colorHex ? Color.primary : Color.clear,
                                                                lineWidth: 2
                                                            )
                                                            .frame(width: 20, height: 20)
                                                    )
                                                    .shadow(color: Color.getSpecialMaterialShadow(colorHex)!, radius: 2, x: 0, y: 1)
                                                    .scaleEffect(selectedThemeColor == colorHex ? 1.2 : 1.0)
                                                    .animation(.easeInOut(duration: 0.2), value: selectedThemeColor)
                                            } else {
                                                // 普通颜色显示
                                                Circle()
                                                    .fill(Color(hex: colorHex))
                                                    .frame(width: 16, height: 16)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                selectedThemeColor == colorHex ? Color.primary : Color.clear,
                                                                lineWidth: 2
                                                            )
                                                    )
                                                    .scaleEffect(selectedThemeColor == colorHex ? 1.2 : 1.0)
                                                    .animation(.easeInOut(duration: 0.2), value: selectedThemeColor)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // 时间选择
                        HStack(spacing: Spacing.lg) {
                            Text("时间")
                                .font(.subheadline)
                                .foregroundColor(.secondaryGray)
                                .frame(width: 60, alignment: .leading)
                            
                            HStack(spacing: Spacing.sm) {
                                Button(action: {
                                    adjustTime(-15)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.secondaryGray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(formatTimeDisplay())
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(width: 60)
                                
                                Button(action: {
                                    adjustTime(15)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.secondaryGray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // 减少间距
                    Spacer(minLength: Spacing.xs)  // 进一步减少间距
                    
                    HStack(spacing: Spacing.sm) {
                        Button("取消") { dismiss() }
                            .buttonStyle(SmallSecondaryButtonStyle())
                        Spacer()
                        Button("创建") { createPlan() }
                            .buttonStyle(SmallButtonStyle())
                            .disabled(projectName.isEmpty)
                    }
                }
                .padding(Spacing.md)  // 减少外层padding
                .background(Color.appBackground)
            }
            .frame(width: 380, height: 260)
            .background(Color.appBackground)
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func adjustTime(_ minutes: Int) {
        let newTotal = totalMinutes + minutes
        if newTotal >= 15 && newTotal <= 480 { // 15分钟到8小时
            totalMinutes = newTotal
        }
    }
    
    private func formatTimeDisplay() -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func createPlan() {
        guard !projectName.isEmpty else {
            showError("请输入时间段名称")
            return
        }
        
        guard totalMinutes > 0 else {
            showError("计划时间必须大于0")
            return
        }
        
        let totalSeconds = TimeInterval(totalMinutes * 60)
        
        planViewModel.addPlan(
            project: projectName,
            plannedTime: totalSeconds,
            themeColor: selectedThemeColor
        )
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

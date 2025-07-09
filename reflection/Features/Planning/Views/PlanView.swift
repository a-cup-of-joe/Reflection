//
//  PlanView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct PlanView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @State private var showingAddPlan = false
    @State private var selectedPlan: PlanItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // 标题和添加按钮
                HStack {
                    Text("时间分配计划")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddPlan = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .buttonStyle(CircleButtonStyle())
                }
                .padding(.top, Spacing.xl)
                
                // 时间条列表
                LazyVStack(spacing: Spacing.md) {
                    ForEach(planViewModel.plans) { plan in
                        TimeBarView(plan: plan) {
                            selectedPlan = plan
                        }
                    }
                }
                
                if planViewModel.plans.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(.secondaryGray)
                        
                        Text("暂无时间段")
                            .font(.headline)
                            .foregroundColor(.secondaryGray)
                        
                        Text("点击上方 + 按钮创建您的第一个时间段")
                            .font(.body)
                            .foregroundColor(.secondaryGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, Spacing.xxl)
                }
                
                Spacer(minLength: Spacing.xl)
            }
        }
        .containerStyle()
        .sheet(isPresented: $showingAddPlan) {
            CreatePlanView()
                .environmentObject(planViewModel)
        }
        .sheet(item: $selectedPlan) { plan in
            EditPlanView(plan: plan)
                .environmentObject(planViewModel)
        }
    }
}

// MARK: - TimeBarView
struct TimeBarView: View {
    let plan: PlanItem
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Button(action: onTap) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(plan.project)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(formatPlanTime())
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        
                        Spacer()
                    }
                    .frame(width: calculateBarWidth(containerWidth: geometry.size.width), height: 44)
                    .background(
                        Group {
                            if plan.isSpecialMaterial {
                                // 特殊材质效果
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .fill(plan.specialMaterialGradient!)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.small)
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
                                    .shadow(color: plan.specialMaterialShadow!, radius: isHovered ? 6 : 3, x: 0, y: 2)
                                    .shadow(color: Color.black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: 4)
                            } else {
                                // 普通颜色效果
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .fill(plan.themeColorSwiftUI)
                                    .shadow(color: plan.themeColorSwiftUI.opacity(0.3), radius: isHovered ? 4 : 2, x: 0, y: 2)
                            }
                        }
                    )
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isHovered = hovering
                }
                
                Spacer()
            }
        }
        .frame(height: 44)
    }
    
    private func formatPlanTime() -> String {
        let totalMinutes = Int(plan.plannedTime / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func calculateBarWidth(containerWidth: CGFloat) -> CGFloat {
        let totalMinutes = plan.plannedTime / 60
        let totalHours = totalMinutes / 60
        
        // 基础宽度：15分钟对应容器宽度的20%
        let baseWidth = containerWidth * 0.2
        
        // 3小时对应容器宽度的70%
        let maxWidth = containerWidth * 0.7
        let referenceHours: CGFloat = 3.0
        
        // 计算比例宽度
        let proportionalWidth = baseWidth + (totalHours / referenceHours) * (maxWidth - baseWidth)
        
        // 限制最小和最大宽度
        let minWidth = containerWidth * 0.15  // 最小15%
        let finalMaxWidth = containerWidth * 0.85  // 最大85%
        
        return max(minWidth, min(proportionalWidth, finalMaxWidth))
    }
}

// MARK: - EditPlanView
struct EditPlanView: View {
    let plan: PlanItem
    @EnvironmentObject var planViewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String
    @State private var totalMinutes: Int
    @State private var selectedThemeColor: String
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(plan: PlanItem) {
        self.plan = plan
        self._projectName = State(initialValue: plan.project)
        self._totalMinutes = State(initialValue: Int(plan.plannedTime / 60))
        self._selectedThemeColor = State(initialValue: plan.themeColor)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Spacer()
                    
                    Text("编辑时间段")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
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
                                            }
                                        }
                                            .scaleEffect(selectedThemeColor == colorHex ? 1.2 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: selectedThemeColor)
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
                        Button("删除") { showingDeleteConfirmation = true }
                            .buttonStyle(SmallSecondaryButtonStyle())
                            .foregroundColor(.red)
                        Button("保存") { showingSaveConfirmation = true }
                            .buttonStyle(SmallButtonStyle())
                            .disabled(projectName.isEmpty)
                    }
                }
                .padding(Spacing.md)  // 减少外层padding
                .background(Color.appBackground)
            }
            .frame(width: 380, height: 280)
            .background(Color.appBackground)
            .alert("确认保存", isPresented: $showingSaveConfirmation) {
                Button("取消", role: .cancel) { }
                Button("保存") {
                    savePlan()
                }
            } message: {
                Text("确定要保存对时间段的修改吗？")
            }
            .alert("确认删除", isPresented: $showingDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deletePlan()
                }
            } message: {
                Text("确定要删除这个时间段吗？此操作无法撤销。")
            }
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
    
    private func savePlan() {
        guard !projectName.isEmpty else {
            showError("请输入时间段名称")
            return
        }
        
        guard totalMinutes > 0 else {
            showError("计划时间必须大于0")
            return
        }
        
        planViewModel.updatePlan(
            planId: plan.id,
            project: projectName,
            plannedTime: TimeInterval(totalMinutes * 60),
            themeColor: selectedThemeColor
        )
        dismiss()
    }
    
    private func deletePlan() {
        planViewModel.deletePlan(planId: plan.id)
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    PlanView()
        .environmentObject(PlanViewModel())
}
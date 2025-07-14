//
//  TaskSelectionView.swift
//  reflection
//
//  Created by linan on 2025/7/13.
//

import SwiftUI

struct TaskSelectionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @Binding var selectedPlan: PlanItem?
    @Binding var customProject: String
    @Binding var taskDescription: String
    @Binding var expectedTime: String
    @Binding var goals: [String]
    
    let onBack: () -> Void
    let onStart: () -> Void
    
    var body: some View {
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
                onBack: onBack,
                onStart: onStart
            )
        }
        .background(Color.appBackground)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
    }
}

// 左侧时间块列表
struct TimeBlocksList: View {
    let plans: [PlanItem]
    @Binding var selectedPlan: PlanItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("选择时间块")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
            
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(plans, id: \.id) { plan in
                        SelectableTimeBar(
                            plan: plan,
                            isSelected: selectedPlan?.id == plan.id,
                            onTap: {
                                selectedPlan = plan
                            }
                        )
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.bottom, Spacing.lg)
            }
        }
        .background(Color.cardBackground)
        .overlay(
            Rectangle()
                .fill(Color.borderGray)
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// 可选择的时间条（复用PlanView样式，无拖拽、占满长度、有选中状态）
struct SelectableTimeBar: View {
    let plan: PlanItem
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.project)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(plan.plannedTime.formatted())
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                
                Spacer()
                
                // 选中状态的标识符
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.trailing, Spacing.md)
                }
            }
            .frame(height: 44)
            .background(createBackground())
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { isHovered = $0 }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func createBackground() -> some View {
        if plan.isSpecialMaterial {
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
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(color: plan.specialMaterialShadow!, radius: isHovered ? 6 : 3, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(plan.themeColorSwiftUI)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(
                            isSelected ? Color.white : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(color: plan.themeColorSwiftUI.opacity(0.3), radius: isHovered ? 4 : 2, x: 0, y: 2)
        }
    }
}

// 右侧任务自定义区域
struct TaskCustomizationArea: View {
    let selectedPlan: PlanItem?
    @Binding var customProject: String
    @Binding var taskDescription: String
    @Binding var expectedTime: String
    @Binding var goals: [String]
    let onBack: () -> Void
    let onStart: () -> Void
    
    @State private var expectedMinutes: Int = 30
    
    var canStart: Bool {
        let hasProject = selectedPlan != nil || !customProject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasProject
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("任务设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 占位，保持标题居中
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 项目信息
                    if selectedPlan == nil {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("项目名称")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("输入项目名称", text: $customProject)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.cardBackground)
                                .cornerRadius(CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                                        .stroke(Color.borderGray, lineWidth: 1)
                                )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("选中项目")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: Spacing.md) {
                                // 使用与 TimeBlockCard 一致的圆球设计
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    selectedPlan!.themeColorSwiftUI.opacity(0.9),
                                                    selectedPlan!.themeColorSwiftUI,
                                                    selectedPlan!.themeColorSwiftUI.opacity(0.7)
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 12
                                            )
                                        )
                                        .frame(width: 24, height: 24)
                                        .shadow(color: selectedPlan!.themeColorSwiftUI.opacity(0.6), radius: 2, x: 0, y: 1)
                                    
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .offset(x: -3, y: -3)
                                }
                                
                                Text(selectedPlan?.project ?? "")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(selectedPlan?.themeColorSwiftUI.opacity(0.08) ?? Color.lightGreen)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .stroke(selectedPlan?.themeColorSwiftUI.opacity(0.3) ?? Color.borderGray, lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // 任务描述 - 改为多行输入
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("任务主题")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(Color.borderGray, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                                        .fill(Color.cardBackground)
                                )
                                .frame(minHeight: 80)
                            
                            TextEditor(text: $taskDescription)
                                .padding(Spacing.sm)
                                .background(Color.clear)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                        }
                    }
                    
                    // 预期时间 - 复用PlanFormView的时间选择器
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("预期时间")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        PlanTimeAdjuster(totalMinutes: $expectedMinutes)
                    }
                    
                    // 预期小目标 - 改为更大的输入框
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("预期目标")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(goals.indices, id: \.self) { index in
                            HStack(spacing: Spacing.md) {
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                                        .stroke(Color.borderGray, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                                .fill(Color.cardBackground)
                                        )
                                        .frame(minHeight: 60)
                                    
                                    TextEditor(text: $goals[index])
                                        .padding(Spacing.sm)
                                        .background(Color.clear)
                                        .font(.body)
                                        .scrollContentBackground(.hidden)
                                    
                                }
                                
                                if goals.count > 1 {
                                    Button(action: {
                                        goals.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        if goals.count < 5 {
                            Button(action: {
                                goals.append("")
                            }) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.primaryGreen)
                                    Text("添加目标")
                                        .foregroundColor(.primaryGreen)
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            
            // 开始按钮
            VStack {
                Button(action: onStart) {
                    Text("开始专注")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(canStart ? Color.primaryGreen : Color.secondaryGray)
                        )
                }
                .disabled(!canStart)
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.appBackground)
        }
        .onAppear {
            // 初始化时间显示
            updateExpectedTimeString()
        }
        .onChange(of: expectedMinutes) { _, _ in
            updateExpectedTimeString()
        }
    }
    
    // 更新预期时间字符串
    private func updateExpectedTimeString() {
        expectedTime = expectedMinutes.formattedAsTime()
    }
}

#Preview {
    TaskSelectionView(
        selectedPlan: .constant(nil),
        customProject: .constant(""),
        taskDescription: .constant(""),
        expectedTime: .constant(""),
        goals: .constant([""]),
        onBack: {},
        onStart: {}
    )
    .environmentObject(SessionViewModel())
    .environmentObject(PlanViewModel())
}

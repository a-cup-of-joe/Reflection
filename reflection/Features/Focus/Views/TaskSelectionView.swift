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
                        TimeBlockCard(
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

// 时间块卡片
struct TimeBlockCard: View {
    let plan: PlanItem
    let isSelected: Bool
    let onTap: () -> Void
    
    private var completionProgress: Double {
        guard plan.plannedTime > 0 else { return 0 }
        return min(plan.actualTime / plan.plannedTime, 1.0)
    }
    
    private var isCompleted: Bool {
        plan.actualTime >= plan.plannedTime
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // 左侧彩色圆球 - 类似 Panel 1 的行星小球
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    plan.themeColorSwiftUI.opacity(0.9),
                                    plan.themeColorSwiftUI,
                                    plan.themeColorSwiftUI.opacity(0.7)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 16
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: plan.themeColorSwiftUI.opacity(0.6), radius: 4, x: 0, y: 2)
                    
                    // 高光效果
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(x: -4, y: -4)
                    
                    // 完成状态的进度环
                    Circle()
                        .trim(from: 0, to: completionProgress)
                        .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: completionProgress)
                    
                    // 完成状态图标
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // 项目信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.project)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 时间信息
                    HStack(spacing: Spacing.xs) {
                        Text(plan.actualTime.formatted())
                            .font(.caption)
                            .foregroundColor(isCompleted ? .primaryGreen : .secondaryGray)
                        
                        Text("/")
                            .font(.caption)
                            .foregroundColor(.secondaryGray)
                        
                        Text(plan.plannedTime.formatted())
                            .font(.caption)
                            .foregroundColor(.secondaryGray)
                        
                        Spacer()
                        
                        // 完成百分比
                        Text("\(Int(completionProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(plan.themeColorSwiftUI)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(
                        // 根据完成状态和选中状态调整背景
                        isSelected 
                            ? plan.themeColorSwiftUI.opacity(0.15)
                            : (isCompleted 
                                ? plan.themeColorSwiftUI.opacity(0.05)
                                : Color.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(
                                isSelected 
                                    ? plan.themeColorSwiftUI 
                                    : (isCompleted 
                                        ? plan.themeColorSwiftUI.opacity(0.3)
                                        : Color.borderGray), 
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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
                                .textFieldStyle(CustomTextFieldStyle())
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
                    
                    // 预期时间 - 使用 PlanView 样式的时间选择器
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("预期时间")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: Spacing.lg) {
                            HStack(spacing: Spacing.sm) {
                                Button(action: {
                                    adjustTime(-15)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.secondaryGray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(expectedMinutes.formattedAsTime())
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(width: 80)
                                
                                Button(action: {
                                    adjustTime(15)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.secondaryGray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .stroke(Color.borderGray, lineWidth: 1)
                                    )
                            )
                            
                            Spacer()
                        }
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
    }
    
    // 时间调整函数
    private func adjustTime(_ minutes: Int) {
        expectedMinutes = max(15, expectedMinutes + minutes)
        updateExpectedTimeString()
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

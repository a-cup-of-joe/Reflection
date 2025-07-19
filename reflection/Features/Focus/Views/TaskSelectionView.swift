//
//  TaskSelectionView.swift
//  reflection
//
//  Created by linan on 2025/7/13.
//

import SwiftUI
import AppKit

// MARK: - KeyboardHandlerView for macOS
struct KeyboardHandlerView: NSViewRepresentable {
    let onKeyPress: (KeyboardKey) -> Bool
    
    enum KeyboardKey {
        case escape
        case other(UInt16)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyboardHandlerNSView()
        view.onKeyPress = onKeyPress
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyboardHandlerNSView {
            view.onKeyPress = onKeyPress
        }
    }
}

class KeyboardHandlerNSView: NSView {
    var onKeyPress: ((KeyboardHandlerView.KeyboardKey) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        let key: KeyboardHandlerView.KeyboardKey
        
        if event.keyCode == 53 { // ESC key
            key = .escape
        } else {
            key = .other(event.keyCode)
        }
        
        if let handler = onKeyPress, handler(key) {
            return // 事件已处理
        }
        
        super.keyDown(with: event)
    }
}

struct TaskSelectionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @Binding var selectedPlan: PlanItem?
    @Binding var taskDescription: String
    @Binding var expectedTime: String
    @Binding var goals: [String]
    
    let onBack: () -> Void
    let onStart: () -> Void
    
    @State private var showDraftAlert = false
    @State private var hasDraft = false
    
    var body: some View {
        HStack(spacing: 0) {
            TimeBlocksList(
                plans: planViewModel.currentPlanItems.sorted(by: sortPlans),
                selectedPlan: $selectedPlan
            )
            .frame(width: 280)
            
            TaskCustomizationArea(
                selectedPlan: $selectedPlan,
                taskDescription: $taskDescription,
                expectedTime: $expectedTime,
                goals: $goals,
                onBack: onBack,
                onStart: onStart,
                onSaveDraft: saveCurrentDraft,
                hasDraft: hasDraft
            )
        }
        .background(Color.appBackground)
        .onTapGesture {
            // 点击空白区域时清除焦点
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .background(
            // 隐藏的可聚焦视图用于捕获键盘事件
            KeyboardHandlerView { key in
                if case .escape = key {
                    onBack()
                    return true
                }
                return false
            }
        )
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
        .onAppear {
            checkForDraft()
            setupAutoSave()
        }
        .onDisappear {
            saveCurrentDraft()
        }
    }
    
    private func sortPlans(_ plan1: PlanItem, _ plan2: PlanItem) -> Bool {
        let isCompleted1 = plan1.actualTime >= plan1.plannedTime
        let isCompleted2 = plan2.actualTime >= plan2.plannedTime
        if isCompleted1 != isCompleted2 {
            return !isCompleted1
        }
        return plan1.createdAt < plan2.createdAt
    }
    
    private func checkForDraft() {
        hasDraft = TaskDraftManager.shared.hasDraft()
    }
    
    private func restoreDraft() {
        guard let draft = TaskDraftManager.shared.loadDraft() else { return }
        
        if let planID = draft.selectedPlanID {
            selectedPlan = planViewModel.currentPlanItems.first { $0.id == planID }
        } else {
            selectedPlan = nil
        }
        
        taskDescription = draft.taskDescription
        expectedTime = draft.expectedTime
        goals = draft.goals.isEmpty ? [""] : draft.goals
    }
    
    private func saveCurrentDraft() {
        let selectedPlanID = selectedPlan?.id
        TaskDraftManager.shared.saveDraft(
            selectedPlanID: selectedPlanID,
            taskDescription: taskDescription,
            expectedTime: expectedTime,
            goals: goals.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        )
    }
    
    private func clearDraft() {
        TaskDraftManager.shared.clearDraft()
        hasDraft = false
        
        // 重置表单
        selectedPlan = nil
        taskDescription = ""
        expectedTime = "30分钟"
        goals = [""]
    }
    
    private func setupAutoSave() {
        // 使用onChange监听所有需要保存的变量变化
    }
}

// 左侧时间块列表
struct TimeBlocksList: View {
    let plans: [PlanItem]
    @Binding var selectedPlan: PlanItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("选择时间块")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
            }
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
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @Binding var selectedPlan: PlanItem?
    @Binding var taskDescription: String
    @Binding var expectedTime: String
    @Binding var goals: [String]
    let onBack: () -> Void
    let onStart: () -> Void
    let onSaveDraft: () -> Void
    let hasDraft: Bool
    
    @State private var expectedMinutes: Int = 30
    
    var canStart: Bool {
        let hasProject = selectedPlan != nil || !taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    .layoutPriority(1) // 确保标题不会被压缩
                
                Spacer()
                
                // 草稿操作按钮
                HStack(spacing: Spacing.md) {
                    if hasDraft {
                        Button(action: restoreDraft) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16))
                                .foregroundColor(.primaryGreen)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("恢复草稿")
                    }
                    
                    Button(action: clearForm) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("清除表单")
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 项目信息
                    projectInfoSection
                    
                    // 任务描述 - 改为多行输入
                    taskDescriptionSection
                    
                    // 预期时间 - 复用PlanFormView的时间选择器
                    expectedTimeSection
                    
                    // 预期小目标 - 改为更大的输入框
                    goalsSection
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            
            // 开始按钮
            startButtonSection
        }
        .onAppear {
            updateExpectedTimeString()
        }
        .onChange(of: expectedMinutes) { _, _ in
            updateExpectedTimeString()
            onSaveDraft()
        }
        .onChange(of: taskDescription) { _, _ in
            onSaveDraft()
        }
        .onChange(of: goals) { _, _ in
            onSaveDraft()
        }
        .onChange(of: selectedPlan) { _, _ in
            onSaveDraft()
        }
    }
    
    private var projectInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("选中项目")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let selectedPlan = selectedPlan {
                HStack(spacing: Spacing.md) {
                    // 使用与 TimeBlockCard 一致的圆球设计
                    projectIconView
                    
                    Text(selectedPlan.project)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(selectedPlan.themeColorSwiftUI.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(selectedPlan.themeColorSwiftUI.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // 未选择项目时的提示
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.secondary)
                    
                    Text("请从左侧选择一个时间块")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var projectIconView: some View {
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
    }
    
    private var taskDescriptionSection: some View {
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
    }
    
    private var expectedTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("预期时间")
                .font(.headline)
                .foregroundColor(.primary)
            
            PlanTimeAdjuster(totalMinutes: $expectedMinutes)
        }
    }
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("预期目标")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(goals.indices, id: \.self) { index in
                goalInputRow(index: index)
            }
            
            if goals.count < 5 {
                addGoalButton
            }
        }
    }
    
    private func goalInputRow(index: Int) -> some View {
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
                    onSaveDraft()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var addGoalButton: some View {
        Button(action: {
            goals.append("")
            onSaveDraft()
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
    
    private var startButtonSection: some View {
        VStack {
            Button(action: {
                // 开始任务前清除草稿
                // TaskDraftManager.shared.clearDraft()
                onStart()
            }) {
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
    
    private func updateExpectedTimeString() {
        expectedTime = expectedMinutes.formattedAsTime()
    }
    
    private func restoreDraft() {
        guard let draft = TaskDraftManager.shared.loadDraft() else { return }
        
        if let planID = draft.selectedPlanID {
            selectedPlan = planViewModel.currentPlanItems.first { $0.id == planID }
        } else {
            selectedPlan = nil
        }
        
        taskDescription = draft.taskDescription
        expectedTime = draft.expectedTime
        goals = draft.goals.isEmpty ? [""] : draft.goals
    }
    
    private func clearForm() {
        selectedPlan = nil
        taskDescription = ""
        expectedTime = "30分钟"
        expectedMinutes = 30
        goals = [""]
        
        // TaskDraftManager.shared.clearDraft()
    }
}

#Preview {
    TaskSelectionView(
        selectedPlan: .constant(nil),
        taskDescription: .constant(""),
        expectedTime: .constant(""),
        goals: .constant([""]),
        onBack: {},
        onStart: {}
    )
    .environmentObject(SessionViewModel())
    .environmentObject(PlanViewModel())
}

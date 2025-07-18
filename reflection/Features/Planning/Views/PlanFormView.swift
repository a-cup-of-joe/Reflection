//
//  PlanFormView.swift
//  reflection
//
//  Created by linan on 2025/7/12.
//

import SwiftUI

struct PlanFormView: View {
    enum Mode {
        case create
        case edit(PlanItem)
    }
    
    let mode: Mode
    @EnvironmentObject var planViewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String
    @State private var totalMinutes: Int
    @State private var selectedThemeColor: String
    @State private var meaning: String
    @State private var targets: [(DateRange, String)] = []
    @State private var archievedTargets: [DateRange: String] = [:]
    @State private var showArchivedTemplate: Bool = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            self._projectName = State(initialValue: "")
            self._totalMinutes = State(initialValue: 30)
            self._selectedThemeColor = State(initialValue: "#00CE4A")
            self._meaning = State(initialValue: "")
            self._targets = State(initialValue: []) // 初始无目标
            self._archievedTargets = State(initialValue: [:])
        case .edit(let plan):
            self._projectName = State(initialValue: plan.project)
            self._totalMinutes = State(initialValue: Int(plan.plannedTime / 60))
            self._selectedThemeColor = State(initialValue: plan.themeColor)
            self._meaning = State(initialValue: plan.meaning)
            self._targets = State(initialValue: plan.targets.map { ($0.key, $0.value) })
            self._archievedTargets = State(initialValue: plan.archievedTargets)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏 + 操作按钮
            HStack(alignment: .center, spacing: 0) {
                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                headerActionButtons
            }
            .padding(Spacing.md)
            .background(Color.appBackground)

            // 表单内容可滚动
            ScrollView {
                VStack(spacing: Spacing.md) {
                    formFields
                }
                .padding(Spacing.md)
                .background(Color.appBackground)
            }
        }
        .frame(width: 450, height: frameHeight)
        .background(Color.appBackground)
        .onTapGesture {
            // 点击空白区域时清除焦点
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onKeyPress(.escape) {
            // ESC键关闭表单
            dismiss()
            return .handled
        }
        .confirmationDialog("确认保存", isPresented: $showingSaveConfirmation) {
            Button("保存", action: savePlan)
        }
        .confirmationDialog("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive, action: deletePlan)
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var titleText: String {
        switch mode {
        case .create: return "新建时间段"
        case .edit: return "编辑时间段"
        }
    }
    
    private var frameHeight: CGFloat {
        switch mode {
        case .create: return 460
        case .edit: return 480
        }
    }
    
    private var primaryButtonText: String {
        switch mode {
        case .create: return "创建"
        case .edit: return "保存"
        }
    }
    
    // MARK: - View Components
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            PlanFormField(label: "名称") {
                textFieldView
            }

            PlanFormField(label: "颜色") {
                PlanColorPicker(selectedColor: $selectedThemeColor)
            }

            PlanFormField(label: "时间") {
                PlanTimeAdjuster(totalMinutes: $totalMinutes)
            }

            PlanFormField(label: "意义") {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(Color.borderGray, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(Color.white)
                        )
                        .frame(height: 48)
                    TextEditor(text: $meaning)
                        .font(.body)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 6)
                        .background(Color.clear)
                        .cornerRadius(CornerRadius.small)
                        .frame(height: 48)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: 4) {
                    Text("目标")
                        .font(.subheadline)
                        .foregroundColor(.secondaryGray)
                        .frame(width: 60, alignment: .leading)
                    if targets.isEmpty {
                        Button(action: {
                            targets.append((DateRange(), ""))
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.primaryGreen)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if !archievedTargets.isEmpty {
                            Button(action: {
                                withAnimation {
                                    showArchivedTemplate.toggle()
                                }
                            }) {
                                Image(systemName: "archivebox")
                                    .foregroundColor(.secondaryGray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                if !targets.isEmpty {
                    ForEach(targets.indices, id: \ .self) { index in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: 4) {
                                    DatePicker("开始", selection: Binding(
                                        get: { targets[index].0.start },
                                        set: { newStart in
                                            let end = targets[index].0.end
                                            targets[index].0 = DateRange(start: newStart, end: end)
                                        }
                                    ), displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(width: 110)
                                    DatePicker("结束", selection: Binding(
                                        get: { targets[index].0.end },
                                        set: { newEnd in
                                            let start = targets[index].0.start
                                            targets[index].0 = DateRange(start: start, end: newEnd)
                                        }
                                    ), displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(width: 110)
                                }
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .stroke(Color.borderGray, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                                .fill(Color.white)
                                        )
                                        .frame(minHeight: 64, maxHeight: 64)
                                    TextEditor(text: Binding(
                                        get: { targets[index].1 },
                                        set: { targets[index].1 = $0 }
                                    ))
                                        .font(.body)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, 10)
                                        .background(Color.clear)
                                        .cornerRadius(CornerRadius.small)
                                        .frame(minWidth: 120, minHeight: 64, maxHeight: 64, alignment: .top)
                                }
                                VStack(spacing: 6) {
                                    if case .edit = mode, !targets[index].1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Button(action: {
                                            // 归档目标到 archievedTargets
                                            let archived = targets[index]
                                            if archievedTargets[archived.0] == nil {
                                                archievedTargets[archived.0] = archived.1
                                            }
                                            targets.remove(at: index)
                                        }) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    Button(action: {
                                        targets.remove(at: index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                }

                if !targets.isEmpty && targets.count < 5 {
                    HStack(spacing: 4) {
                        Button(action: {
                            targets.append((DateRange(), ""))
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.primaryGreen)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if !archievedTargets.isEmpty {
                            Button(action: {
                                withAnimation {
                                    showArchivedTemplate.toggle()
                                }
                            }) {
                                Image(systemName: "archivebox")
                                    .foregroundColor(.secondaryGray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .offset(y: -10)
                    .offset(x: 7)
                }

                // 展示已归档目标
                if !archievedTargets.isEmpty && showArchivedTemplate {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("已归档目标")
                            .font(.footnote)
                            .foregroundColor(.secondaryGray)
                        ForEach(Array(archievedTargets.keys), id: \.self) { key in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(key.start, formatter: dateFormatter) ~ \(key.end, formatter: dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.secondaryGray)
                                }
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .stroke(Color.borderGray, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                        .frame(minHeight: 32, maxHeight: 32)
                                    Text(archievedTargets[key] ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondaryGray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                }
                                Spacer()
                                VStack(spacing: 6) {
                                    Button(action: {
                                        // 恢复归档目标到 targets
                                        if let value = archievedTargets[key] {
                                            targets.append((key, value))
                                            archievedTargets.removeValue(forKey: key)
                                        }
                                    }) {
                                        Image(systemName: "arrow.uturn.left")
                                            .foregroundColor(.primaryGreen)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    Button(action: {
                                        // 永久删除归档目标
                                        archievedTargets.removeValue(forKey: key)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var textFieldView: some View {
        switch mode {
        case .create:
            return AnyView(
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
            )
        case .edit:
            return AnyView(
                TextField("时间段名称", text: $projectName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            )
        }
    }
    
    // 表头操作按钮
    private var headerActionButtons: some View {
        HStack(spacing: Spacing.sm) {
            if case .edit = mode {
                Button("删除") { showingDeleteConfirmation = true }
                    .buttonStyle(SmallRedButtonStyle())
            }
            Spacer().frame(width: 16)
            Button("取消", action: dismiss.callAsFunction)
                .buttonStyle(SmallSecondaryButtonStyle())

            Button(primaryButtonText) {
                switch mode {
                case .create: createPlan()
                case .edit: showingSaveConfirmation = true
                }
            }
            .buttonStyle(SmallButtonStyle())
            .disabled(projectName.isEmpty)
        }
    }
    
    // MARK: - Actions
    
    private func createPlan() {
        // 确保所有正在编辑的时间字段都被提交
        commitPendingTimeEdits()

        // 等待焦点失去和数据更新完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showError("请输入时间段名称")
                return
            }

            guard totalMinutes > 0 else {
                showError("计划时间必须大于0")
                return
            }

            // 只保存有内容的targets
            let filteredTargets = targets.filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let targetsDict = Dictionary(uniqueKeysWithValues: filteredTargets)
            // 只保存有内容的archievedTargets
            let archievedDict = archievedTargets.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            planViewModel.addPlanItem(
                project: projectName,
                plannedTime: TimeInterval(totalMinutes * 60),
                themeColor: selectedThemeColor,
                meaning: meaning,
                targets: targetsDict,
                archievedTargets: archievedDict
            )
            dismiss()
        }
    }
    
    private func savePlan() {
        guard case .edit(let plan) = mode else { return }

        // 确保所有正在编辑的时间字段都被提交
        commitPendingTimeEdits()

        // 等待焦点失去和数据更新完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard !projectName.isEmpty else {
                showError("请输入时间段名称")
                return
            }

            guard totalMinutes > 0 else {
                showError("计划时间必须大于0")
                return
            }

            // 只保存有内容的targets
            let filteredTargets = targets.filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let targetsDict = Dictionary(uniqueKeysWithValues: filteredTargets)
            // 只保存有内容的archievedTargets
            let archievedDict = archievedTargets.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            planViewModel.updatePlanItem(
                planItemId: plan.id,
                project: projectName,
                plannedTime: TimeInterval(totalMinutes * 60),
                themeColor: selectedThemeColor,
                meaning: meaning,
                targets: targetsDict,
                archievedTargets: archievedDict
            )
            dismiss()
        }
    }
// MARK: - Date Formatter for Archived Targets

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
    
    private func deletePlan() {
        guard case .edit(let plan) = mode else { return }
        planViewModel.deletePlanItem(planItemId: plan.id)
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func commitPendingTimeEdits() {
        // 清除焦点以触发正在编辑的时间字段的提交
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
}

// MARK: - Reusable Components

struct PlanFormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondaryGray)
                .frame(width: 60, alignment: .leading)
            
            content
        }
    }
}

struct PlanColorPicker: View {
    @Binding var selectedColor: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Color.themeColors, id: \.self) { colorHex in
                PlanColorButton(
                    colorHex: colorHex,
                    isSelected: selectedColor == colorHex
                ) {
                    selectedColor = colorHex
                }
            }
        }
    }
}

struct PlanColorButton: View {
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if Color.isSpecialMaterial(colorHex) {
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
                        .shadow(color: Color.getSpecialMaterialShadow(colorHex)!, radius: 2, x: 0, y: 1)
                } else {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 16, height: 16)
                }
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                    .frame(width: 20, height: 20)
            )
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlanTimeAdjuster: View {
    @Binding var totalMinutes: Int
    @State private var isEditingHours = false
    @State private var isEditingMinutes = false
    @State private var hoursText: String = ""
    @State private var minutesText: String = ""
    @FocusState private var hoursFieldFocused: Bool
    @FocusState private var minutesFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: { adjustTime(-15) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.secondaryGray)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack(spacing: 4) {
                // Hours display/input
                Group {
                    if isEditingHours {
                        TextField("", text: $hoursText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 30)
                            .multilineTextAlignment(.center)
                            .focused($hoursFieldFocused)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            )
                            .onSubmit {
                                commitHoursEdit()
                            }
                            .onChange(of: hoursText) { _, newValue in
                                validateHoursInput(newValue)
                            }
                            .onKeyPress(.escape) {
                                // ESC键取消编辑
                                isEditingHours = false
                                hoursFieldFocused = false
                                updateDisplayValues()
                                return .handled
                            }
                    } else {
                        Text(displayHours)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 30)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .onTapGesture {
                                startEditingHours()
                            }
                    }
                }
                
                Text("h")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryGray)
                
                // Minutes display/input
                Group {
                    if isEditingMinutes {
                        TextField("", text: $minutesText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 30)
                            .multilineTextAlignment(.center)
                            .focused($minutesFieldFocused)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            )
                            .onSubmit {
                                commitMinutesEdit()
                            }
                            .onChange(of: minutesText) { _, newValue in
                                validateMinutesInput(newValue)
                            }
                            .onKeyPress(.escape) {
                                // ESC键取消编辑
                                isEditingMinutes = false
                                minutesFieldFocused = false
                                updateDisplayValues()
                                return .handled
                            }
                    } else {
                        Text(displayMinutes)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 30)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .onTapGesture {
                                startEditingMinutes()
                            }
                    }
                }
                
                Text("min")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryGray)
            }
            
            Button(action: { adjustTime(15) }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.secondaryGray)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            updateDisplayValues()
        }
        .onChange(of: totalMinutes) { _, _ in
            updateDisplayValues()
        }
        .onChange(of: hoursFieldFocused) { _, isFocused in
            if !isFocused && isEditingHours {
                commitHoursEdit()
            }
        }
        .onChange(of: minutesFieldFocused) { _, isFocused in
            if !isFocused && isEditingMinutes {
                commitMinutesEdit()
            }
        }
    }
    
    private var displayHours: String {
        String(format: "%02d", totalMinutes / 60)
    }
    
    private var displayMinutes: String {
        String(format: "%02d", totalMinutes % 60)
    }
    
    private func adjustTime(_ minutes: Int) {
        let newTotal = totalMinutes + minutes
        if newTotal >= 15 && newTotal <= 480 {
            totalMinutes = newTotal
        }
    }
    
    private func updateDisplayValues() {
        // 这个方法现在只是确保状态一致，实际显示通过计算属性处理
    }
    
    private func startEditingHours() {
        hoursText = String(totalMinutes / 60)
        isEditingHours = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            hoursFieldFocused = true
        }
    }
    
    private func startEditingMinutes() {
        minutesText = String(totalMinutes % 60)
        isEditingMinutes = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            minutesFieldFocused = true
        }
    }
    
    private func commitHoursEdit() {
        if let hours = Int(hoursText.isEmpty ? "0" : hoursText) {
            let clampedH = min(max(hours, 0), 7)
            let newTotal = clampedH * 60 + (totalMinutes % 60)
            if newTotal >= 15 && newTotal <= 480 {
                totalMinutes = newTotal
            }
        }
        isEditingHours = false
        hoursFieldFocused = false
    }
    
    private func commitMinutesEdit() {
        if let minutes = Int(minutesText.isEmpty ? "0" : minutesText) {
            let clampedM = min(max(minutes, 0), 59)
            let newTotal = (totalMinutes / 60) * 60 + clampedM
            if newTotal >= 15 && newTotal <= 480 {
                totalMinutes = newTotal
            }
        }
        isEditingMinutes = false
        minutesFieldFocused = false
    }
    
    private func validateHoursInput(_ newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count <= 2 {
            hoursText = filtered
        }
    }
    
    private func validateMinutesInput(_ newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count <= 2 {
            minutesText = filtered
        }
    }
}

// MARK: - Previews

#Preview("Create Plan") {
    PlanFormView(mode: .create)
        .environmentObject(PlanViewModel())
}

#Preview("Edit Plan") {
    PlanFormView(mode: .edit(PlanItem(
        project: "示例项目",
        plannedTime: 1800,
        themeColor: "#00CE4A"
    )))
    .environmentObject(PlanViewModel())
}

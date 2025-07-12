//
//  PlanView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI
import AppKit

struct PlanView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @State private var showingAddTimeBar = false
    @State private var selectedTimeBar: TimeBar?
    @State private var draggedIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var targetIndex: Int? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 标题
                    HStack {
                        Text("Time Planner")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // 时间条列表
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(planViewModel.getTimeBars().indices, id: \.self) { index in
                            let timeBar = planViewModel.getTimeBars()[index]
                            DraggableTimeBar(
                                timeBarID: timeBar.id,
                                index: index,
                                totalItems: planViewModel.getTimeBars().count,
                                draggedIndex: $draggedIndex,
                                dragOffset: $dragOffset,
                                targetIndex: $targetIndex,
                                onTap: {
                                    selectedTimeBar = timeBar
                                },
                                onMove: { from, to in
                                    planViewModel.moveTimeBar(fromIndex: from, toIndex: to)
                                }
                            )
                        }
                    }
                    .scrollDisabled(draggedIndex != nil) // 当拖动时禁用滚动
                    .allowsHitTesting(true) // 确保可以响应点击
                    .background(Color.clear) // 明确背景色
                    .clipped() // 限制拖动范围

                    if planViewModel.getTimeBars().isEmpty {
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
                    
            // 悬浮的添加按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddTimeBar = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .sheet(isPresented: $showingAddTimeBar) {
            CreatePlanView()
                .environmentObject(planViewModel)
        }
        .sheet(item: $selectedTimeBar) { timeBar in
            EditPlanView(timeBarID: timeBar.id)
                .environmentObject(planViewModel)
        }
    }
}

// MARK: - TimeBarView
struct TimeBarView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    let timeBarID: UUID
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    // Computed properties to avoid property initialization issues
    var plannedTime: TimeInterval {
        planViewModel.getPlannedTime(for: timeBarID)
    }
    
    var colorHex: String {
        planViewModel.getColorHex(for: timeBarID)
    }
    
    var name: String {
        planViewModel.getActivityName(for: timeBarID)
    }
    
    var formatTime: String {
        planViewModel.getFormattedPlannedTime(for: timeBarID)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 主要内容区域 - 只有这部分可以被拖动
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(formatTime)
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
                    if Color.isSpecialMaterial(colorHex) {
                        // 特殊材质效果
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color.getSpecialMaterialGradient(colorHex)!)
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
                            .shadow(color: Color.getSpecialMaterialShadow(colorHex)!, radius: isHovered ? 6 : 3, x: 0, y: 2)
                            .shadow(color: Color.black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: 4)
                    } else {
                        // 普通颜色效果
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(planViewModel.getColor(for: timeBarID))
                            .shadow(color: planViewModel.getColor(for: timeBarID).opacity(0.3), radius: isHovered ? 4 : 2, x: 0, y: 2)
                    }
                }
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onTapGesture {
                onTap()
            }
            .onHover { hovering in
                isHovered = hovering
            }
            
                Spacer()
            }
        }
        .frame(height: 44)
    }
    
    private func calculateBarWidth(containerWidth: CGFloat) -> CGFloat {
        let totalMinutes = plannedTime / 60
        let totalHours = totalMinutes / 60
        
        // 确保最小容器宽度，避免除零错误
        let safeContainerWidth = max(containerWidth, 200)
        

        let baseWidth = safeContainerWidth * 0.1
        
        // 最大宽度：85%的容器宽度
        let maxWidth = safeContainerWidth * 0.7
        
        // 参考时长：2小时对应最大宽度
        let referenceHours: CGFloat = 3
        
        // 使用对数函数优化长度映射，让差异更加明显
        let logScale = log(1 + totalHours) / log(1 + referenceHours)
        let proportionalWidth = baseWidth + (maxWidth - baseWidth) * logScale
        
        // 设置最小宽度：30%的容器宽度
        let minWidth = safeContainerWidth * 0.1
        
        return max(minWidth, min(proportionalWidth, maxWidth))
    }
}

// MARK: - DraggableTimeBar
struct DraggableTimeBar: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    let timeBarID: UUID
    let index: Int
    let totalItems: Int
    @Binding var draggedIndex: Int?
    @Binding var dragOffset: CGFloat
    @Binding var targetIndex: Int?
    let onTap: () -> Void
    let onMove: (Int, Int) -> Void
    
    @State private var localDragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isHovered = false
    
    // 添加窗口状态管理
    @State private var windowIsMovable = true
    @State private var windowMovableChanged = false
    
    private var isBeingDragged: Bool {
        draggedIndex == index
    }
    
    // 精确的让位逻辑
    private var shouldShift: Bool {
        guard let draggedIndex = draggedIndex, 
              let targetIndex = targetIndex,
              draggedIndex != index else { return false }
        
        // 只有在拖动路径上的元素才需要让位
        if draggedIndex < targetIndex {
            // 向下拖动：原位置到目标位置之间的元素向上让位
            return index > draggedIndex && index <= targetIndex
        } else if draggedIndex > targetIndex {
            // 向上拖动：目标位置到原位置之间的元素向下让位
            return index >= targetIndex && index < draggedIndex
        }
        
        return false
    }
    
    private var shiftOffset: CGFloat {
        guard shouldShift,
              let draggedIndex = draggedIndex,
              let targetIndex = targetIndex else { return 0 }
        
        let itemHeight: CGFloat = 44 + Spacing.md
        
        // 根据拖动方向决定让位方向
        if draggedIndex < targetIndex {
            // 向下拖动，上方元素向上让位
            return -itemHeight
        } else {
            // 向上拖动，下方元素向下让位
            return itemHeight
        }
    }
    
    // 计算目标位置 - 修复精度问题
    private func calculateTargetIndex(dragOffset: CGFloat) -> Int {
        guard draggedIndex == index else { return index }
        
        let itemHeight: CGFloat = 44 + Spacing.md
        let threshold = itemHeight * 0.5 // 50% 阈值，确保对称
        
        var newIndex = index
        
        if dragOffset > threshold {
            // 向下拖动
            newIndex = index + Int((dragOffset + threshold) / itemHeight)
        } else if dragOffset < -threshold {
            // 向上拖动
            newIndex = index + Int((dragOffset - threshold) / itemHeight)
        }
        
        return max(0, min(totalItems - 1, newIndex))
    }
    
    var body: some View {
        TimeBarView(timeBarID: timeBarID, onTap: {
            if !isDragging {
                onTap()
            }
        })
        .offset(y: isBeingDragged ? localDragOffset.height : shiftOffset)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .zIndex(isDragging ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shiftOffset)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        draggedIndex = index
                        
                        // 禁用窗口拖动
                        if let window = NSApp.keyWindow {
                            windowIsMovable = window.isMovable
                            window.isMovable = false
                            windowMovableChanged = true
                        }
                    }
                    
                    // 只允许垂直拖动
                    let verticalTranslation = value.translation.height
                    localDragOffset = CGSize(width: 0, height: verticalTranslation)
                    dragOffset = verticalTranslation
                    
                    // 实时计算目标位置
                    let newTargetIndex = calculateTargetIndex(dragOffset: verticalTranslation)
                    if newTargetIndex != targetIndex {
                        targetIndex = newTargetIndex
                    }
                }
                .onEnded { value in
                    let finalTargetIndex = calculateTargetIndex(dragOffset: value.translation.height)
                    let shouldMove = abs(value.translation.height) > 20 && finalTargetIndex != index
                    
                    if shouldMove {
                        // 延迟执行移动和状态重置，让动画完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onMove(index, finalTargetIndex)
                            
                            // 在移动完成后重置状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                resetDragState()
                            }
                        }
                    } else {
                        // 如果不需要移动，立即重置状态
                        resetDragState()
                    }
                }
        )
    }
    
    private func resetDragState() {
        // 恢复窗口拖动能力
        if windowMovableChanged {
            NSApp.windows.forEach { window in
                if !window.isMovable {
                    window.isMovable = windowIsMovable
                }
            }
            windowMovableChanged = false
        }
        
        // 重置拖动状态
        isDragging = false
        draggedIndex = nil
        dragOffset = 0
        targetIndex = nil
        localDragOffset = .zero
    }
}

// MARK: - EditPlanView
struct EditPlanView: View {
    let timeBarID: UUID
    @EnvironmentObject var planViewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String
    @State private var plannedTime: TimeInterval
    @State private var totalMinutes: Int
    @State private var selectedThemeColor: String
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(timeBarID: UUID) {
        self.timeBarID = timeBarID
        self._projectName = State(initialValue: planViewModel.getActivityName(for: timeBarID))
        self._plannedTime = State(initialValue: planViewModel.getPlannedTime(for: timeBarID))
        self._totalMinutes = State(initialValue: Int(planViewModel.getPlannedTime(for: timeBarID) / 60))
        self._selectedThemeColor = State(initialValue: planViewModel.getColorHex(for: timeBarID))
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
        
        planViewModel.updateTimeBar(
            timBarID: timeBarID,
            name: projectName,
            plannedTime: TimeInterval(totalMinutes * 60),
            themeColor: selectedThemeColor
        )
        dismiss()
    }
    
    private func deletePlan() {
        planViewModel.deleteTimeBar(timBarID: timeBarID)
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
//
//  PlanView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI
import AppKit

// MARK: - DragState
struct DragState {
    var draggedIndex: Int?
    var targetIndex: Int?
    var isDragging: Bool = false
    var dragOffset: CGSize = .zero
    
    mutating func reset() {
        draggedIndex = nil
        targetIndex = nil
        isDragging = false
        dragOffset = .zero
    }
}

struct PlanView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @State private var showingAddPlan = false
    @State private var selectedPlan: PlanItem?
    @State private var dragState = DragState()
    @State private var showingPlanManager = false
    @State private var isEditingTitle = false
    @State private var editingTitle = ""
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 标题
                    HStack {
                        Spacer()
                        
                        if isEditingTitle {
                            TextField("", text: $editingTitle)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .focused($isTitleFocused)
                                .onSubmit {
                                    saveTitleEdit()
                                }
                                .onAppear {
                                    isTitleFocused = true
                                }
                        } else {
                            Text(planViewModel.currentPlan?.name ?? "Time Planner")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .onTapGesture(count: 2) {
                                    startTitleEditing()
                                }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, Spacing.xl)
                    .onTapGesture {
                        if isEditingTitle {
                            saveTitleEdit()
                        }
                    }
                    
                    // 时间条列表
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(planViewModel.currentPlanItems, id: \.id) { plan in
                            DraggableTimeBar(
                                plan: plan,
                                totalItems: planViewModel.currentPlanItems.count,
                                dragState: $dragState,
                                onTap: { selectedPlan = plan },
                                onMove: planViewModel.movePlanItem
                            )
                        }
                    }
                    .scrollDisabled(dragState.draggedIndex != nil)
                    
                    if planViewModel.currentPlanItems.isEmpty {
                        EmptyStateView()
                    }
                    
                    Spacer(minLength: Spacing.xl)
                }
            }
            .containerStyle()
                    
            // 悬浮按钮组
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        // 计划管理按钮
                        FloatingActionButton(
                            icon: "folder",
                            backgroundColor: .secondary
                        ) { 
                            showingPlanManager = true 
                        }
                        
                        // 添加任务按钮
                        FloatingActionButton(
                            icon: "plus"
                        ) { 
                            showingAddPlan = true 
                        }
                    }
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .sheet(isPresented: $showingAddPlan) {
            PlanFormView(mode: .create)
                .environmentObject(planViewModel)
        }
        .sheet(item: $selectedPlan) { plan in
            PlanFormView(mode: .edit(plan))
                .environmentObject(planViewModel)
        }
        .sheet(isPresented: $showingPlanManager) {
            PlanManagerView()
                .environmentObject(planViewModel)
        }
        .onChange(of: isTitleFocused) { _, newValue in
            if !newValue && isEditingTitle {
                saveTitleEdit()
            }
        }
    }
    
    // MARK: - Title Editing Methods
    private func startTitleEditing() {
        guard let currentPlan = planViewModel.currentPlan else { return }
        editingTitle = currentPlan.name
        isEditingTitle = true
    }
    
    private func saveTitleEdit() {
        let trimmedTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            planViewModel.updatePlanName(trimmedTitle)
        }
        isEditingTitle = false
        isTitleFocused = false
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    var body: some View {
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
}

// MARK: - FloatingActionButton
struct FloatingActionButton: View {
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    init(icon: String = "plus", backgroundColor: Color = .accentColor, action: @escaping () -> Void) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
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
                // 添加左侧间距使 TimeBars 向右偏移
                Spacer()
                    .frame(width: Spacing.md)
                
                // 主要内容区域 - 只有这部分可以被拖动
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
                }
                .frame(width: calculateBarWidth(containerWidth: geometry.size.width), height: 44)
                .background(createBackground())
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
                .onTapGesture(perform: onTap)
                .onHover { isHovered = $0 }
            
                Spacer()
            }
        }
        .frame(height: 44)
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
                            lineWidth: 1
                        )
                )
                .shadow(color: plan.specialMaterialShadow!, radius: isHovered ? 6 : 3, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(plan.themeColorSwiftUI)
                .shadow(color: plan.themeColorSwiftUI.opacity(0.3), radius: isHovered ? 4 : 2, x: 0, y: 2)
        }
    }
    

    
    private func calculateBarWidth(containerWidth: CGFloat) -> CGFloat {
        let safeWidth = max(containerWidth, 200)
        let baseWidth = safeWidth * 0.2
        let maxWidth = safeWidth * 0.85
        let totalHours = plan.plannedTime / 3600
        let logScale = log(1 + totalHours) / log(1 + 3) // 3 hours reference
        let proportionalWidth = baseWidth + (maxWidth - baseWidth) * logScale
        return max(baseWidth, min(proportionalWidth, maxWidth))
    }
}

// MARK: - DraggableTimeBar
struct DraggableTimeBar: View {
    let plan: PlanItem
    // var index: Int
    let totalItems: Int
    @EnvironmentObject var planViewModel: PlanViewModel
    @Binding var dragState: DragState
    let onTap: () -> Void
    let onMove: (Int, Int) -> Void
    
    private let itemHeight: CGFloat = 44 + 16 // TimeBar高度 + spacing
    
    // index改造为PlanItem的索引
    var index: Int {
        planViewModel.indexOfPlanItem(withId: plan.id) ?? 0
    }
    // 计算当前元素是否应该移动让位
    private var shouldShift: Bool {
        guard let draggedIndex = dragState.draggedIndex,
              let targetIndex = dragState.targetIndex,
              draggedIndex != index else { return false }
        
        // 如果拖拽的元素要移动到这个位置，或者要经过这个位置
        if draggedIndex < targetIndex {
            // 向下拖拽：被拖拽元素下方的元素向上移动
            return index > draggedIndex && index <= targetIndex
        } else {
            // 向上拖拽：被拖拽元素上方的元素向下移动
            return index >= targetIndex && index < draggedIndex
        }
    }
    
    // 计算移动偏移量
    private var shiftOffset: CGFloat {
        guard shouldShift else { return 0 }
        
        if let draggedIndex = dragState.draggedIndex, let targetIndex = dragState.targetIndex {
            return draggedIndex < targetIndex ? -itemHeight : itemHeight
        }
        return 0
    }
    
    // 基于拖拽距离计算目标位置
    private func calculateTargetIndex(from dragOffset: CGFloat) -> Int {
        // 计算拖拽了多少个元素的高度
        let draggedItems = Int(round(dragOffset / itemHeight))
        let newIndex = index + draggedItems
        
        // 确保在有效范围内
        return max(0, min(totalItems - 1, newIndex))
    }
    
    var body: some View {
        TimeBarView(plan: plan, onTap: { 
            if dragState.draggedIndex != index { onTap() } 
        })
        .offset(y: dragState.draggedIndex == index ? dragState.dragOffset.height : shiftOffset)
        .scaleEffect(dragState.draggedIndex == index ? 1.05 : 1.0)
        .zIndex(dragState.draggedIndex == index ? 1000 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: shiftOffset)
        .animation(.easeInOut(duration: 0.2), value: dragState.draggedIndex == index)
        // 监听拖拽状态变化
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if dragState.draggedIndex != index {
                        startDragging()
                    }
                    
                    dragState.dragOffset = value.translation
                    
                    // 实时计算目标位置
                    let newTargetIndex = calculateTargetIndex(from: value.translation.height)
                    if newTargetIndex != dragState.targetIndex {
                        dragState.targetIndex = newTargetIndex
                    }
                }
                .onEnded { value in
                    let finalTargetIndex = calculateTargetIndex(from: value.translation.height)
                    let threshold = itemHeight * 0.3
                    
                    if abs(value.translation.height) > threshold && finalTargetIndex != index {
                        let originalIndex = index
                        
                        onMove(originalIndex, finalTargetIndex)
                        dragState.draggedIndex = finalTargetIndex
                        let targetOffset = dragState.dragOffset.height - CGFloat(finalTargetIndex - originalIndex) * itemHeight
                        dragState.dragOffset = CGSize(width: 0, height: targetOffset)
                    }
                    endDragging()
                }
        )
    }
    
    private func startDragging() {
        dragState.isDragging = true
        dragState.draggedIndex = index
        dragState.targetIndex = index
    }
    
    private func endDragging() {
        dragState.isDragging = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dragState.reset()
        }
    }
}

#Preview {
    PlanView()
        .environmentObject(PlanViewModel())
}
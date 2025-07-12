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
    
    mutating func reset() {
        draggedIndex = nil
        targetIndex = nil
        isDragging = false
    }
}



struct PlanView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @State private var showingAddPlan = false
    @State private var selectedPlan: PlanItem?
    @State private var dragState = DragState()
    
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
                        ForEach(planViewModel.plans.indices, id: \.self) { index in
                            let plan = planViewModel.plans[index]
                            DraggableTimeBar(
                                plan: plan,
                                index: index,
                                totalItems: planViewModel.plans.count,
                                dragState: $dragState,
                                onTap: { selectedPlan = plan },
                                onMove: planViewModel.movePlan
                            )
                        }
                    }
                    .scrollDisabled(dragState.draggedIndex != nil)
                    
                    if planViewModel.plans.isEmpty {
                        EmptyStateView()
                    }
                    
                    Spacer(minLength: Spacing.xl)
                }
            }
            .containerStyle()
                    
            // 悬浮添加按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton { showingAddPlan = true }
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
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
        let baseWidth = safeWidth * 0.1
        let maxWidth = safeWidth * 0.7
        let totalHours = plan.plannedTime / 3600
        let logScale = log(1 + totalHours) / log(1 + 3) // 3 hours reference
        let proportionalWidth = baseWidth + (maxWidth - baseWidth) * logScale
        return max(safeWidth * 0.1, min(proportionalWidth, maxWidth))
    }
}

// MARK: - DraggableTimeBar
struct DraggableTimeBar: View {
    let plan: PlanItem
    let index: Int
    let totalItems: Int
    @Binding var dragState: DragState
    let onTap: () -> Void
    let onMove: (Int, Int) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    private let itemHeight: CGFloat = 44 + 16 // TimeBar高度 + spacing
    
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
            if !isDragging { onTap() } 
        })
        .offset(y: dragState.draggedIndex == index ? dragOffset.height : shiftOffset)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .zIndex(isDragging ? 1000 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: shiftOffset)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if !isDragging {
                        startDragging()
                    }
                    
                    dragOffset = value.translation
                    
                    // 实时计算目标位置
                    let newTargetIndex = calculateTargetIndex(from: value.translation.height)
                    if newTargetIndex != dragState.targetIndex {
                        print("📍 [Index \(index)] Target changed from \(dragState.targetIndex ?? -1) to \(newTargetIndex)")
                        dragState.targetIndex = newTargetIndex
                    }
                }
                .onEnded { value in
                    let finalTargetIndex = calculateTargetIndex(from: value.translation.height)
                    let threshold = itemHeight * 0.3
                    
                    // 只有拖拽距离足够大且目标位置不同时才移动
                    if abs(value.translation.height) > threshold && finalTargetIndex != index {
                        onMove(index, finalTargetIndex)
                    }
                    
                    endDragging()
                }
        )
    }
    
    private func startDragging() {
        isDragging = true
        dragState.isDragging = true
        dragState.draggedIndex = index
        dragState.targetIndex = index
    }
    
    private func endDragging() {
        isDragging = false
        dragOffset = .zero
        
        // 短暂延迟后重置状态，让动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dragState.reset()
        }
    }
}

#Preview {
    PlanView()
        .environmentObject(PlanViewModel())
}
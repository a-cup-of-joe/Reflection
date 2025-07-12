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
    var dragOffset: CGFloat = 0
    var targetIndex: Int?
    
    mutating func reset() {
        draggedIndex = nil
        dragOffset = 0
        targetIndex = nil
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
    
    @State private var localDragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var windowState = WindowState()
    
    private var isBeingDragged: Bool { dragState.draggedIndex == index }
    private var itemHeight: CGFloat { 44 + Spacing.md }
    
    // MARK: - WindowState
    struct WindowState {
        var isMovable = true
        var hasChanged = false
    }
    
    private var shouldShift: Bool {
        guard let draggedIndex = dragState.draggedIndex,
              let targetIndex = dragState.targetIndex,
              draggedIndex != index else { return false }
        
        if draggedIndex < targetIndex {
            return index > draggedIndex && index <= targetIndex
        } else {
            return index >= targetIndex && index < draggedIndex
        }
    }
    
    private var shiftOffset: CGFloat {
        guard shouldShift,
              let draggedIndex = dragState.draggedIndex,
              let targetIndex = dragState.targetIndex else { return 0 }
        
        return draggedIndex < targetIndex ? -itemHeight : itemHeight
    }
    
    private func calculateTargetIndex(dragOffset: CGFloat) -> Int {
        guard dragState.draggedIndex == index else { return index }
        
        let threshold = itemHeight * 0.5
        var newIndex = index
        
        if dragOffset > threshold {
            newIndex = index + Int((dragOffset + threshold) / itemHeight)
        } else if dragOffset < -threshold {
            newIndex = index + Int((dragOffset - threshold) / itemHeight)
        }
        
        return max(0, min(totalItems - 1, newIndex))
    }
    
    var body: some View {
        TimeBarView(plan: plan, onTap: { if !isDragging { onTap() } })
            .offset(y: isBeingDragged ? localDragOffset.height : shiftOffset)
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .zIndex(isDragging ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shiftOffset)
            .gesture(dragGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                if !isDragging {
                    startDragging()
                }
                
                let verticalTranslation = value.translation.height
                localDragOffset = CGSize(width: 0, height: verticalTranslation)
                dragState.dragOffset = verticalTranslation
                
                let newTargetIndex = calculateTargetIndex(dragOffset: verticalTranslation)
                if newTargetIndex != dragState.targetIndex {
                    dragState.targetIndex = newTargetIndex
                }
            }
            .onEnded { value in
                let finalTargetIndex = calculateTargetIndex(dragOffset: value.translation.height)
                let shouldMove = abs(value.translation.height) > 20 && finalTargetIndex != index
                
                if shouldMove {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onMove(index, finalTargetIndex)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            resetDragState()
                        }
                    }
                } else {
                    resetDragState()
                }
            }
    }
    
    private func startDragging() {
        isDragging = true
        dragState.draggedIndex = index
        
        if let window = NSApp.keyWindow {
            windowState.isMovable = window.isMovable
            window.isMovable = false
            windowState.hasChanged = true
        }
    }
    
    private func resetDragState() {
        if windowState.hasChanged {
            NSApp.windows.forEach { window in
                if !window.isMovable {
                    window.isMovable = windowState.isMovable
                }
            }
            windowState.hasChanged = false
        }
        
        isDragging = false
        dragState.reset()
        localDragOffset = .zero
    }
}

#Preview {
    PlanView()
        .environmentObject(PlanViewModel())
}
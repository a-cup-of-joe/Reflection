//
//  PlanManagerView.swift
//  reflection
//
//  Created by linan on 2025/7/14.
//

import SwiftUI

struct PlanManagerView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreatePlan = false
    @State private var newPlanName = ""
    @State private var planToDelete: Plan?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("计划管理")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 创建按钮
                Button(action: { showingCreatePlan = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("新建")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color(hex: "#00CE4A"))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Color(hex: "#00CE4A"))
                .font(.system(size: 14, weight: .medium))
            }
            .padding(Spacing.md)
            .background(Color.white)
            
            // 计划列表
            if planViewModel.plans.isEmpty {
                EmptyPlanStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(planViewModel.plans) { plan in
                            PlanRowView(
                                plan: plan,
                                isSelected: planViewModel.currentPlan?.id == plan.id,
                                onSelect: { 
                                    planViewModel.switchToPlan(plan)
                                    dismiss()
                                },
                                onDelete: { 
                                    planToDelete = plan
                                    showingDeleteAlert = true
                                },
                                canDelete: planViewModel.plans.count > 1
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
                .background(Color.white)
            }
        }
        .frame(width: 380, height: 450)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .alert("新建计划", isPresented: $showingCreatePlan) {
            TextField("计划名称", text: $newPlanName)
            Button("取消", role: .cancel) {
                newPlanName = ""
            }
            Button("创建") {
                planViewModel.createNewPlan(name: newPlanName)
                newPlanName = ""
                dismiss()
            }
            .disabled(newPlanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("为您的新计划起一个名字")
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {
                planToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let plan = planToDelete {
                    planViewModel.deletePlan(plan.id)
                }
                planToDelete = nil
            }
        } message: {
            if let plan = planToDelete {
                Text("确定要删除计划 \"\(plan.name)\" 吗？此操作无法撤销。")
            }
        }
    }
}

struct PlanRowView: View {
    let plan: Plan
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let canDelete: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // 左侧：计划信息
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(plan.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? Color(hex: "#00CE4A") : .primary)
                        .lineLimit(1)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#00CE4A"))
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text("\(plan.planItems.count) 项任务")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右侧：时间条缩略图
            PlanThumbnailView(planItems: plan.planItems)
                .frame(width: 80, height: 24)
            
            // 删除按钮
            if isHovered && canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(isSelected ? Color(hex: "#00CE4A").opacity(0.08) : (isHovered ? Color.gray.opacity(0.05) : Color.white))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .stroke(isSelected ? Color(hex: "#00CE4A").opacity(0.3) : Color.borderGray, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct PlanThumbnailView: View {
    let planItems: [PlanItem]
    
    var body: some View {
        HStack(spacing: 1) {
            
                // 显示前4个时间条的缩略图
                ForEach(Array(planItems.prefix(4).enumerated()), id: \.element.id) { index, item in
                    let width = calculateThumbnailWidth(for: item, in: planItems.prefix(4))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.themeColorSwiftUI)
                        .frame(width: width, height: 8)
                        .opacity(0.8)
                
                // 如果还有更多项目，显示省略号
                if planItems.count > 4 {
                    Text("…")
                        .font(.system(size: 6))
                        .foregroundColor(.secondaryGray)
                        .frame(width: 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func calculateThumbnailWidth(for item: PlanItem, in items: ArraySlice<PlanItem>) -> CGFloat {
        let totalTime = items.reduce(0) { $0 + $1.plannedTime }
        guard totalTime > 0 else { return 6 }
        
        let proportion = item.plannedTime / totalTime
        let availableWidth: CGFloat = 80 // 总可用宽度
        let minWidth: CGFloat = 3
        let maxWidth: CGFloat = 25
        
        let calculatedWidth = availableWidth * proportion
        return max(minWidth, min(maxWidth, calculatedWidth))
    }
}

struct EmptyPlanStateView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondaryGray)
                .opacity(0.6)
            
            Text("暂无计划")
                .font(.headline)
                .foregroundColor(.secondaryGray)
            
            Text("点击 + 按钮创建您的第一个计划")
                .font(.body)
                .foregroundColor(.secondaryGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    PlanManagerView()
        .environmentObject(PlanViewModel())
}

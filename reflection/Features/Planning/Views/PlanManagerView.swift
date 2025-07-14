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
    @State private var editingPlan: Plan?
    @State private var editingPlanName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("计划管理")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                
                Divider()
                
                // 计划列表
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(planViewModel.plans) { plan in
                            PlanRowView(
                                plan: plan,
                                isSelected: planViewModel.currentPlan?.id == plan.id,
                                onSelect: { planViewModel.switchToPlan(plan) },
                                onEdit: { 
                                    editingPlan = plan
                                    editingPlanName = plan.name
                                },
                                onDelete: { planViewModel.deletePlan(plan.id) }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }
                
                // 创建新计划按钮
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: { showingCreatePlan = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("创建新计划")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .frame(width: 400, height: 500)
        .alert("创建新计划", isPresented: $showingCreatePlan) {
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
        }
        .alert("编辑计划", isPresented: .constant(editingPlan != nil)) {
            TextField("计划名称", text: $editingPlanName)
            Button("取消", role: .cancel) {
                editingPlan = nil
                editingPlanName = ""
            }
            Button("保存") {
                if let plan = editingPlan {
                    planViewModel.updatePlanName(plan.id, newName: editingPlanName)
                }
                editingPlan = nil
                editingPlanName = ""
            }
            .disabled(editingPlanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct PlanRowView: View {
    let plan: Plan
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(plan.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                
                HStack {
                    Text("\(plan.planItems.count) 项任务")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("修改于 \(plan.lastModified.formatted(.dateTime.month().day().hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isHovered {
                HStack(spacing: Spacing.sm) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { isHovered = $0 }
    }
}

#Preview {
    PlanManagerView()
        .environmentObject(PlanViewModel())
}

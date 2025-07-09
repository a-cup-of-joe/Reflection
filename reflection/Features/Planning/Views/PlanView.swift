//
//  PlanView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct PlanView: View {
    @EnvironmentObject var planViewModel: PlanViewModel
    @State private var showingAddPlan = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // 标题和添加按钮
                HStack {
                    Text("时间分配计划")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddPlan = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .buttonStyle(CircleButtonStyle())
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xl)
                
                // 计划列表
                LazyVStack(spacing: Spacing.md) {
                    ForEach(planViewModel.plans) { plan in
                        PlanItemCard(plan: plan)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                
                if planViewModel.plans.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(.secondaryGray)
                        
                        Text("暂无计划")
                            .font(.headline)
                            .foregroundColor(.secondaryGray)
                        
                        Text("点击上方 + 按钮创建您的第一个计划")
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
        .sheet(isPresented: $showingAddPlan) {
            CreatePlanView()
                .environmentObject(planViewModel)
        }
    }
}

struct PlanItemCard: View {
    let plan: PlanItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // 项目名称
            Text(plan.project)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 时间信息
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("计划时间")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                    
                    Text(plan.plannedTimeFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("实际时间")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                    
                    Text(plan.actualTimeFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 进度圆环
                VStack(spacing: Spacing.xs) {
                    ProgressCircle(progress: plan.completionPercentage, size: 50, lineWidth: 4)
                        .overlay(
                            Text("\(Int(plan.completionPercentage * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryGreen)
                        )
                }
            }
            
            // 时间差异提示
            if abs(plan.timeDifference) > 60 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: plan.timeDifference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(plan.timeDifference > 0 ? .orange : .primaryGreen)
                        .font(.caption)
                    
                    Text(plan.timeDifference > 0 
                         ? "超时 \(TimeFormatters.formatDuration(plan.timeDifference))" 
                         : "提前 \(TimeFormatters.formatDuration(-plan.timeDifference))")
                        .font(.caption)
                        .foregroundColor(plan.timeDifference > 0 ? .orange : .primaryGreen)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(plan.timeDifference > 0 ? Color.orange.opacity(0.1) : Color.primaryGreen.opacity(0.1))
                .cornerRadius(CornerRadius.small)
            }
        }
        .padding(Spacing.lg)
        .cardStyle()
    }
}

#Preview {
    PlanView()
        .environmentObject(PlanViewModel())
}
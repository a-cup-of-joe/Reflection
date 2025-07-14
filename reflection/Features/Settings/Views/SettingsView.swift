//
//  SettingsView.swift
//  reflection
//
//  Created by linan on 2025/7/14.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @State private var showingClearDataAlert = false
    @State private var showingDebugSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            headerView
            
            // 内容区域
            contentView
        }
        .background(Color.appBackground)
        .alert("确认清除所有数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("此操作将永久删除所有计划和会话数据，无法恢复。")
        }
        .sheet(isPresented: $showingDebugSheet) {
            DebugView(sessionViewModel: sessionViewModel)
        }
    }
    
    // MARK: - Private Views
    private var headerView: some View {
        HStack {
            Text("设置")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // 数据管理
                dataManagementSection
                
                // 开发者选项
                if isDebugEnabled {
                    debugSection
                }
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("数据管理")
            
            SettingsCard {
                SettingsRow(
                    icon: "trash",
                    title: "清除所有数据",
                    subtitle: "删除所有计划和会话记录",
                    isDestructive: true
                ) {
                    showingClearDataAlert = true
                }
            }
        }
    }
    
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("开发者选项")
            
            SettingsCard {
                SettingsRow(
                    icon: "hammer",
                    title: "调试模式",
                    subtitle: "查看和编辑Session数据",
                    isDestructive: false
                ) {
                    showingDebugSheet = true
                }
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
    }
    
    // MARK: - Computed Properties
    private var isDebugEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Private Methods
    private func clearAllData() {
        DataManager.shared.clearAllData()
        sessionViewModel.clearAllSessions()
        
        // 可以添加一些反馈，比如toast或者完成提示
    }
}

// MARK: - SettingsCard
struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - SettingsRow
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDestructive: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                // 文本内容
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(titleColor)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryGray)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryGray)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isHovered ? Color.borderGray.opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var iconColor: Color {
        isDestructive ? .red : .primaryGreen
    }
    
    private var titleColor: Color {
        isDestructive ? .red : .black
    }
}

// MARK: - DebugView
struct DebugView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingSession: FocusSession?
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            debugHeaderView
            
            // 内容
            debugContentView
        }
        .background(Color.appBackground)
        .sheet(item: $editingSession) { session in
            SessionEditView(session: session, sessionViewModel: sessionViewModel)
        }
    }
    
    private var debugHeaderView: some View {
        HStack {
            Text("调试模式")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button("完成") {
                dismiss()
            }
            .foregroundColor(.primaryGreen)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
    
    private var debugContentView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(sessionViewModel.sessions) { session in
                    SessionDebugCard(session: session) {
                        editingSession = session
                    }
                }
                
                if sessionViewModel.sessions.isEmpty {
                    Text("暂无Session数据")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryGray)
                        .padding(.top, Spacing.xl)
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - SessionDebugCard
struct SessionDebugCard: View {
    let session: FocusSession
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(session.projectName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button("编辑") {
                    onEdit()
                }
                .font(.system(size: 12))
                .foregroundColor(.primaryGreen)
            }
            
            Text(session.taskDescription)
                .font(.system(size: 12))
                .foregroundColor(.secondaryGray)
            
            HStack {
                Text("开始: \(session.startTime, formatter: debugDateFormatter)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondaryGray)
                
                Spacer()
            }
            
            if let endTime = session.endTime {
                HStack {
                    Text("结束: \(endTime, formatter: debugDateFormatter)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondaryGray)
                    
                    Spacer()
                    
                    Text("时长: \(Int(session.duration / 60))分钟")
                        .font(.system(size: 11))
                        .foregroundColor(.secondaryGray)
                }
            } else {
                Text("进行中...")
                    .font(.system(size: 11))
                    .foregroundColor(.primaryGreen)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.small)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
    
    private var debugDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }
}

// MARK: - SessionEditView
struct SessionEditView: View {
    let session: FocusSession
    let sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String
    @State private var taskDescription: String
    @State private var startTime: Date
    @State private var endTime: Date?
    @State private var hasEndTime: Bool
    
    init(session: FocusSession, sessionViewModel: SessionViewModel) {
        self.session = session
        self.sessionViewModel = sessionViewModel
        self._projectName = State(initialValue: session.projectName)
        self._taskDescription = State(initialValue: session.taskDescription)
        self._startTime = State(initialValue: session.startTime)
        self._endTime = State(initialValue: session.endTime)
        self._hasEndTime = State(initialValue: session.endTime != nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            editHeaderView
            
            // 编辑表单
            editFormView
        }
        .background(Color.appBackground)
    }
    
    private var editHeaderView: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .foregroundColor(.secondaryGray)
            
            Spacer()
            
            Text("编辑Session")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button("保存") {
                saveChanges()
            }
            .foregroundColor(.primaryGreen)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
    
    private var editFormView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // 项目名称
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("项目名称")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    TextField("输入项目名称", text: $projectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 任务描述
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("任务描述")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    TextField("输入任务描述", text: $taskDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 开始时间
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("开始时间")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                // 结束时间
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("结束时间")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Toggle("", isOn: $hasEndTime)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    if hasEndTime {
                        DatePicker("", selection: Binding(
                            get: { endTime ?? Date() },
                            set: { endTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
    
    private func saveChanges() {
        var updatedSession = session
        updatedSession.projectName = projectName
        updatedSession.taskDescription = taskDescription
        updatedSession.startTime = startTime
        updatedSession.endTime = hasEndTime ? endTime : nil
        
        sessionViewModel.updateSession(updatedSession)
        dismiss()
    }
}

#Preview {
    SettingsView(sessionViewModel: SessionViewModel())
}

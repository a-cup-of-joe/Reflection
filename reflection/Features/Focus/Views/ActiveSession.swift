struct ActiveSessionCard: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    let session: FocusSession
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 状态指示
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: true)
                
                Text("专注中")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
            }
            
            // 项目和任务信息
            VStack(spacing: Spacing.md) {
                Text(session.projectName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(session.taskDescription)
                    .font(.body)
                    .foregroundColor(.secondaryGray)
                    .multilineTextAlignment(.center)
            }
            
            // 计时器
            TimerView(elapsedTime: sessionViewModel.elapsedTime)
            
            // 结束按钮
            Button(action: {
                sessionViewModel.endCurrentSession()
            }) {
                Text("结束会话")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(Spacing.xl)
        .cardStyle()
    }
}
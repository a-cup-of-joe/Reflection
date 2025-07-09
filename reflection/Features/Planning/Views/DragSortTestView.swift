import SwiftUI

// 测试拖动排序功能的简单视图
struct DragSortTestView: View {
    @StateObject private var planViewModel = PlanViewModel()
    
    var body: some View {
        VStack {
            Text("拖动排序测试")
                .font(.title)
                .padding()
            
            Button("添加测试数据") {
                addTestData()
            }
            .padding()
            
            PlanView()
                .environmentObject(planViewModel)
        }
        .frame(width: 800, height: 600)
    }
    
    private func addTestData() {
        planViewModel.addPlan(project: "工作任务", plannedTime: 3600, themeColor: "#FF4757")
        planViewModel.addPlan(project: "学习时间", plannedTime: 2700, themeColor: "#32CD32")
        planViewModel.addPlan(project: "休息时间", plannedTime: 1800, themeColor: "#4169E1")
        planViewModel.addPlan(project: "运动", plannedTime: 2400, themeColor: "#FFD700")
        planViewModel.addPlan(project: "阅读", plannedTime: 1500, themeColor: "#8A2BE2")
    }
}

#Preview {
    DragSortTestView()
}

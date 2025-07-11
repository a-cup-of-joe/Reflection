import Foundation

class AppDataManager: ObservableObject {
    static let shared = AppDataManager()
    
    @Published var activities: [Activity] = []
    @Published var plans: [Plan] = []
    @Published var daySessions: [DaySession] = []
    @Published var currentPlan: Plan? {
        didSet {
            savePlans()
        }
    }
    
    // UserDefaults keys
    private let activitiesKey = "saved_activities"
    private let plansKey = "saved_plans"
    private let daySessionsKey = "saved_day_sessions"
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    private func loadAllData() {
        activities = loadActivities()
        plans = loadPlans()
        daySessions = loadDaySessions()
        
        // 初始化 currentPlan
        initializeCurrentPlan()
    }
    
    private func initializeCurrentPlan() {
        // 检查 currentPlan 是否存在且在 plans 数组中
        if let current = currentPlan,
           plans.contains(where: { $0.id == current.id }) {
            // currentPlan 有效，无需处理
            return
        }
        
        // currentPlan 为空或不在 plans 中，需要重新设置
        if let latestPlan = plans.max(by: { $0.createdAt < $1.createdAt }) {
            // 选择最新的计划
            currentPlan = latestPlan
        } else {
            // 如果没有计划，创建一个空白计划
            let defaultPlan = Plan(
                id: UUID(),
                name: "默认计划",
                timeBars: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            plans.append(defaultPlan)
            currentPlan = defaultPlan
            savePlans()
        }
    }
    
    private func loadActivities() -> [Activity] {
        guard let data = UserDefaults.standard.data(forKey: activitiesKey),
              let decoded = try? JSONDecoder().decode([Activity].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func loadPlans() -> [Plan] {
        guard let data = UserDefaults.standard.data(forKey: plansKey),
              let decoded = try? JSONDecoder().decode([Plan].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func loadDaySessions() -> [DaySession] {
        guard let data = UserDefaults.standard.data(forKey: daySessionsKey),
              let decoded = try? JSONDecoder().decode([DaySession].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Data Saving
    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: activitiesKey)
        }
    }
    
    private func savePlans() {
        if let encoded = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(encoded, forKey: plansKey)
        }
    }
    
    private func saveDaySessions() {
        if let encoded = try? JSONEncoder().encode(daySessions) {
            UserDefaults.standard.set(encoded, forKey: daySessionsKey)
        }
    }
    
    // MARK: - Activity Management
    func addActivity(_ activity: Activity) {
        // 确保名称唯一
        guard !activities.contains(where: { $0.name == activity.name }) else {
            return
        }
        activities.append(activity)
        saveActivities()
    }
    
    func updateActivity(_ activity: Activity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
            saveActivities()
        }
    }
    
    func deleteActivity(_ activity: Activity) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
    }
    
    func getActivity(by id: UUID) -> Activity? {
        return activities.first { $0.id == id }
    }

    func getActivity(by name: String) -> Activity? {
        return activities.first { $0.name == name }
    }

    func getAllActivities() -> [Activity] {
        return activities
    }

    func addTimeBar(to plan: Plan = dataManager.currentPlan, timeBar: TimeBar) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            var updatedPlan = plans[index]
            updatedPlan.timeBars.append(timeBar)
            plans[index] = updatedPlan
            savePlans()
        }
    }

    func deleteTimeBar(from plan: Plan = dataManager.currentPlan, timeBarId: UUID) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            var updatedPlan = plans[index]
            updatedPlan.timeBars.removeAll { $0.id == timeBarId }
            plans[index] = updatedPlan
            savePlans()
        }
    }

    func deleteTimeBar(from plan: Plan = dataManager.currentPlan, at indexSet: IndexSet) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            var updatedPlan = plans[index]
            updatedPlan.timeBars.remove(atOffsets: indexSet)
            plans[index] = updatedPlan
            savePlans()
        }
    }

    func updatedTimeBar(from plan: Plan = dataManager.currentPlan, timeBar: TimeBar) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            var updatedPlan = plans[index]
            if let timeBarIndex = updatedPlan.timeBars.firstIndex(where: { $0.id == timeBar.id }) {
                updatedPlan.timeBars[timeBarIndex] = timeBar
            } else {
                // 如果没有找到对应的时间段，添加新的时间段
                updatedPlan.timeBars.append(timeBar)
            }
            plans[index] = updatedPlan
            savePlans()
        }
    }

    func moveTimeBar(from source: IndexSet, to destination: Int, in plan: Plan = dataManager.currentPlan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            var updatedPlan = plans[index]
            updatedPlan.timeBars.move(fromOffsets: source, toOffset: destination)
            plans[index] = updatedPlan
            savePlans()
        }
    }

    func moveTimeBar(fromIndex: Int, toIndex: Int, in plan: Plan = dataManager.currentPlan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            var updatedPlan = plans[index]
            guard fromIndex >= 0 && fromIndex < updatedPlan.timeBars.count &&
                  toIndex >= 0 && toIndex < updatedPlan.timeBars.count &&
                  fromIndex != toIndex else { return }
            let timeBar = updatedPlan.timeBars.remove(at: fromIndex)
            updatedPlan.timeBars.insert(timeBar, at: toIndex)
            plans[index] = updatedPlan
            savePlans()
        }
    }
    
    // MARK: - Plan Management
    func addPlan(_ plan: Plan) {
        plans.append(plan)
        savePlans()
    }
    
    func updatePlan(_ plan: Plan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
            savePlans()
        }
    }
    
    func deletePlan(_ plan: Plan) {
        plans.removeAll { $0.id == plan.id }
        
        // 如果删除的是当前计划，需要重新设置 currentPlan
        if currentPlan?.id == plan.id {
            currentPlan = nil
            initializeCurrentPlan()
        } else {
            savePlans()
        }
    }
    
    // MARK: - Session Management
    func addDaySession(_ daySession: DaySession) {
        daySessions.append(daySession)
        saveDaySessions()
    }
    
    func updateDaySession(_ daySession: DaySession) {
        if let index = daySessions.firstIndex(where: { $0.id == daySession.id }) {
            daySessions[index] = daySession
            saveDaySessions()
        }
    }
    
    func addSessionToToday(activityId: UUID, startTime: Date, duration: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 查找今天的 DaySession
        if let todayIndex = daySessions.firstIndex(where: { 
            Calendar.current.isDate($0.createdAt, inSameDayAs: today) 
        }) {
            // 添加到现有的 DaySession
            let newSession = Session(id: UUID(), activityId: activityId, startTime: startTime, duration: duration)
            var updatedDaySession = daySessions[todayIndex]
            updatedDaySession = DaySession(
                id: updatedDaySession.id,
                sessions: updatedDaySession.sessions + [newSession],
                createdAt: updatedDaySession.createdAt
            )
            daySessions[todayIndex] = updatedDaySession
        } else {
            // 创建新的 DaySession
            let newSession = Session(id: UUID(), activityId: activityId, startTime: startTime, duration: duration)
            let newDaySession = DaySession(
                id: UUID(),
                sessions: [newSession],
                createdAt: today
            )
            daySessions.append(newDaySession)
        }
        
        saveDaySessions()
    }
    
    // MARK: - Statistics & Computed Properties
    func getTotalTimeForActivity(_ activityId: UUID) -> TimeInterval {
        return daySessions.flatMap { $0.sessions }
            .filter { $0.activityId == activityId }
            .reduce(0) { $0 + $1.duration }
    }
    
    func getSessionsForActivity(_ activityId: UUID) -> [Session] {
        return daySessions.flatMap { $0.sessions }
            .filter { $0.activityId == activityId }
    }
    
    func getTodaysSessions() -> [Session] {
        let today = Calendar.current.startOfDay(for: Date())
        return daySessions.first { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }?.sessions ?? []
    }
    
    // MARK: - Plan Statistics
    func getCompletionStatsForPlan(_ plan: Plan) -> [(activityId: UUID, planned: TimeInterval, actual: TimeInterval)] {
        return plan.timeBars.map { timeBar in
            let actualTime = getTotalTimeForActivity(timeBar.activityId)
            return (activityId: timeBar.activityId, planned: timeBar.plannedTime, actual: actualTime)
        }
    }
    
    // MARK: - Utility Methods
    func clearAllData() {
        activities.removeAll()
        plans.removeAll()
        daySessions.removeAll()
        currentPlan = nil
        
        UserDefaults.standard.removeObject(forKey: activitiesKey)
        UserDefaults.standard.removeObject(forKey: plansKey)
        UserDefaults.standard.removeObject(forKey: daySessionsKey)
        
        // 重新创建默认计划
        initializeCurrentPlan()
    }
    
    // MARK: - Plan Selection
    func setCurrentPlan(_ plan: Plan) {
        guard plans.contains(where: { $0.id == plan.id }) else {
            // 如果要设置的计划不在列表中，先添加它
            plans.append(plan)
            savePlans()
            currentPlan = plan
            return
        }
        currentPlan = plan
    }
}
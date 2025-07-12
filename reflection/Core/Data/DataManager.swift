import Foundation

class DataManager: ObservableObject {
    static let shared = DataManager()
    @Published var activities: [UUID: Activity] = [:] {
        didSet {
            saveActivities()
        }
    }
    @Published var plans: [UUID: Plan] = [:] {
        didSet {
            savePlans()
        }
    }
    @Published var daySessions: [UUID: DaySession] = [:] {
        didSet {
            saveDaySessions()
        }
    }
    @Published var currentPlan: Plan? {
        didSet {
            saveCurrentPlan()
        }
    }
    
    // UserDefaults keys
    private let activitiesKey = "saved_activities"
    private let plansKey = "saved_plans"
    private let daySessionsKey = "saved_day_sessions"
    private let currentPlanKey = "saved_current_plan"
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    private func loadAllData() {
        activities = loadActivities()
        plans = loadPlans()
        daySessions = loadDaySessions()
        currentPlan = loadCurrentPlan()

        initializeCurrentPlan()
    }
    
    private func initializeCurrentPlan() {
        // 检查 currentPlan 是否存在且在 plans 数组中
        if let current = currentPlan,
           plans[current.id] != nil {
            // currentPlan 有效，无需处理
            return
        }
        
        // currentPlan 为空或不在 plans 中，需要重新设置
        if let latestPlan = plans.values.max(by: { $0.createdAt < $1.createdAt }) {
            // 选择最新的计划
            currentPlan = latestPlan
        } else {
            // 如果没有计划，创建一个空白计划
            let defaultPlan = Plan(
                id: UUID(),
                name: "default",
                timeBars: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            plans[defaultPlan.id] = defaultPlan
            currentPlan = defaultPlan
    
        }
    }
    
    private func loadActivities() -> [UUID: Activity] {
        guard let data = UserDefaults.standard.data(forKey: activitiesKey),
              let decoded = try? JSONDecoder().decode([Activity].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }
    
    private func loadPlans() -> [UUID: Plan] {
        guard let data = UserDefaults.standard.data(forKey: plansKey),
              let decoded = try? JSONDecoder().decode([Plan].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }
    
    private func loadDaySessions() -> [UUID: DaySession] {
        guard let data = UserDefaults.standard.data(forKey: daySessionsKey),
              let decoded = try? JSONDecoder().decode([DaySession].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }
    
    private func loadCurrentPlan() -> Plan? {
        guard let data = UserDefaults.standard.data(forKey: currentPlanKey),
              let decoded = try? JSONDecoder().decode(Plan.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    // MARK: - Data Saving
    private func saveActivities() {
        let activitiesArray = Array(activities.values)
        if let encoded = try? JSONEncoder().encode(activitiesArray) {
            UserDefaults.standard.set(encoded, forKey: activitiesKey)
        }
    }
    
    private func savePlans() {
        let plansArray = Array(plans.values)
        if let encoded = try? JSONEncoder().encode(plansArray) {
            UserDefaults.standard.set(encoded, forKey: plansKey)
        }
    }
    
    private func saveDaySessions() {
        let daySessionsArray = Array(daySessions.values)
        if let encoded = try? JSONEncoder().encode(daySessionsArray) {
            UserDefaults.standard.set(encoded, forKey: daySessionsKey)
        }
    }
    
    private func saveCurrentPlan() {
        if let currentPlan = currentPlan,
           let encoded = try? JSONEncoder().encode(currentPlan) {
            UserDefaults.standard.set(encoded, forKey: currentPlanKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentPlanKey)
        }
    }
    
    // MARK: - Activity Management
    func addActivity(_ activity: Activity) {
        // 确保名称唯一
        guard !activities.values.contains(where: { $0.name == activity.name }) else {
            return
        }
        activities[activity.id] = activity
    }
    
    func updateActivity(_ activity: Activity) {
        activities[activity.id] = activity
    }
    
    func deleteActivity(_ activity: Activity) {
        activities.removeValue(forKey: activity.id)
    }
    
    func getActivity(by id: UUID) -> Activity? {
        return activities[id]
    }

    func getActivity(by name: String) -> Activity? {
        return activities.values.first { $0.name == name }
    }

    func getAllActivities() -> [Activity] {
        return Array(activities.values)
    }

    func getTimeBar(by id: UUID, in plan: Plan? = currentPlan) -> TimeBar? {
        guard let plan = plan, let existingPlan = plans[plan.id] else { return nil }
        return existingPlan.timeBars.first { $0.id == id }
    }

    func getTimeBars(in plan: Plan? = currentPlan) -> [TimeBar] {
        guard let plan = plan, let existingPlan = plans[plan.id] else { return [] }
        return existingPlan.timeBars
    }

    func addTimeBar(to plan: Plan = currentPlan, timeBar: TimeBar) {
        guard var existingPlan = plans[plan.id] else { return }
        existingPlan.timeBars.append(timeBar)
        plans[plan.id] = existingPlan
        
        // 如果是当前计划，更新当前计划
        if currentPlan?.id == plan.id {
            currentPlan = existingPlan
        }

    }

    func deleteTimeBar(from plan: Plan, timBarID: UUID) {
        guard var existingPlan = plans[plan.id] else { return }
        existingPlan.timeBars.removeAll { $0.id == timBarID }
        plans[plan.id] = existingPlan
        
        // 如果是当前计划，更新当前计划
        if currentPlan?.id == plan.id {
            currentPlan = existingPlan
        }

    }

    func deleteTimeBar(from plan: Plan, at indexSet: IndexSet) {
        guard var existingPlan = plans[plan.id] else { return }
        existingPlan.timeBars.remove(atOffsets: indexSet)
        plans[plan.id] = existingPlan
        
        // 如果是当前计划，更新当前计划
        if currentPlan?.id == plan.id {
            currentPlan = existingPlan
        }

    }

    func updatedTimeBar(from plan: Plan, timeBar: TimeBar) {
        guard var existingPlan = plans[plan.id] else { return }
        if let timeBarIndex = existingPlan.timeBars.firstIndex(where: { $0.id == timeBar.id }) {
            existingPlan.timeBars[timeBarIndex] = timeBar
        } else {
            // 如果没有找到对应的时间段，添加新的时间段
            existingPlan.timeBars.append(timeBar)
        }
        plans[plan.id] = existingPlan
        
        // 如果是当前计划，更新当前计划
        if currentPlan?.id == plan.id {
            currentPlan = existingPlan
        }
    }

    func moveTimeBar(from source: IndexSet, to destination: Int, in plan: Plan = currentPlan) {
        guard var existingPlan = plans[plan.id] else { return }
        existingPlan.timeBars.move(fromOffsets: source, toOffset: destination)
        plans[plan.id] = existingPlan
        
        // 如果是当前计划，更新当前计划
        if currentPlan?.id == plan.id {
            currentPlan = existingPlan
        }

    }

    func moveTimeBar(fromIndex: Int, toIndex: Int, in plan: Plan = currentPlan) {
        guard var existingPlan = plans[plan.id] else { return }
        guard fromIndex >= 0 && fromIndex < existingPlan.timeBars.count &&
              toIndex >= 0 && toIndex < existingPlan.timeBars.count &&
              fromIndex != toIndex else { return }
        
        let timeBar = existingPlan.timeBars.remove(at: fromIndex)
        existingPlan.timeBars.insert(timeBar, at: toIndex)
        plans[plan.id] = existingPlan
        
        // 如果是当前计划，更新当前计划
        if currentPlan?.id == plan.id {
            currentPlan = existingPlan
        }

    }
    
    // MARK: - Plan Management
    func addPlan(_ plan: Plan) {
        plans[plan.id] = plan
    }
    
    func updatePlan(_ plan: Plan) {
        plans[plan.id] = plan
    }
    
    func deletePlan(_ plan: Plan) {
        plans.removeValue(forKey: plan.id)
        
        // 如果删除的是当前计划，需要重新设置 currentPlan
        if currentPlan?.id == plan.id {
            currentPlan = nil
            initializeCurrentPlan()
        }
    }
    
    // MARK: - Session Management
    func addDaySession(_ daySession: DaySession) {
        daySessions[daySession.id] = daySession
    }
    
    func updateDaySession(_ daySession: DaySession) {
        daySessions[daySession.id] = daySession
    }

    func getTodayDaySession() -> DaySession? {
        let today = Calendar.current.startOfDay(for: Date())
        if let existingSession = daySessions.values.first(where: { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }) {
            return existingSession
        } else {
            let newDaySession = DaySession(
                id: UUID(),
                sessions: [],
                createdAt: today
            )
            daySessions[newDaySession.id] = newDaySession
            return newDaySession
        }
    }
    
    func addSessionToToday(activityId: UUID, startTime: Date, duration: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        
        todayDaySession = getTodayDaySession()
        let newSession = Session(id: UUID(), activityId: activityId, startTime: startTime, duration: duration)
        daySessions[todayDaySession.id].sessions.append(newSession)
    }

    func updateSession(session: Session, from daySession: DaySession? = getTodayDaySession()) {
        guard let daySession = daySession ?? getTodayDaySession() else { return }
        
        if let index = daySession.sessions.firstIndex(where: { $0.id == session.id }) {
            daySessions[daySession.id].sessions[index] = session
        } else {
            // 如果没有找到对应的会话，添加新的会话
            daySessions[daySession.id].sessions.append(session)
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
        UserDefaults.standard.removeObject(forKey: currentPlanKey)
        
        initializeCurrentPlan()
    }
    
    // MARK: - Plan Selection
    func setCurrentPlan(_ plan: Plan) {
        guard plans[plan.id] != nil else {
            plans[plan.id] = plan
            currentPlan = plan
            return
        }
        currentPlan = plan
    }
}
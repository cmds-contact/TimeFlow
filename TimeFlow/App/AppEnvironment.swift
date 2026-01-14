import SwiftUI
import SwiftData

/// Main dependency injection container for the app
@MainActor
final class AppEnvironment: ObservableObject {

    // MARK: - Properties

    let modelContainer: ModelContainer
    let userSettings: UserSettings
    let timeCalculator: TimeCalculator

    /// Selection state for block selection across the calendar
    @Published var selectionState = SelectionState()

    /// Undo manager for undo/redo support
    let undoManager = UndoManager()

    // Repositories
    private(set) lazy var planBlockRepository: PlanBlockRepository = {
        PlanBlockRepository(modelContext: modelContainer.mainContext)
    }()

    private(set) lazy var actualBlockRepository: ActualBlockRepository = {
        ActualBlockRepository(modelContext: modelContainer.mainContext)
    }()

    private(set) lazy var taskRepository: TaskRepository = {
        TaskRepository(modelContext: modelContainer.mainContext)
    }()

    private(set) lazy var pomodoroRepository: PomodoroRepository = {
        PomodoroRepository(modelContext: modelContainer.mainContext)
    }()

    // Services
    private(set) lazy var timerService: TimerService = {
        TimerService(
            actualBlockRepository: actualBlockRepository,
            timeCalculator: timeCalculator
        )
    }()

    // UseCases
    private(set) lazy var useCases: UseCases = {
        UseCases(
            planBlockRepository: planBlockRepository,
            actualBlockRepository: actualBlockRepository,
            taskRepository: taskRepository,
            pomodoroRepository: pomodoroRepository,
            timerService: timerService,
            timeCalculator: timeCalculator,
            userSettings: userSettings
        )
    }()

    // MARK: - Initialization

    init() {
        // Configure SwiftData model container
        let schema = Schema([
            PlanBlockModel.self,
            ActualBlockModel.self,
            TaskItemModel.self,
            PomodoroSessionModel.self,
            CategoryModel.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        self.userSettings = UserSettings()
        self.timeCalculator = TimeCalculator()
    }

    // MARK: - Methods

    /// Restore any persisted state (timers, sessions) on app launch
    func restoreState() async {
        await timerService.restore()
    }
}

// MARK: - UseCases Container
@MainActor
struct UseCases {
    // Calendar
    let createPlanBlock: CreatePlanBlockUseCase
    let updatePlanBlock: UpdatePlanBlockUseCase
    let deletePlanBlock: DeletePlanBlockUseCase
    let fetchPlanBlocks: FetchPlanBlocksUseCase

    // Tracking
    let startTracking: StartTrackingUseCase
    let stopTracking: StopTrackingUseCase
    let createActualBlock: CreateActualBlockUseCase
    let updateActualBlock: UpdateActualBlockUseCase
    let deleteActualBlock: DeleteActualBlockUseCase
    let linkActualToPlan: LinkActualToPlanUseCase

    // Tasks
    let createTask: CreateTaskUseCase
    let updateTask: UpdateTaskUseCase
    let deleteTask: DeleteTaskUseCase
    let completeTask: CompleteTaskUseCase
    let calculateDailyLoad: CalculateDailyLoadUseCase

    // Focus
    let startPomodoro: StartPomodoroUseCase
    let pausePomodoro: PausePomodoroUseCase
    let resumePomodoro: ResumePomodoroUseCase
    let stopPomodoro: StopPomodoroUseCase
    let completeCycle: CompleteCycleUseCase

    init(
        planBlockRepository: PlanBlockRepository,
        actualBlockRepository: ActualBlockRepository,
        taskRepository: TaskRepository,
        pomodoroRepository: PomodoroRepository,
        timerService: TimerService,
        timeCalculator: TimeCalculator,
        userSettings: UserSettings
    ) {
        // Calendar UseCases
        self.createPlanBlock = CreatePlanBlockUseCase(
            repository: planBlockRepository,
            timeCalculator: timeCalculator
        )
        self.updatePlanBlock = UpdatePlanBlockUseCase(
            repository: planBlockRepository,
            timeCalculator: timeCalculator
        )
        self.deletePlanBlock = DeletePlanBlockUseCase(repository: planBlockRepository)
        self.fetchPlanBlocks = FetchPlanBlocksUseCase(repository: planBlockRepository)

        // Tracking UseCases
        self.startTracking = StartTrackingUseCase(timerService: timerService)
        self.stopTracking = StopTrackingUseCase(
            timerService: timerService,
            repository: actualBlockRepository
        )
        self.createActualBlock = CreateActualBlockUseCase(
            repository: actualBlockRepository,
            timeCalculator: timeCalculator
        )
        self.updateActualBlock = UpdateActualBlockUseCase(
            repository: actualBlockRepository
        )
        self.deleteActualBlock = DeleteActualBlockUseCase(
            repository: actualBlockRepository
        )
        self.linkActualToPlan = LinkActualToPlanUseCase(
            actualRepository: actualBlockRepository,
            planRepository: planBlockRepository,
            timeCalculator: timeCalculator
        )

        // Task UseCases
        self.createTask = CreateTaskUseCase(repository: taskRepository)
        self.updateTask = UpdateTaskUseCase(repository: taskRepository)
        self.deleteTask = DeleteTaskUseCase(repository: taskRepository)
        self.completeTask = CompleteTaskUseCase(repository: taskRepository)
        self.calculateDailyLoad = CalculateDailyLoadUseCase(
            repository: taskRepository,
            settings: userSettings
        )

        // Focus UseCases
        self.startPomodoro = StartPomodoroUseCase(
            repository: pomodoroRepository,
            timerService: timerService,
            settings: userSettings
        )
        self.pausePomodoro = PausePomodoroUseCase(timerService: timerService)
        self.resumePomodoro = ResumePomodoroUseCase(timerService: timerService)
        self.stopPomodoro = StopPomodoroUseCase(
            repository: pomodoroRepository,
            timerService: timerService
        )
        self.completeCycle = CompleteCycleUseCase(
            repository: pomodoroRepository,
            actualBlockRepository: actualBlockRepository,
            timerService: timerService,
            settings: userSettings
        )
    }
}

// MARK: - Environment Keys

private struct UseCasesKey: EnvironmentKey {
    static let defaultValue: UseCases? = nil
}

private struct TimeCalculatorKey: EnvironmentKey {
    static let defaultValue: TimeCalculator = TimeCalculator()
}

private struct UserSettingsKey: EnvironmentKey {
    static let defaultValue: UserSettings? = nil
}

extension EnvironmentValues {
    var useCases: UseCases? {
        get { self[UseCasesKey.self] }
        set { self[UseCasesKey.self] = newValue }
    }

    var timeCalculator: TimeCalculator {
        get { self[TimeCalculatorKey.self] }
        set { self[TimeCalculatorKey.self] = newValue }
    }

    var userSettings: UserSettings? {
        get { self[UserSettingsKey.self] }
        set { self[UserSettingsKey.self] = newValue }
    }
}

import SwiftUI
import SwiftData

@main
struct EventTourPlannerApp: App {
    private let modelContainer: ModelContainer
    private let eventListViewModel: EventListViewModel
    private let tourListViewModel: TourListViewModel

    init() {
        do {
            let container = try ModelContainer(
                for: LiveEvent.self,
                EventExpense.self,
                TourPlan.self,
                TourScheduleItem.self
            )
            modelContainer = container
            eventListViewModel = EventListViewModel(
                repository: SwiftDataEventRepository(
                    modelContext: container.mainContext
                )
            )
            tourListViewModel = TourListViewModel(
                repository: SwiftDataTourRepository(
                    modelContext: container.mainContext
                )
            )
        } catch {
            fatalError("SwiftDataの初期化に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                eventViewModel: eventListViewModel,
                tourViewModel: tourListViewModel
            )
        }
        .modelContainer(modelContainer)
    }
}

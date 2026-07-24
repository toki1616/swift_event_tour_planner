import SwiftUI
import SwiftData

@main
struct EventTourPlannerApp: App {
    private let modelContainer: ModelContainer
    private let eventListViewModel: EventListViewModel

    init() {
        do {
            let container = try ModelContainer(
                for: LiveEvent.self,
                EventExpense.self
            )
            modelContainer = container
            eventListViewModel = EventListViewModel(
                repository: SwiftDataEventRepository(
                    modelContext: container.mainContext
                )
            )
        } catch {
            fatalError("SwiftDataの初期化に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: eventListViewModel)
        }
        .modelContainer(modelContainer)
    }
}

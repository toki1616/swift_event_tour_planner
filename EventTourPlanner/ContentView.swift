import SwiftUI

struct ContentView: View {
    let eventViewModel: EventListViewModel
    let tourViewModel: TourListViewModel

    var body: some View {
        TabView {
            EventListView(viewModel: eventViewModel)
                .tabItem {
                    Label("イベント", systemImage: "music.note.list")
                }

            TourListView(viewModel: tourViewModel)
                .tabItem {
                    Label("ツアー", systemImage: "suitcase.rolling")
                }
        }
    }
}
